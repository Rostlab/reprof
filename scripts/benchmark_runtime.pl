#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
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

    say JOB "#!/bin/sh";
    say JOB "echo \"length $length\" 1>&2";
    say JOB "mkdir -p $tmp_dir";
    say JOB "time $bin -seq $seq -out $tmp_file -mutations all";
    say JOB "rm -rf $tmp_dir";

    close JOB;

    say `qsub ./job.sh`;
}
