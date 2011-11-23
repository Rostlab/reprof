#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $fasta_file = shift;
my $min_length = 45;
open FASTA, $fasta_file or confess "fh error\n";
while (my $header = <FASTA>) {
    next if ($header !~ m/^>/);

    my $sequence = <FASTA>;
    chomp $header;
    chomp $sequence;

    next if length $sequence < $min_length;

    my $id = substr $header, 1;
    my @split_id = split /\|/, $id;
    say ">$split_id[1]";
    say $sequence;
}
close FASTA;
