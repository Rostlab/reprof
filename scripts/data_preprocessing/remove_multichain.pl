#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Reprof::Source::dssp;
use Reprof::Parser::dssp;

my $fasta_file = shift;

open FASTA, "$fasta_file" or croak "Could not open $fasta_file\n";
while (my $header = <FASTA>) {
    my $seq = <FASTA>;
    chomp $header;
    chomp $seq;
    my $id = substr $header, 1;
    my ($file, $chain) = Reprof::Source::dssp->rost_db($id, $seq);
    my $dssp_parser = Reprof::Parser::dssp->new($file);

    my $chains = $dssp_parser->get_chains;
    my $chain_count = scalar @$chains;

    if ($chain_count == 1) {
        say ">$id";
        say "$seq";
    }
}
