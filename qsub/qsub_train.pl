#!/usr/bin/perl -w
use strict;
use feature qw(say);

my $window_min = 3;
my $window_max = 19;
my $window_step = 2;

my $hidden_min = 10;
my $hidden_max = 150;
my $hidden_step = 10;

my $offset_min = 0;
my $offset_max = 9;
my $offset_step = 1;

my $base = "/mnt/project/reprof/";
my $bin = $base . "scripts/nnet/train.pl";
my $folds = $base . "data/folds/";


my $qsub_file_head = "#!/bin/sh\n"."export PERL5LIB=/mnt/project/reprof/perl/lib/perl/5.10.1";

for (my $window = $window_min; $window <= $window_max; $window += $window_step) {
	for (my $hidden = $hidden_min; $hidden <= $hidden_max; $hidden += $hidden_step) {
		for (my $offset = $offset_min; $offset <= $offset_max; $offset += $offset_step) {
			my $jobname = "o$offset" . "_w$window" . "_h$hidden";
			my $tmp = "/tmp/$jobname.sh";
			my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/ -e '.$base.'data/grid/ '.$tmp;
			
			my $data = $base . "data/results/" . "o$offset" . "_w$window" . "_h$hidden" . ".data";
			my $net = $base . "data/nets/" . "o$offset" . "_w$window" . "_h$hidden" . ".nnet";

			my @cmd = ( 
				$bin, 
				"-data", $data, 
				"-net", $net, 
				"-offset", $offset, 
				"-window", $window,
				"-hidden", $hidden,
				"-folds", $folds);

			open FH, '>', $tmp or die "Could not open $tmp\n";
			say FH $qsub_file_head;
			say FH (join ' ', @cmd);
			close FH;
			chmod 0777, $tmp or die "Could not change file permissions of $tmp\n";
			say `$qsub`;
			unlink $tmp or die "Could not delete $tmp\n";
		}
	}
}
