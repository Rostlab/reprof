#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Carp;
use List::Util qw(shuffle);
use Setbench::Parser::fasta;

my $in;
my $out;

GetOptions( 'in|i=s'    =>  \$in,
        'out|o=s'    =>  \$out
        );

my $parser = Setbench::Parser::fasta->new($in);
my @id_list = $parser->id_list;
my @shuffled_ids = shuffle @id_list;

open OUT, ">", $out or croak "Could not open $out\n";
foreach my $id (@shuffled_ids) {
    my @residues = $parser->residue($id);
    my $sequence = join "", @residues;
    my $header = ">$id";

    say OUT $header;
    say OUT $sequence;
}
close OUT;
