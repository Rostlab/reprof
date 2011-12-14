#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use File::Spec;

my @files = @ARGV;

my $out_dir = "/mnt/project/reprof/data/horiz/";
my $psipred_bin = "/mnt/project/reprof/tools/psipred/runpsipred";
my $tmp_dir = "/tmp/psipred/";

foreach my $f (@files) {
    my $fasta_file = File::Spec->rel2abs($f);
    my ($v, $d, $out) = File::Spec->splitpath($fasta_file);
    $out =~ s/\.fasta$//;

    open FH, "> job.sh" or confess "fh error\n";
    say FH join "\n", 
        "#!/bin/sh",
        "~rost_db/src/spreadBig_80.pl",
        "mkdir $tmp_dir",
        "cd $tmp_dir",
        "$psipred_bin $fasta_file",
        "mv $out.* $out_dir";
    close FH;
    say `qsub job.sh`;
}
