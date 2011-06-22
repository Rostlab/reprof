#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     trains the fann neural network
#           with the given datasets
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Getopt::Long;
use AI::FANN qw(:all);
use List::Util qw(sum shuffle);
use NNtrain::Measure;
use File::Basename;

my $hiddens_opt;
my $learning_rate;
my $learning_momentum;
my $max_epochs;
my $wait_epochs;
my $train_file;
my $ctrain_file;
my $test_file;
my $out;
my $config_file;
my $balanced = 0;

GetOptions(	
			'config|c=s'	        => \$config_file
			);


open CONFIG, $config_file or croak "Could not open $config_file\n";
while (my $line = <CONFIG>) {
    my ($type, $option, $value) = split /\s+/, $line;
    
    if ($type eq "option") {
        if ($option eq "hiddens") {
            $hiddens_opt = $value;
        }
        elsif ($option eq "learning_rate") {
            $learning_rate = $value;
        }
        elsif ($option eq "learning_momentum") {
            $learning_momentum = $value;
        }
        elsif ($option eq "max_epochs") {
            $max_epochs = $value;
        }
        elsif ($option eq "wait_epochs") {
            $wait_epochs = $value;
        }
        elsif ($option eq "trainset") {
            $train_file = $value;
        }
        elsif ($option eq "ctrainset") {
            $ctrain_file = $value;
        }
        elsif ($option eq "testset") {
            $test_file = $value;
        }
        elsif ($option eq "out") {
            $out = $value;
        }
        elsif ($option eq "balanced") {
            $balanced = $value;
        }
    }
}
close CONFIG;

#--------------------------------------------------
# Open and parse setfiles
#-------------------------------------------------- 
sub parse_data {
    my ($file) = @_;

    open FH, $file or croak "Could not open $file\n";

    my @data;
    while (my $inputs = <FH>) {
        chomp $inputs;
        my $outputs = <FH>;
        chomp $outputs;
        push @data, [$inputs, $outputs];
    }
    close FH;
    return @data;
}

sub iostring2arrays {
    my $dp = shift;
    
    my @inputs = split /\s+/, $dp->[0];
    my @outputs = split /\s+/, $dp->[1];

    return (\@inputs, \@outputs);
}

$|++;
say "parse data";
print "train... ";
my @train_data = parse_data($train_file);
print "ctrain... ";
my @ctrain_data = parse_data($ctrain_file);
print "test\n";
my @test_data = parse_data($test_file);

my @first_dp = iostring2arrays($train_data[0]);

#--------------------------------------------------
# Helper variables
#-------------------------------------------------- 
my @hiddens = split /,/, $hiddens_opt;
my $num_inputs = scalar @{$first_dp[0]};
my $num_outputs = scalar @{$first_dp[1]};
my $num_hiddens = 0;
foreach my $layer (@hiddens) {
    $num_hiddens += $layer;
}

my $max_Qn = -1;
my $best_epoch = 0;
my $boring_epochs = 0;

#-------------------------------------------------- 
# Prepare output
#-------------------------------------------------- 
my $result_file = "$out/nntrain.result";
if (-e $result_file) {
    open FH, $result_file or die "Could not open $result_file\n";
    my $line = <FH>;
    close FH;
    if ($line =~ m/^FINISHED/) {
        croak "Training already finished, delete results to rerun";
    }
    elsif ($line =~ m/^TRAINING/) {
        say "Resuming training";
    }
}

my $training_file = "$out/nntrain.train";
open TRAINING, ">>", $training_file  or die "Could not open $training_file\n";
select TRAINING;
$|++;
select STDOUT;


#--------------------------------------------------
# Create nn
#-------------------------------------------------- 
my $ann;
my $nn_file = "$out/nntrain.model";
if (-e $nn_file) {
    $ann = AI::FANN->new_from_file($nn_file);
    say "network loaded from file";
}
else {
    my @layers;
    push @layers, $num_inputs;
    push @layers, @hiddens unless scalar @hiddens == 0;
    push @layers, $num_outputs;

    $ann = AI::FANN->new_standard(@layers);
    $ann->hidden_activation_function(FANN_SIGMOID);
    $ann->output_activation_function(FANN_SIGMOID);
    $ann->training_algorithm(FANN_TRAIN_INCREMENTAL);
    $ann->train_error_function(FANN_ERRORFUNC_LINEAR);
    $ann->train_stop_function(FANN_STOPFUNC_MSE);
    $ann->learning_rate($learning_rate);
    $ann->learning_momentum($learning_momentum);

    say "created network ", join " ", @layers;
}

