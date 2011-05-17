#!/usr/bin/perl -w
use strict;
use feature qw(say);

my $window_min = 5;
my $window_max = 31;
my $window_step = 2;

my $hidden_min = 5;
my $hidden_max = 250;
my $hidden_step = 5;

#my $type = "ss";
my $type = "acc";

#my $subtype = "seq";
my $subtype = "struc";

#my $networks = [
#    ];
my $networks = [
    ];

my $setcombos = [[1, 2, 3], [2, 3, 1], [3, 1, 2]]; 

my $lrate = 0.01;
my $lmoment = 0.1;

my $base = "/mnt/project/reprof/";
my $bin = $base . "scripts/train_reprof.pl";
my $sets = $base . "data/sets/$type/";
my $results = $base . "data/results/";
my $nets = $base . "data/nets/";


my $qsub_file_head = "#!/bin/sh\n"."export PERL5LIB=/mnt/project/reprof/lib/perl";

my $count = 0;
foreach my $setcombo (@$setcombos) { 
    my $trainset = $setcombo->[0];
    my $crosstrainset = $setcombo->[1];
    my $testset = $setcombo->[2];

    for (my $window = $window_min; $window <= $window_max; $window += $window_step) {
        for (my $hidden = $hidden_min; $hidden <= $hidden_max; $hidden += $hidden_step) {
            my $base_filename = "ty$type.st$subtype.tr$trainset.ct$crosstrainset.te$testset.w$window.h$hidden.lr$lrate.lm$lmoment";

            my $jobname = $base_filename;
            $jobname =~ s/\./_/g;

            my $tmp = "/tmp/$jobname.sh";
            my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/ -e '.$base.'data/grid/ '.$tmp;

            my @cmd = ( 
                    'time '         , $bin, 
                    '-train'   	    , "$sets/$trainset.set",
                    '-crosstrain'	, "$sets/$crosstrainset.set",
                    '-test'    	    , "$sets/$testset.set",
                    '-net'	        , "$nets/$base_filename.net",
                    '-data'    	    , "$results/$base_filename.result",
                    '-window'  	    , $window,
                    '-hidden'  	    , $hidden,
                    '-lrate'   	    , $lrate,
                    '-lmoment'      , $lmoment );

            if ($subtype eq 'struc') {
                push @cmd,
                     '-prenet'      , $networks->[$trainset - 1];
            }

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
