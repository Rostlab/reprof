#!/usr/bin/perl -w
use strict;
use feature qw(say);

my $window_min = 15;
my $window_max = 31;
my $window_step = 2;

my $hidden_min = 5;
my $hidden_max = 150;
my $hidden_step = 5;

my $set_min = 1;
my $set_max = 3;

#my $type = "seqlayer";
my $type = "struclayer";

my $lrate = 0.01;
my $lmoment = 0.1;

my $base = "/mnt/project/reprof/";
my $bin = $base . "scripts/train_reprof.pl";
my $train = $base . "data/sets/$type/train/";
my $valid = $base . "data/sets/$type/valid/";
my $test = $base . "data/sets/$type/test/";
my $results = $base . "data/results/";
my $nets = $base . "data/nets/";


my $qsub_file_head = "#!/bin/sh\n"."export PERL5LIB=/mnt/project/reprof/lib/perl";

my $count = 0;
foreach my $set ($set_min .. $set_max) { 
    for (my $window = $window_min; $window <= $window_max; $window += $window_step) {
        for (my $hidden = $hidden_min; $hidden <= $hidden_max; $hidden += $hidden_step) {
            my $base_filename = "t$type.s$set.w$window.h$hidden.lr$lrate.lm$lmoment";

            my $jobname = $base_filename;
            $jobname =~ s/\./_/g;

            my $tmp = "/tmp/$jobname.sh";
            my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/train/ -e '.$base.'data/grid/train/ '.$tmp;

            my @cmd = ( 
                    'time '     , $bin, 
                    '-train'   	, "$train/$set/",
                    '-valid'   	, "$valid/$set/",
                    '-test'    	, "$test/$set/",
                    '-net'	, "$nets/$base_filename.net",
                    '-data'    	, "$results/$base_filename.result",
                    '-window'  	, $window,
                    '-hidden'  	, $hidden,
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
