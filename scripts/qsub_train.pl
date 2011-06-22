#!/usr/bin/perl -w
use strict;
use feature qw(say);

my $window_min = 7;
my $window_max = 29;
my $window_step = 2;

my $hidden_min = 10;
my $hidden_max = 300;
my $hidden_step = 10;

my $rates =      [0.01, 0.1, 0.3, 0.5, 0.7, 0.9];

my $types = ["ss"];#, "acc"];

my $subtype = "seq";
#my $subtype = "struc";

my $subsubtypes = ["norm", "pc"];

#my $networks = [
#   ];
my $networks = [
    ];

my $setcombos = [[1, 2, 3]];#, [2, 3, 1], [3, 1, 2]]; 


my $base = "/mnt/project/reprof/";
my $bin = $base . "scripts/train_reprof.pl";
my $sets = $base . "data/sets/";
my $results = $base . "data/results/";
my $nets = $base . "data/nets/";

my $qsub_file_head = "#!/bin/sh\n"."export PERL5LIB=/mnt/project/reprof/lib/perl";

my $count = 0;
foreach my $setcombo (@$setcombos) { 
    my $trainset = $setcombo->[0];
    my $crosstrainset = $setcombo->[1];
    my $testset = $setcombo->[2];

    foreach my $lrate_pos (0 .. scalar @$rates - 1) {
        my $lrate = $rates->[$lrate_pos];

        foreach my $mrate_pos ($lrate_pos + 1 .. scalar @$rates - 1) {
            my $lmoment = $rates->[$mrate_pos];

            for (my $window = $window_min; $window <= $window_max; $window += $window_step) {

                for (my $hidden = $hidden_min; $hidden <= $hidden_max; $hidden += $hidden_step) {
                    for my $type (@$types) {

                        for my $subsubtype (@$subsubtypes) {
                            my $base_filename = "ty$type.st$subtype.ss$subsubtype.tr$trainset.ct$crosstrainset.te$testset.w$window.h$hidden.lr$lrate.lm$lmoment";

                            my $trainset_file       = "$sets/$trainset.$type.$subsubtype.set";
                            my $crosstrainset_file  = "$sets/$crosstrainset.$type.$subsubtype.set";
                            my $testset_file        = "$sets/$testset.$type.$subsubtype.set";
                            my $net_file            = "$nets/$base_filename.net";
                            my $result_file         = "$results/$base_filename.result";

                            if (-e $net_file || -e $result_file) {
                                next;
                            }

                            my $jobname = $base_filename;
                            $jobname =~ s/\./_/g;
                            my $tmp = "/tmp/$jobname.sh";

                            my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/ -e '.$base.'data/grid/ '.$tmp;

                            my @cmd = ( 
                                    $bin, 
                                    '-train'   	    , $trainset_file,
                                    '-crosstrain'	, $crosstrainset_file,
                                    '-test'    	    , $testset_file,
                                    '-net'	        , $net_file,
                                    '-data'    	    , $result_file,
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
                            say "$qsub";
                            $count++;
                            unlink $tmp or die "Could not delete $tmp\n";
                        }
                    }
                }
            }
        }
    }
}

say "$count jobs submitted...";
