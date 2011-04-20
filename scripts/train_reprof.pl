#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     trains the reprof neural network
#           with the given datasets
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

use Data::Dumper;
use AI::FANN qw(:all);
use Getopt::Long;
use File::Spec;
use List::Util qw(shuffle);
use Reprof::Parser::Dssp;
use Reprof::Tools::Translator qw(id2pdb aa2number ss2number);
use Reprof::Tools::Set;
use Reprof::Tools::Measure;

my $train_dir;
my $valid_dir;
my $test_dir;

my $window_size = 19;
my $num_hiddens = 75;

my $max_epochs = 1000;
my $learn_rate = 0.01;
my $learn_moment = 0.1;
my $precise = 1;

my $max_decreasing_epochs = 20;

my $debug = 0;
my $net_file = "./test.net";	
my $result_file = "./test.data";

GetOptions(	
			'train=s'   	=> \$train_dir,
			'valid=s'   	=> \$valid_dir,
			'test=s'    	=> \$test_dir,
			'net=s'	    	=> \$net_file,
			'data=s'    	=> \$result_file,
			'window=i'  	=> \$window_size,
			'hidden=i'  	=> \$num_hiddens,
			'lrate=s'   	=> \$learn_rate,
			'lmoment=s'  	=> \$learn_moment,
			'precise=i' 	=> \$precise,
			'epochs=i'      => \$max_epochs,
			'debug'	        => \$debug
			);

unless ($train_dir && $valid_dir && $test_dir) {
    say "\nDESCRIPTION:";
    say "trains the reprof neural network with the given datasets";

    say "\nOPTIONS:";
    say "-train";
    say "\tdir containing the trainset";
    say "-valid";
    say "\tdir containing the validset";
    say "-test";
    say "\tdir containing the testset";
    say "-net";
    say "\tfile to store the nn";
    say "-data";
    say "\tfile to store the benchmark values";
    say "-window";
    say "\twindow length";
    say "-hidden";
    say "\tnumber of hidden neurons";
    say "-lrate";
    say "\tlearning rate";
    say "-lmoment";
    say "\tlearning momentum";
    say "-precise";
    say "\treset MSE after every protein instead of every fold";
    say "-epochs";
    say "\tmaximum number of epochs";

    die "\nInvalid options";
}

#--------------------------------------------------
# Open and parse setfiles
#-------------------------------------------------- 
print "Parsing trainset(s)... ";
my $train_set = Reprof::Tools::Set->new($train_dir, $window_size);
say "".($train_set->size)." dps";

print "Parsing validset(s)... ";
my $valid_set = Reprof::Tools::Set->new($valid_dir, $window_size);
say "".($valid_set->size)." dps";

print "Parsing testset(s)... ";
my $test_set = Reprof::Tools::Set->new($test_dir, $window_size);
say "".($test_set->size)." dps";

#--------------------------------------------------
# Helper variables
#-------------------------------------------------- 
my $num_features = $train_set->num_features;
my $num_outputs = $train_set->num_outputs;

my $num_inputs = $window_size * $num_features;

my $max_q3 = -1;
my $decreasing_epochs = 0;
 
#--------------------------------------------------
# Create nn
#-------------------------------------------------- 
my $ann = AI::FANN->new_standard($num_inputs, $num_hiddens, $num_outputs);

say sprintf("Created network with %d inputs, %d hidden neurons, %d outputs", $num_inputs, $num_hiddens, $num_outputs);		

# set nn parameters
$ann->hidden_activation_function(FANN_SIGMOID);
$ann->output_activation_function(FANN_SIGMOID);
$ann->training_algorithm(FANN_TRAIN_INCREMENTAL);
$ann->learning_rate($learn_rate);
$ann->learning_momentum($learn_moment);

#-------------------------------------------------- 
# Prepare output
#-------------------------------------------------- 
while (-e $net_file) {
    $net_file .= '.copy';
}
while (-e $result_file) {
    $result_file .= '.copy';
}
open RESULT, ">", $result_file or die "Could not open $result_file\n";
select RESULT;
$|++;
select STDOUT;
$|++;

#--------------------------------------------------
# Loop through epochs 
#-------------------------------------------------- 
foreach my $epoch (1 .. $max_epochs) {
    #--------------------------------------------------
    # Training 
    #-------------------------------------------------- 
    print "Epoch $epoch: training\n";
    train_nn($ann, $train_set);

    #--------------------------------------------------
    # Testing 
    #-------------------------------------------------- 
    # trainset
    print "Epoch $epoch: benchmark trainset... ";
    my $train_measure = test_nn($ann, $train_set);
	my $train_q3 = $train_measure->Q3;
    printf "Q3: %.3f\n", $train_q3;
    
    # validset
    print "Epoch $epoch: benchmark validset... ";
    my $valid_measure = test_nn($ann, $valid_set);
	my $valid_q3 = $valid_measure->Q3;
    printf "Q3: %.3f\n", $valid_q3;

    
    # testset
    print "Epoch $epoch: benchmark testset... ";
    my $test_measure = test_nn($ann, $test_set);
    my $test_q3 = $test_measure->Q3;
    printf "Q3: %.3f\n", $test_q3;

    # print output for benchmark on train valid testsets
    printf RESULT "%s %.5f %.5f %.5f\n", $epoch, $train_q3, $valid_q3, $test_q3;

    #--------------------------------------------------
    # Save nn if validset reaches new maximum value
    #-------------------------------------------------- 
    if ($valid_q3 > $max_q3) {
        $ann->save($net_file);
        $max_q3 = $valid_q3;
        $decreasing_epochs = 0;
    }
    else {
        $decreasing_epochs++;
    }

    if ($decreasing_epochs >= $max_decreasing_epochs) {
        say "Finished after epoch $epoch because no increasing valid Q3 since $decreasing_epochs epochs";
        last;
    }
}

close RESULT;

#--------------------------------------------------
# SUBS
#-------------------------------------------------- 
#--------------------------------------------------
# name:        train_nn
# desc:        trains the network with the data
# args:        fann object, ref to sets
# return:      NA
#-------------------------------------------------- 
sub train_nn {
    my ($nn, $set) = @_;
    
    $nn->reset_MSE;
    while (my $dp = $set->next_dp) {
        $nn->reset_MSE if $precise;
        $nn->train($dp->[0], $dp->[1]);
    }
}

#--------------------------------------------------
# name:        test_nn
# desc:        tests the network with data
# args:        fann object, ref to sets
# return:      Reprof::Tools::Measure
#-------------------------------------------------- 
sub test_nn {
    my ($nn, $set) = @_;
    my $measure = Reprof::Tools::Measure->new($num_outputs);

    while (my $dp = $set->next_dp) {
        my $result = $nn->run($dp->[0]);
        $measure->add($dp->[1], $result);
    }

    return $measure;
}


#--------------------------------------------------
# name:        empty_array
# desc:        creates an empty array filled
#              filled with zeroes
# args:        size of array
# return:      array
#-------------------------------------------------- 
sub empty_array {
	my $size = shift;

	my @array;
	foreach (1..$size) {
		push @array, 0;
	}

	return @array;
}
