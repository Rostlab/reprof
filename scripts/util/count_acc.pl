#!/usr/bin/perl -w
use strict;
use feature qw(say);

my @dssp_files = glob "/mnt/project/rost_db/data/dssp/*/*.dssp";
say STDERR "Found ".(scalar @dssp_files)." files";

my %counts;
foreach my $file (@dssp_files) {
    open DSSP, $file;
    my $started = 0;
    while (my $line = <DSSP>) {
        if (!$started && $line =~ m/  #  RESIDUE AA/) {
            $started = 1;
        }
        elsif ($started) {
            my $acc = substr $line, 34, 5;
            $counts{$acc}++;
        }
    }
    close DSSP;
}

foreach my $acc (sort keys %counts) {
    say "$acc $counts{$acc}";
}
