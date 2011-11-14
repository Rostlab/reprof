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
use Reprof::Measure;
use File::Basename;

my $hiddens_opt;
my $hiddens_frac;
my $learning_rate;
my $learning_momentum;
my $max_epochs;
my $wait_epochs;
my $train_file;
my $ctrain_file;
my $test_file;
my $out;
my $config_file;
my $balanced_train = 0;
my $balanced_ctrain = 0;
my $max_time = -1;
my $measure_type = "Qn";
my $measure_pos = 0;

GetOptions(	
			'config|c=s'	        => \$config_file
			);

#$|++;

open CONFIG, $config_file or croak "Could not open $config_file\n";
while (my $line = <CONFIG>) {
    my ($type, $option, $value) = split /\s+/, $line;
    
    if ($type eq "option") {
        if ($option eq "hiddens") {
            $hiddens_opt = $value;
        }
        elsif ($option eq "hiddens_frac") {
            $hiddens_frac = $value;
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
        elsif ($option eq "balanced_train") {
            $balanced_train = $value;
        }
        elsif ($option eq "balanced_ctrain") {
            $balanced_ctrain = $value;
        }
        elsif ($option eq "max_time") {
            $max_time = $value;
        }
        elsif ($option eq "measure_type") {
            $measure_type = $value;
        }
        elsif ($option eq "measure_pos") {
            $measure_pos = $value;
        }
        else {
            warn "unknown option: $option $value\n";
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

#print "checking input size... ";
my @train_data = parse_data($train_file);

my @first_dp = iostring2arrays($train_data[0]);

#--------------------------------------------------
# Helper variables
#-------------------------------------------------- 
my $num_inputs = scalar @{$first_dp[0]};
my $num_outputs = scalar @{$first_dp[1]};
my $num_hiddens = 0;
my @hiddens;

if (defined $hiddens_frac) {
    $num_hiddens = int ($hiddens_frac * ($num_inputs + $num_outputs));
    push @hiddens, ($num_hiddens>1?$num_hiddens:1);
}
else {
    @hiddens = split /,/, $hiddens_opt;
    foreach my $layer (@hiddens) {
        $num_hiddens += $layer;
    }
}

undef @train_data;
#say "done...";

my $max_ctrain = -1;
my $best_epoch = 0;
my $boring_epochs = 0;

#-------------------------------------------------- 
# Prepare output
#-------------------------------------------------- 
my $result_file = "$out/nntrain.result";

my $training_file = "$out/nntrain.train";
#open TRAINING, ">", $training_file  or die "Could not open $training_file\n";
#select TRAINING;
#$|++;
#select STDOUT;


#--------------------------------------------------
# Create nn
#-------------------------------------------------- 
my $ann;
my $nn_file = "$out/nntrain.model";
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

#say "created network ", join " ", @layers;

#--------------------------------------------------
# prepare balancing
#-------------------------------------------------- 
sub balance {
    my $ori_data = shift;
    my $min_class_size;
    my %grouped_data;
    
    #say "prepare balancing";

    foreach my $dp (@$ori_data) {
        push @{$grouped_data{$dp->[1]}}, $dp;
    }
    
    while (my ($class, $data) = each %grouped_data) {
        my $size = scalar @$data;
        #say "$class -> $size";
        if (!defined $min_class_size) {
            $min_class_size = $size;
        }
        elsif ($size < $min_class_size) {
            $min_class_size = $size;
        }
    }

    #say "min train class size: $min_class_size";

    my @balanced_data;

    while (my ($class, $data) = each %grouped_data) {
        my @shuffled_data = shuffle @$data;
        my $data_size = scalar @shuffled_data;
        foreach my $i (0 .. $min_class_size - 1) {
            push @balanced_data, $shuffled_data[$i];
        }
        my $size = scalar @balanced_data;
        #say "$class -> $size";
    }

    my @shuffled_data = shuffle @balanced_data;

    return \@shuffled_data;
}

sub load_data {
    my $file = shift;
    my $balanced = shift;

    #--------------------------------------------------
    # parsing, shuffling, balancing train data
    #-------------------------------------------------- 
    my @current_data = parse_data($file);

    my @processed_current_data;
    if ($balanced) {
        @processed_current_data = @{balance(\@current_data)};
    }
    else {
        @processed_current_data = shuffle @current_data;
    }

    return \@processed_current_data;
}

#--------------------------------------------------
# Loop through epochs 
#-------------------------------------------------- 
my $pid = $$;
my $tmp_model_file = "/tmp/$pid.reprof.model";
my $start_time = time;
my $epoch = 0;
while (1 == 1) {
    #say "epoch " . ++$epoch;
    my @processed_current_data;

    #--------------------------------------------------
    # Training 
    #-------------------------------------------------- 
    #print "parsing...";
    @processed_current_data = @{load_data($train_file, $balanced_train)};
    #say "done";

    #print "train... ";
    $ann->reset_MSE;
    foreach my $dp (@processed_current_data) {
        my @dp_data = iostring2arrays($dp);
        $ann->train(@dp_data);
    }
    my $train_mse = $ann->MSE;
    undef @processed_current_data;
    #say "done";

    #--------------------------------------------------
    # crosstraining
    #-------------------------------------------------- 
    #print "parsing...";
    @processed_current_data = @{load_data($ctrain_file, $balanced_ctrain)};
    #say "done";
    
    #print "crosstrain... ";
    $ann->reset_MSE;
    my $ctrain_measure = Reprof::Measure->new($num_outputs);
    foreach my $dp (@processed_current_data) {
        my @dp_data = iostring2arrays($dp);
        my $pred = $ann->test(@dp_data);
        $ctrain_measure->add($dp_data[1], $pred);
    }
    my $ctrain_mse = $ann->MSE;
    undef @processed_current_data;
    #say "done";

    #--------------------------------------------------
    # output 
    #-------------------------------------------------- 
    #print "writing outputs...";
    #say TRAINING "epoch $epoch";
    #say TRAINING join " ", "time", (time - $start_time);
    #say TRAINING "hiddens $num_hiddens";
    #say TRAINING join " ", "train_mse", ($train_mse);
    #say TRAINING join " ", "ctrain_mse", ($ctrain_mse);
    #say TRAINING join " ", "ctrain_qn", (map {sprintf "%.3f", $_*100} ($ctrain_measure->Qn));
    #say TRAINING join " ", "ctrain_precisions", (map {sprintf "%.3f", $_*100} ($ctrain_measure->precisions));
    #say TRAINING join " ", "ctrain_recalls", (map {sprintf "%.3f", $_*100} ($ctrain_measure->recalls));
    #say TRAINING join " ", "ctrain_fmeasures", (map {sprintf "%.3f", $_*100} ($ctrain_measure->fmeasures));
    #say TRAINING join " ", "ctrain_aucs", (map {sprintf "%.3f", $_*100} ($ctrain_measure->aucs));
    #say TRAINING join " ", "ctrain_mccs", (map {sprintf "%.3f", $_*100} ($ctrain_measure->mccs));
    #say "done";

    #--------------------------------------------------
    # Save nn if ctrainset reaches new maximum value
    #-------------------------------------------------- 
    if (($ctrain_measure->$measure_type())[$measure_pos] > $max_ctrain) {
        $ann->save($tmp_model_file);
        $max_ctrain = ($ctrain_measure->$measure_type())[$measure_pos];
        $best_epoch = $epoch;
        $boring_epochs = 0;
        #open RESULT, ">", $result_file  or die "Could not open $result_file\n";
        #say RESULT "TRAINING";
        #say RESULT "epoch $epoch";
        #say RESULT join " ", "time", (time - $start_time);
        #say RESULT "hiddens $num_hiddens";
        #say RESULT join " ", "train_mse", ($train_mse);
        #say RESULT join " ", "ctrain_mse", ($ctrain_mse);
        #say RESULT join " ", "ctrain_qn", (map {sprintf "%.3f", $_*100} ($ctrain_measure->Qn));
        #say RESULT join " ", "ctrain_precisions", (map {sprintf "%.3f", $_*100} ($ctrain_measure->precisions));
        #say RESULT join " ", "ctrain_recalls", (map {sprintf "%.3f", $_*100} ($ctrain_measure->recalls));
        #say RESULT join " ", "ctrain_fmeasures", (map {sprintf "%.3f", $_*100} ($ctrain_measure->fmeasures));
        #say RESULT join " ", "ctrain_aucs", (map {sprintf "%.3f", $_*100} ($ctrain_measure->aucs));
        #say RESULT join " ", "ctrain_mccs", (map {sprintf "%.3f", $_*100} ($ctrain_measure->mccs));
        #close RESULT;
    }
    else { 
        $boring_epochs++;
    }

    #--------------------------------------------------
    # finish training if a max value is reached
    #-------------------------------------------------- 
    my $finished_boring = ($boring_epochs >= $wait_epochs ? 1 : 0);
    my $finished_epochs = ($epoch > $max_epochs ? 1 : 0);
    my $finished_time = (($max_time > 0 && time - $start_time > $max_time) ? 1 : 0);

    if ($finished_boring || $finished_epochs || $finished_time) {
        #say "finishing, because: boring=$finished_boring epochs=$finished_epochs time=$finished_time";

        $ann = AI::FANN->new_from_file($tmp_model_file);
        $ann->save($nn_file);
        unlink $tmp_model_file;

        $ann->reset_MSE;
        my $train_measure = Reprof::Measure->new($num_outputs);
        @processed_current_data = @{load_data($train_file, 0)};
        foreach my $dp (@processed_current_data) {
            my @dp_data = iostring2arrays($dp);
            my $pred = $ann->test(@dp_data);
            $train_measure->add($dp_data[1], $pred);
        }
        $train_mse = $ann->MSE;
        undef @processed_current_data;

        $ann->reset_MSE;
        $ctrain_measure = Reprof::Measure->new($num_outputs);
        @processed_current_data = @{load_data($ctrain_file, 0)};
        foreach my $dp (@processed_current_data) {
            my @dp_data = iostring2arrays($dp);
            my $pred = $ann->test(@dp_data);
            $ctrain_measure->add($dp_data[1], $pred);
        }
        $ctrain_mse = $ann->MSE;
        undef @processed_current_data;

        $ann->reset_MSE;
        my $test_measure = Reprof::Measure->new($num_outputs);
        @processed_current_data = @{load_data($test_file, 0)};
        foreach my $dp (@processed_current_data) {
            my @dp_data = iostring2arrays($dp);
            my $pred = $ann->test(@dp_data);
            $test_measure->add($dp_data[1], $pred);
        }
        my $test_mse = $ann->MSE;
        undef @processed_current_data;


        open RESULT, ">", $result_file  or die "Could not open $result_file\n";
        say RESULT "FINISHED";
        say RESULT "epoch $epoch";
        say RESULT "best_epoch $best_epoch";
        say RESULT join " ", "time until exit", (time - $start_time);
        say RESULT "hiddens $num_hiddens";
        say RESULT "boring=$finished_boring epochs=$finished_epochs time=$finished_time";
        say "";

        say RESULT join " ", "train_mse", ($train_mse);
        say RESULT join " ", "train_qn", (map {sprintf "%.3f", $_*100} ($train_measure->Qn));
        say RESULT join " ", "train_precisions", (map {sprintf "%.3f", $_*100} ($train_measure->precisions));
        say RESULT join " ", "train_recalls", (map {sprintf "%.3f", $_*100} ($train_measure->recalls));
        say RESULT join " ", "train_fmeasures", (map {sprintf "%.3f", $_*100} ($train_measure->fmeasures));
        say RESULT join " ", "train_aucs", (map {sprintf "%.3f", $_*100} ($train_measure->aucs));
        say RESULT join " ", "train_mccs", (map {sprintf "%.3f", $_*100} ($train_measure->mccs));
        say "";

        say RESULT join " ", "ctrain_mse", ($ctrain_mse);
        say RESULT join " ", "ctrain_qn", (map {sprintf "%.3f", $_*100} ($ctrain_measure->Qn));
        say RESULT join " ", "ctrain_precisions", (map {sprintf "%.3f", $_*100} ($ctrain_measure->precisions));
        say RESULT join " ", "ctrain_recalls", (map {sprintf "%.3f", $_*100} ($ctrain_measure->recalls));
        say RESULT join " ", "ctrain_fmeasures", (map {sprintf "%.3f", $_*100} ($ctrain_measure->fmeasures));
        say RESULT join " ", "ctrain_aucs", (map {sprintf "%.3f", $_*100} ($ctrain_measure->aucs));
        say RESULT join " ", "ctrain_mccs", (map {sprintf "%.3f", $_*100} ($ctrain_measure->mccs));
        say "";

        say RESULT join " ", "test_mse", ($test_mse);
        say RESULT join " ", "test_qn", (map {sprintf "%.3f", $_*100} ($test_measure->Qn));
        say RESULT join " ", "test_precisions", (map {sprintf "%.3f", $_*100} ($test_measure->precisions));
        say RESULT join " ", "test_recalls", (map {sprintf "%.3f", $_*100} ($test_measure->recalls));
        say RESULT join " ", "test_fmeasures", (map {sprintf "%.3f", $_*100} ($test_measure->fmeasures));
        say RESULT join " ", "test_aucs", (map {sprintf "%.3f", $_*100} ($test_measure->aucs));
        say RESULT join " ", "test_mccs", (map {sprintf "%.3f", $_*100} ($test_measure->mccs));
        close RESULT;

        last;
    }
}

#close TRAINING;

#--------------------------------------------------
#  
#-------------------------------------------------- 
