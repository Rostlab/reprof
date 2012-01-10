#!/usr/bin/perl
use warnings;
use strict;
use Carp;
use Getopt::Long;
use Pod::Usage;

my $bin = "/mnt/project/reprof/scripts/reprof.pl";
my $tmp_base = "/tmp/reprof/";

my $min_length = 1;
my $max_length = 1000;


foreach my $length ($min_length .. $max_length) {
    my $seq = "X" x $length;
    my $tmp_dir = "$tmp_base/$length/";
    my $tmp_file = "$tmp_dir/$length";

    open JOB, "> ./job.sh" or confess "fh error\n";

    print JOB "#!/bin/sh\n";
    print JOB "echo \"length $length\" 1>&2\n";
    print JOB "mkdir -p $tmp_dir\n";
    print JOB "time $bin -seq $seq -out $tmp_file -mutations all\n";
    print JOB "rm -rf $tmp_dir\n";

    close JOB;

    print `qsub ./job.sh`, "\n";
}
