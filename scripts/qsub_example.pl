#!/usr/bin/perl -w
use strict;
use feature qw(say);
use File::Path qw(make_path);
use Cwd;
use Carp;
use Data::Dumper;

#--------------------------------------------------
# base settings 
#-------------------------------------------------- 
my $base = "/mnt/project/reprof/";
my $setconvert = "$base/scripts/setconvert.pl";
my $nntrain = "$base/scripts/nntrain.pl";
my $out_base = getcwd;
#--------------------------------------------------
# set
#-------------------------------------------------- 
my $set_train_list = "option list $base/data/lists/all1.list";
my $set_ctrain_list = "option list $base/data/lists/all2.list";
my $set_test_list = "option list $base/data/lists/all3.list";
my $set_set = "option set $base/data/sets/all.set";
my $set_format = "option format fann";
my @set_windows = (1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29);
my @set_selected_features = ();
my @set_unselected_features = (
        "input pssm normalized",
        "input pssm percentage",
        "input pssm weight",
        "input pssm info",
        "input fasta profile",
        "input fasta relative_position",
        "input fasta relative_position_reverse",
        "input fasta mass",
        "input fasta volume",
        "input fasta hydrophobicity",
        "input fasta cbeta",
        "input fasta hbreaker",
        "input fasta charge",
        "input fasta in_sequence_bit",
        "input fasta polarity"
);

my @set_unselected_globals = (
        "input fasta aa_composition",
        "input fasta length_5state"
    );

my @set_features_2test;
foreach my $feat (@set_unselected_features) {
    foreach my $win (@set_windows) {
        push @set_features_2test, "$feat $win";
    }
}
foreach my $feat (@set_unselected_globals) {
    push @set_features_2test, "$feat 1";
}

my $set_output = "output dssp ss_3state 1";
#--------------------------------------------------
# linking 
#-------------------------------------------------- 
my $trainset;
my $ctrainset;
my $testset;
#--------------------------------------------------
# neural net 
#-------------------------------------------------- 
my @nn_hiddens = (
        "option hiddens 50", 
        "option hiddens 100", 
        "option hiddens 200", 
        "option hiddens 400",
        "option hiddens 600"
        );
my $nn_balanced = "option balanced 0";
my $nn_learning_rate = "option learning_rate 0.01"; 
my $nn_learning_momentum = "option learning_momentum 0.3";
my $nn_max_epochs = "option max_epochs 200";
my $nn_wait_epochs = "option wait_epochs 5";
# variable
my $nn_out;
#--------------------------------------------------
# ogog 
#-------------------------------------------------- 
my $count = 0;
foreach my $set_feature_2test (@set_features_2test) {
    foreach my $nn_hidden (@nn_hiddens) {
        $count++;
        my $out = "$out_base/$count/";
        next if -e $out;
        my $tmp = "/tmp/reprof/$out/";
        make_path $out;


        $trainset = "$tmp/train.set";
        $ctrainset = "$tmp/ctrain.set";
        $testset = "$tmp/test.set";

        sub write_setconvert {
            my ($cfg_file, $list_file, $out_file, $feature_2test, @selected_features) = @_;
            open OUT, ">", $cfg_file or croak "Could not open $cfg_file\n";
            say OUT $list_file;
            say OUT $set_set;
            say OUT $set_format;
            say OUT "option out $out_file";
            say OUT $set_output;
            say OUT join "\n", @selected_features;
            say OUT $feature_2test;
            close OUT;
        }

        my $setconvert_train = "$out/train.setconvert";
        my $setconvert_ctrain = "$out/ctrain.setconvert";
        my $setconvert_test = "$out/test.setconvert";

        write_setconvert($setconvert_train, $set_train_list, $trainset, $set_feature_2test, @set_selected_features);
        write_setconvert($setconvert_ctrain, $set_ctrain_list, $ctrainset, $set_feature_2test, @set_selected_features);
        write_setconvert($setconvert_test, $set_test_list, $testset, $set_feature_2test, @set_selected_features);

        my $nntrain_config = "$out/nntrain.nntrain";
        my $nn_out = "option out $out";

        open OUT, ">", $nntrain_config or croak "Coult not open $nntrain_config\n";
        say OUT $nn_hidden;
        say OUT $nn_learning_rate;
        say OUT $nn_learning_momentum;
        say OUT $nn_max_epochs;
        say OUT $nn_wait_epochs;
        say OUT $nn_out;
        say OUT $nn_balanced;
        say OUT "option trainset $trainset";
        say OUT "option ctrainset $ctrainset";
        say OUT "option testset $testset";
        close OUT;

        my $qsub_file = "$out/hi_tim.sh";
        open QSUB, ">", $qsub_file or croak "Could not open $qsub_file\n";
        say QSUB join "\n", 
                "#!/bin/sh",
                "export PERL5LIB=/mnt/project/reprof/lib/perl",
                "mkdir -p $tmp",
                "$setconvert -config $setconvert_train",
                "$setconvert -config $setconvert_ctrain",
                "$setconvert -config $setconvert_test",
                "$nntrain -config $nntrain_config",
                "rm -rf $tmp";
        close QSUB;
        chmod 777, $qsub_file;

        my $qsub = 'qsub -o '.$out.' -e '.$out.' '.$qsub_file;
        say `$qsub`;

    }
}

say $count." jobs submitted...";
