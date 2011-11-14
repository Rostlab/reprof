#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $in;
my $out;

GetOptions(
    'in|i=s'    =>  \$in,
    'out|o=s'    =>  \$out,
);

open IN, "$in" or croak "fh error\n";
while (my $header = <IN>) {
    my $sequence = <IN>;
    chomp $header;
    chomp $sequence;

    my $id = substr $header, 1;
    
    open OUT, ">", "$out/$id.fasta" or croak "fh error\n";
    say OUT $header;
    say OUT $sequence;
    close OUT;
}
close IN;