#--------------------------------------------------
# prepare balancing
#-------------------------------------------------- 
my $min_train_class_size;
my %grouped_train_data;
if ($balanced) {
    say "prepare balancing";
    foreach my $dp (@train_data) {
        push @{$grouped_train_data{$dp->[1]}}, $dp;
    }
    while (my ($class, $data) = each %grouped_train_data) {
        my $size = scalar @$data;
        say "$class -> $size";
        if (!defined $min_train_class_size) {
            $min_train_class_size = $size;
        }
        elsif ($size < $min_train_class_size) {
            $min_train_class_size = $size;
        }
    }
    say "min train class size: $min_train_class_size";
}

my $min_ctrain_class_size;
my %grouped_ctrain_data;
if ($balanced) {
    say "prepare balancing";
    foreach my $dp (@ctrain_data) {
        push @{$grouped_ctrain_data{$dp->[1]}}, $dp;
    }
    while (my ($class, $data) = each %grouped_ctrain_data) {
        my $size = scalar @$data;
        say "$class -> $size";
        if (!defined $min_ctrain_class_size) {
            $min_ctrain_class_size = $size;
        }
        elsif ($size < $min_ctrain_class_size) {
            $min_ctrain_class_size = $size;
        }
    }
    say "min ctrain class size: $min_ctrain_class_size";
}

