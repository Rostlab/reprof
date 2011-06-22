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
use List::Util qw(shuffle);
use Reprof::Parser::Set;
use Reprof::Tools::Set;
use Reprof::Tools::Measure;
use Reprof::Methods::Fann qw(train_nn run_nn run_nn_return_set);

my $train_file;
my $crosstrain_file;
my $test_file;

my $window_size = 17;
my $num_hiddens = 300;

my $max_epochs = 1000;
my $learn_rate = 0.01;
my $learn_moment = 0.1;

my $max_decreasing_epochs = 15;

my $debug = 0;
my $net_file = "./test.net";	
my $result_file = "./test.data";

my $prenet_file;

$|++;

GetOptions(	
			'train=s'   	=> \$train_file,
			'crosstrain=s'   	=> \$crosstrain_file,
			'test=s'    	=> \$test_file,
			'net=s'	    	=> \$net_file,
			'prenet=s'      => \$prenet_file,
			'data=s'    	=> \$result_file,
			'window=i'  	=> \$window_size,
			'hidden=i'  	=> \$num_hiddens,
			'lrate=s'   	=> \$learn_rate,
			'lmoment=s'  	=> \$learn_moment,
			'epochs=i'      => \$max_epochs,
			'debug'	        => \$debug
			);

unless ($train_file && $crosstrain_file) {
    say "\nDESCRIPTION:";
    say "trains the reprof neural network with the given datasets";

    say "\nOPTIONS:";
    say "-train";
    say "\tdir containing the trainset";
    say "-crosstrain";
    say "\tdir containing the crosstrainset";
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
    say "-epochs";
    say "\tmaximum number of epochs";

    die "\nIncrosstrain options";
}


#--------------------------------------------------
# Open and parse setfiles
#-------------------------------------------------- 
sub init_set {
    my ($set_file) = @_;

    my $set;
    my $set_parser = Reprof::Parser::Set->new($set_file);
    if (defined $prenet_file) {
        my $prenet = AI::FANN->new_from_file($prenet_file);
        my $preset = $set_parser->get_set;
        my ($wsize) = ($prenet_file =~ m/\.w(\d+)\./);
        $preset->win($wsize);
        $set = run_nn_return_set($prenet, $preset);
    }
    else {
        $set = $set_parser->get_set;
    }
    $set->win($window_size);
    $set->iter('random');
    $set->reset_iter;

    return $set;
}


say "Parsing trainset... ";
my $train_set = init_set($train_file);
say "Parsing crosstrainset... ";
my $crosstrain_set = init_set($crosstrain_file);
# say "Parsing testset... ";
# my $test_set = init_set($test_file);


#--------------------------------------------------
# Helper variables
#-------------------------------------------------- 
my $num_features = $train_set->num_features;
my $num_outputs = $train_set->num_outputs;

my $num_inputs = $window_size * $num_features;

my $min_mse = 10;
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
open RESULT, ">", $result_file or die "Could not open $result_file\n";
select RESULT;
$|++;
select STDOUT;

#my @tmpdata;
#while (my $dp = $train_set->next_dp) {
#push @tmpdata, $dp->[1], $dp->[2];
#}
#my $traindata = AI::FANN::TrainData->new(@tmpdata);
#@tmpdata = ();

#while (my $dp = $crosstrain_set->next_dp) {
#push @tmpdata, $dp->[1], $dp->[2];
#}
#my $crosstraindata = AI::FANN::TrainData->new(@tmpdata);
#@tmpdata = ();

#--------------------------------------------------
# Loop through epochs 
#-------------------------------------------------- 
say "Starting to train...";
my $start_time = time;
foreach my $epoch (1 .. $max_epochs) {

    #--------------------------------------------------
    # Training 
    #-------------------------------------------------- 
    say "Epoch $epoch: training";

#$traindata->shuffle;
#my $train_mse = $ann->train_epoch($traindata);

    $ann->reset_MSE;
    while (my $dp = $train_set->next_dp) {
        $ann->train($dp->[1], $dp->[2]);
    }
    my $train_mse = $ann->MSE;

#train_nn($ann, $train_set);

    #--------------------------------------------------
    # Testing 
    #-------------------------------------------------- 
    # trainset
    say "Epoch $epoch: benchmark trainset...";

#my $train_measure = Reprof::Tools::Measure->new($num_outputs);
#run_nn($ann, $train_set, $train_measure);

#if ($train_measure->size == 1) {
#printf "MSE: %.3f\n", $train_measure->mse;
#}
#else {
#printf "Q3: %.3f\n", $train_measure->Q3;
#}
    
    # crosstrainset
    say "Epoch $epoch: benchmark crosstrainset...";

    $ann->reset_MSE;
#foreach my $iter (0 .. $crosstraindata->length - 1) {
    while (my $dp = $crosstrain_set->next_dp) {
#$ann->test($crosstraindata->data($iter));
        $ann->test($dp->[1], $dp->[2]);
    }
    my $crosstrain_mse = $ann->MSE;

#my $crosstrain_mse = $ann->test_on_data($crosstraindata);

#my $crosstrain_measure = Reprof::Tools::Measure->new($num_outputs);
#run_nn($ann, $crosstrain_set, $crosstrain_measure);

#my $crosstrain_current;
#if ($crosstrain_measure->size == 1) {
#$crosstrain_current = 1 - $crosstrain_measure->mse;
#printf "MSE: %.3f\n", $crosstrain_measure->mse;
#}
#else {
#$crosstrain_current = $crosstrain_measure->Q3;
#printf "Q3: %.3f\n", $crosstrain_measure->Q3;
#}

    
    # testset
#print "Epoch $epoch: benchmark testset... ";
#my $test_measure = Reprof::Tools::Measure->new($num_outputs);
#run_nn($ann, $test_set, $test_measure);
#if ($test_measure->size == 1) {
#printf "MSE: %.3f\n", $test_measure->mse;
#}
#else {
#printf "Q3: %.3f L: %.3f H: %.3f E: %.3f\n", $test_measure->Q3, $test_measure->Q_i(0), $test_measure->Q_i(1), $test_measure->Q_i(2);
#}

    # print output for benchmark on train crosstrain testsets
#if ($train_measure->size == 1) {
#printf RESULT "%s %.5f %.5f %.5f\n", 
#$epoch, 
#$train_measure->mse, 
#$crosstrain_measure->mse; 
#}
#else {
#printf RESULT "%s %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %s\n", 
#$epoch, 
#$train_measure->Q3, $crosstrain_measure->Q3,         # $test_measure->Q3, 
#$train_measure->Q_i(0), $crosstrain_measure->Q_i(0), # $test_measure->Q_i(0), 
#$train_measure->Q_i(1), $crosstrain_measure->Q_i(1), # $test_measure->Q_i(1), 
#$train_measure->Q_i(2), $crosstrain_measure->Q_i(2), # $test_measure->Q_i(2), 
#(time - $start_time);
#}

    printf RESULT "%s %s %s %s\n", $epoch, $train_mse, $crosstrain_mse, (time - $start_time);

    #--------------------------------------------------
    # Save nn if crosstrainset reaches new maximum value
    #-------------------------------------------------- 
    if ($crosstrain_mse < $min_mse) {
        $ann->save($net_file);
        $min_mse = $crosstrain_mse;
        $decreasing_epochs = 0;
    }
    else {
        $decreasing_epochs++;
    }

    if ($decreasing_epochs >= $max_decreasing_epochs) {
        say "Finished after epoch $epoch because no increasing crosstrain Q3 since $decreasing_epochs epochs";
        last;
    }
}

say RESULT "#END";
close RESULT;

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
