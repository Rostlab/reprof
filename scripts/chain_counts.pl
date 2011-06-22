#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Setbench::Parser::dssp;
use Carp;
use Data::Dumper;

my $list = shift;
open LIST, $list or croak "Could not open $list\n";
my @list = <LIST>;
chomp @list;
close LIST;

foreach my $entry (@list) {
    my $id = substr $entry, 0, 4;
    my $dssp = "/mnt/project/rost_db/data/dssp/".(substr $id, 1, 2)."/pdb".($id).".dssp";
    my $dssp_parser = Setbench::Parser::dssp->new($dssp);
    my $chain_count = scalar @{$dssp_parser->getchains};
    if ($chain_count == 1) {
        say $entry;
    }
}
