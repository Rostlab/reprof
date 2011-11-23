#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $fasta_file;
my $out_prefix;
my $min_length = 45;

GetOptions(
    'fasta=s'    =>  \$fasta_file,
    'out=s'      =>  \$out_prefix,
);

my %out;
open FASTA, $fasta_file or confess "fh error\n";
while (my $header = <FASTA>) {
    next if ($header !~ m/^>/);

    my $sequence = <FASTA>;
    chomp $header;
    chomp $sequence;

    next if length $sequence < $min_length;

    my $id = substr $header, 1;
    my @split_id = split /\|/, $id;
    
    if (! exists $out{$split_id[-1]}) {
        $out{$split_id[-1]} = [];
    }

    push @{$out{$split_id[-1]}}, [$split_id[0], $sequence];
}
close FASTA;

foreach my $key (keys %out) {
    open FH, "> $out_prefix"."_$key.fasta", or confess "fh error\n";
    foreach my $protein (@{$out{$key}}) {
        say FH ">$protein->[0]";
        say FH "$protein->[1]";
    }
    close FH;
}
