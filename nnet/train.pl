#!/usr/bin/perl -w
use strict;
use feature qw(say);

use Data::Dumper;
use AI::FANN qw(:all);
use Getopt::Long;
use Prot::Tools::Translator qw(id2pdb aa2number ss2number);
use Prot::Parser::Dssp;
use File::Spec;
use List::Util qw(shuffle);
use Prot::Tools::Fold qw(parse_fold_file data2train);
use Prot::Tools::Measure;

#--------------------------------------------------
# Data
#-------------------------------------------------- 
my $fold_dir = "./data/folds/";

#--------------------------------------------------
# Parameters
#-------------------------------------------------- 
my $num_as = 20+1;
my $min_chain_length = 80;

my $window_size = 11;
my $num_hiddens = 30;

my $fold_offset = 0;
my $num_folds = 10;
my $num_train = 1;
my $num_valid = 1;
my $num_test = 1;
my $max_epochs = 1000;
my $learn_rate = 0.01;
my $learn_moment = 0.1;


#--------------------------------------------------
# Output
#-------------------------------------------------- 
my $verbose = 0;
my $debug = 0;
my $netfile = "./test.nnet";	
my $datadir = "./";

GetOptions(	
			'folds=s'	=> \$fold_dir,
			'net=s'		=> \$netfile,
			'data=s'	=> \$datadir,
			'offset=s'	=> \$fold_offset,
			'window=i'	=> \$window_size,
			'hidden=i'	=> \$num_hiddens,
			'train=i'	=> \$num_train,
			'valid=i'	=> \$num_valid,
			'lrate=s'	=> \$learn_rate,
			'lmoment=s'	=> \$learn_moment,
			'debug'		=> \$debug
			);

#--------------------------------------------------
# Helper variables
#-------------------------------------------------- 
my $num_inputs = $window_size * ($num_as + 1);
my $half_window_size = ($window_size - 1) / 2;
my $num_outputs = 3; # H E L

#--------------------------------------------------
# Load or create ann
#-------------------------------------------------- 
my $ann;
$ann = AI::FANN->new_standard($num_inputs, $num_hiddens, $num_outputs);

say sprintf("Created network with %d inputs, %d hidden neurons, %d outputs", $num_inputs, $num_hiddens, $num_outputs);		

#--------------------------------------------------
# Load from fasta and Gather data from dssp
#-------------------------------------------------- 

$ann->hidden_activation_function(FANN_SIGMOID);
$ann->output_activation_function(FANN_SIGMOID);
$ann->training_algorithm(FANN_TRAIN_INCREMENTAL);
$ann->learning_rate($learn_rate);
#--------------------------------------------------
# $ann->learning_momentum($learn_moment);
#-------------------------------------------------- 

#--------------------------------------------------
# Open and parse foldfiles
#-------------------------------------------------- 
opendir FOLDS, $fold_dir;
my @foldfiles = grep !/^\./, (readdir FOLDS);
close FOLDS;

my @folds;
foreach my $file (@foldfiles) {
	my $foldref = parse_fold_file(File::Spec->catfile($fold_dir, $file));
	push @folds, $foldref;
}

#--------------------------------------------------
# Training
#-------------------------------------------------- 
my $datafile = File::Spec->catfile($datadir, "w$window_size.h$num_hiddens.o$fold_offset.t$num_train.v$num_valid.lr$learn_rate.lm$learn_moment.data");
open DATA, ">", $datafile or die "Could not open $datafile\n";
select DATA;
$|++;
select STDOUT;

my $epoch = -1;
while (++$epoch < $max_epochs) {
	say "Training epoch: $epoch";
	my $current_fold = $fold_offset;

	#--------------------------------------------------
	# Training
	#-------------------------------------------------- 
	$ann->reset_MSE;
	foreach (1 .. $num_train) {
		say "\tFold: $current_fold";
		my $prot_count = 0;

		foreach my $prot_data (@{$folds[$current_fold]}) {
			say "\tProtein: $prot_count" if (++$prot_count % 100 == 0 && $verbose);
			my $data_points = data2train($prot_data, $window_size, $num_as, $num_outputs);
			
			foreach my $dp (@$data_points) {
				$ann->train($dp->[0], $dp->[1]);
			}
		}

		$current_fold = next_fold($current_fold, $num_folds);
	}

	#--------------------------------------------------
	# Testing (trainingset)
	#-------------------------------------------------- 
	say "Train Testing epoch: $epoch";
	
	my $train_measure = Prot::Tools::Measure->new;

	$current_fold = $fold_offset;

	foreach (1 .. $num_train) {
		say "\tFold: $current_fold";
		my $prot_count = 0;

		foreach my $prot_data (@{$folds[$current_fold]}) {
			say "\tProtein: $prot_count" if (++$prot_count % 100 == 0 && $verbose);
			my $data_points = data2train($prot_data, $window_size, $num_as, $num_outputs);
			
			foreach my $dp (@$data_points) {
				my $test_result = $ann->run($dp->[0]);
				$train_measure->add($dp->[1], $test_result);
			}
		}

		$current_fold = next_fold($current_fold, $num_folds);
	}

	my $train_q3 = $train_measure->q3;
	my $train_precision = $train_measure->precision;
	my $train_recall = $train_measure->recall;
	say sprintf("Training: acc: %.2f, prec: %.2f, rec: %.2f", $train_q3, $train_precision, $train_recall);

	#--------------------------------------------------
	# Testing (validationset)
	#-------------------------------------------------- 
	say "Valid Testing epoch: $epoch";
	my $valid_measure = Prot::Tools::Measure->new;

	foreach (1 .. $num_valid) {
		say "\tFold: $current_fold";
		my $prot_count = 0;

		foreach my $prot_data (@{$folds[$current_fold]}) {
			say "\tProtein: $prot_count" if (++$prot_count % 100 == 0 && $verbose);
			my $data_points = data2train($prot_data, $window_size, $num_as, $num_outputs);
			
			foreach my $dp (@$data_points) { # = every window
				my $test_result = $ann->run($dp->[0]);
				$valid_measure->add($dp->[1], $test_result);
			}

		}

		$current_fold = next_fold($current_fold, $num_folds);
	}
	my $valid_q3 = $valid_measure->q3;
	my $valid_precision = $valid_measure->precision;
	my $valid_recall = $valid_measure->recall;
	say sprintf("Validation: acc: %.2f, prec: %.2f, rec: %.2f", $valid_q3, $valid_precision, $valid_recall);

	say DATA sprintf("%s %.3f %.3f %.3f %.3f %.3f %.3f", $epoch, $train_q3, $train_precision, $train_recall, $valid_q3, $valid_precision, $valid_recall);
}

close DATA;


#--------------------------------------------------
# Save the net
#-------------------------------------------------- 
$ann->save($netfile) if $netfile;

#--------------------------------------------------
# Little helpers
#-------------------------------------------------- 
sub next_fold {
	my ($current, $max) = @_;

	return 0 if (++$current == $max);
	return $current;
}

sub empty_array {
	my $size = shift;

	my @array;
	foreach (1..$size) {
		push @array, 0;
	}

	return @array;
}

sub output_to_ss {
	my ($h, $e, $l) = @_;
	
	my $maxpos = -1;
	if ($h >= $e && $h >= $l) {
		$maxpos = 0;
	}
	elsif ($e >= $h && $e >= $l) {
		$maxpos = 1;
	}
	elsif ($l >= $h && $l >= $e) {
		$maxpos = 2;
	}

	return ss2number($maxpos);
}
