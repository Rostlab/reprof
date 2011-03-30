#!/usr/bin/perl -w
use strict;
use feature qw(say);

my $window_min = 9;
my $window_max = 31;
my $window_step = 2;

my $hidden_min = 30;
my $hidden_max = 200;
my $hidden_step = 10;

my $set_min = 1;
my $set_max = 1;
my $type = "seqlayer";

my $lrate = 0.01;
my $lmoment = 0.1;

my $precise = 0;

my $base = "/mnt/project/reprof/";
my $bin = $base . "scripts/train_reprof.pl";
my $train = $base . "data/sets_$type/train/";
my $valid = $base . "data/sets_$type/valid/";
my $test = $base . "data/sets_$type/test/";
my $results = $base . "data/results/";
my $nets = $base . "data/nets/";


my $qsub_file_head = "#!/bin/sh\n"."export PERL5LIB=/mnt/project/reprof/perl/lib/perl/5.10.1";

my $count = 0;
foreach my $set ($set_min .. $set_max) { 
    for (my $window = $window_min; $window <= $window_max; $window += $window_step) {
        for (my $hidden = $hidden_min; $hidden <= $hidden_max; $hidden += $hidden_step) {
            my $base_filename = "t$type.s$set.w$window.h$hidden.lr$lrate.lm$lmoment.p$precise";

            my $jobname = $base_filename;
            $jobname =~ s/\./_/g;

            my $tmp = "/tmp/$jobname.sh";
            my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/train/ -e '.$base.'data/grid/train/ '.$tmp;

            my @cmd = ( 
                    'time '     , $bin, 
                    '-train'   	, "$train/$set/",
                    '-valid'   	, "$valid/$set/",
                    '-test'    	, "$test/$set/",
                    '-net'	   	, "$nets/$base_filename.net",
                    '-data'    	, "$results/$base_filename.result",
                    '-window'  	, $window,
                    '-hidden'  	, $hidden,
                    '-precise'  , $precise,
                    '-lrate'   	, $lrate,
                    '-lmoment'  , $lmoment );

            open FH, '>', $tmp or die "Could not open $tmp\n";
            say FH $qsub_file_head;
            say FH (join ' ', @cmd);
            close FH;
            chmod 0777, $tmp or die "Could not change file permissions of $tmp\n";
            say `$qsub`;
            $count++;
            unlink $tmp or die "Could not delete $tmp\n";
        }
    }
}

say "$count jobs submitted...";