#--------------------------------------------------
# Loop through epochs 
#-------------------------------------------------- 
my $start_time = time;
foreach my $epoch (1 .. $max_epochs) {
    #--------------------------------------------------
    # shuffling / balancing
    #-------------------------------------------------- 
    print "shuffling/balancing... ";
    # train set;
    my @balanced_train_data;
    my @shuffled_train_data;

    if ($balanced) {
        while (my ($class, $data) = each %grouped_train_data) {
            my @shuffled_data = shuffle @$data;
            my @cut_data = @shuffled_data[0 .. $min_train_class_size - 1];
            push @balanced_train_data, @cut_data;
        }

        @shuffled_train_data = shuffle @balanced_train_data;
    }
    else {
        @shuffled_train_data = shuffle @train_data; 
    }

    # ctrain set
    my @balanced_ctrain_data;
    my @shuffled_ctrain_data;

    if ($balanced) {
        while (my ($class, $data) = each %grouped_ctrain_data) {
            my @shuffled_data = shuffle @$data;
            my @cut_data = @shuffled_data[0 .. $min_ctrain_class_size - 1];
            push @balanced_ctrain_data, @cut_data;
        }

        @shuffled_ctrain_data = shuffle @balanced_ctrain_data;
    }
    else {
        @shuffled_ctrain_data = shuffle @ctrain_data; 
    }
    #--------------------------------------------------
    # Training 
    #-------------------------------------------------- 
    print "train... ";
    $ann->reset_MSE;
    foreach my $dp (@shuffled_train_data) {
        my @dp_data = iostring2arrays($dp);
        $ann->train(@dp_data);
    }
    my $train_mse = $ann->MSE;

    #--------------------------------------------------
    # crosstraining
    #-------------------------------------------------- 

    print "crosstrain... ";
    $ann->reset_MSE;
    my $ctrain_measure = NNtrain::Measure->new($num_outputs);
    foreach my $dp (@shuffled_ctrain_data) {
        my @dp_data = iostring2arrays($dp);
        my $pred = $ann->test(@dp_data);
        $ctrain_measure->add($dp_data[1], $pred);
    }
    my $ctrain_mse = $ann->MSE;
    say "!";

    say TRAINING "epoch $epoch";
    say TRAINING join " ", "time", (time - $start_time);
    say TRAINING join " ", "train_mse", ($train_mse);
    say TRAINING join " ", "ctrain_mse", ($ctrain_mse);
    say TRAINING join " ", "ctrain_qn", (map {sprintf "%.3f", $_*100} ($ctrain_measure->Qn));
    say TRAINING join " ", "ctrain_precisions", (map {sprintf "%.3f", $_*100} ($ctrain_measure->precisions));
    say TRAINING join " ", "ctrain_recalls", (map {sprintf "%.3f", $_*100} ($ctrain_measure->recalls));
    say TRAINING join " ", "ctrain_fmeasures", (map {sprintf "%.3f", $_*100} ($ctrain_measure->fmeasures));

    #--------------------------------------------------
    # Save nn if ctrainset reaches new maximum value
    #-------------------------------------------------- 
    if ($ctrain_measure->Qn > $max_Qn) {
        $ann->save($nn_file);
        $max_Qn = $ctrain_measure->Qn;
        $best_epoch = $epoch;
        $boring_epochs = 0;
        open RESULT, ">", $result_file  or die "Could not open $result_file\n";
        say RESULT "TRAINING";
        say RESULT "epoch $epoch";
        say RESULT join " ", "time", (time - $start_time);
        say RESULT join " ", "train_mse", ($train_mse);
        say RESULT join " ", "ctrain_mse", ($ctrain_mse);
        say RESULT join " ", "ctrain_qn", (map {sprintf "%.3f", $_*100} ($ctrain_measure->Qn));
        say RESULT join " ", "ctrain_precisions", (map {sprintf "%.3f", $_*100} ($ctrain_measure->precisions));
        say RESULT join " ", "ctrain_recalls", (map {sprintf "%.3f", $_*100} ($ctrain_measure->recalls));
        say RESULT join " ", "ctrain_fmeasures", (map {sprintf "%.3f", $_*100} ($ctrain_measure->fmeasures));
        close RESULT;
    }
    else {
        $boring_epochs++;
    }

    if ($boring_epochs >= $wait_epochs) {
        say "finished, Qn not increasing anymore";

        $ann = AI::FANN->new_from_file($nn_file);

        $ann->reset_MSE;
        my $train_measure = NNtrain::Measure->new($num_outputs);
        my ($train_base) = fileparse($train_file);
        open OUT, ">", "$out/$train_base.output" or croak "Could not open file\n";
        foreach my $dp (@train_data) {
            my @dp_data = iostring2arrays($dp);
            my $pred = $ann->test(@dp_data);
            say OUT join " ", @$pred;
            $train_measure->add($dp_data[1], $pred);
        }
        close OUT;
        $train_mse = $ann->MSE;

        $ann->reset_MSE;
        $ctrain_measure = NNtrain::Measure->new($num_outputs);
        my ($ctrain_base) = fileparse($ctrain_file);
        open OUT, ">", "$out/$ctrain_base.output" or croak "Could not open file\n";
        foreach my $dp (@ctrain_data) {
            my @dp_data = iostring2arrays($dp);
            my $pred = $ann->test(@dp_data);
            say OUT join " ", @$pred;
            $ctrain_measure->add($dp_data[1], $pred);
        }
        close OUT;
        $ctrain_mse = $ann->MSE;

        $ann->reset_MSE;
        my $test_measure = NNtrain::Measure->new($num_outputs);
        my ($test_base) = fileparse($test_file);
        open OUT, ">", "$out/$test_base.output" or croak "Could not open file\n";
        foreach my $dp (@test_data) {
            my @dp_data = iostring2arrays($dp);
            my $pred = $ann->test(@dp_data);
            say OUT join " ", @$pred;
            $test_measure->add($dp_data[1], $pred);
        }
        close OUT;
        my $test_mse = $ann->MSE;


        open RESULT, ">", $result_file  or die "Could not open $result_file\n";
        say RESULT "FINISHED";
        say RESULT "epoch $epoch";
        say RESULT "best_epoch $best_epoch";
        say RESULT join " ", "time", (time - $start_time);
        say "";

        say RESULT join " ", "train_mse", ($train_mse);
        say RESULT join " ", "train_qn", (map {sprintf "%.3f", $_*100} ($train_measure->Qn));
        say RESULT join " ", "train_precisions", (map {sprintf "%.3f", $_*100} ($train_measure->precisions));
        say RESULT join " ", "train_recalls", (map {sprintf "%.3f", $_*100} ($train_measure->recalls));
        say RESULT join " ", "train_fmeasures", (map {sprintf "%.3f", $_*100} ($train_measure->fmeasures));
        say "";

        say RESULT join " ", "ctrain_mse", ($ctrain_mse);
        say RESULT join " ", "ctrain_qn", (map {sprintf "%.3f", $_*100} ($ctrain_measure->Qn));
        say RESULT join " ", "ctrain_precisions", (map {sprintf "%.3f", $_*100} ($ctrain_measure->precisions));
        say RESULT join " ", "ctrain_recalls", (map {sprintf "%.3f", $_*100} ($ctrain_measure->recalls));
        say RESULT join " ", "ctrain_fmeasures", (map {sprintf "%.3f", $_*100} ($ctrain_measure->fmeasures));
        say "";

        say RESULT join " ", "test_mse", ($test_mse);
        say RESULT join " ", "test_qn", (map {sprintf "%.3f", $_*100} ($test_measure->Qn));
        say RESULT join " ", "test_precisions", (map {sprintf "%.3f", $_*100} ($test_measure->precisions));
        say RESULT join " ", "test_recalls", (map {sprintf "%.3f", $_*100} ($test_measure->recalls));
        say RESULT join " ", "test_fmeasures", (map {sprintf "%.3f", $_*100} ($test_measure->fmeasures));
        close RESULT;

        last;
    }
}

close TRAINING;

#--------------------------------------------------
#  
#-------------------------------------------------- 
