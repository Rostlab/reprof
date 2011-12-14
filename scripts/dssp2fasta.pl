#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

use Perlpred::Parser::dssp;
use Perlpred::Source::dssp;

my $list_file;
my $out_file;
my $min;

GetOptions(
    'list=s'    =>  \$list_file,
    'min=s'    =>  \$min,
);

open LIST, $list_file or croak "Could not open $list_file\n";
my @list = <LIST>;
chomp @list;
close LIST;

my %sequences;
my $missing = 0;
foreach my $line (@list) {
    my ($entry) = split /\s+/, $line;
    my ($dssp_file) = Perlpred::Source::dssp->rost_db($entry);
    if (! -e $dssp_file) {
        $missing++;
        warn "$dssp_file not found\n";
    }
    else {
        my $dssp_parser = Perlpred::Parser::dssp->new($dssp_file);
        my $chains = $dssp_parser->get_chains;
        foreach my $chain (@$chains) {
            my @seq = $dssp_parser->res($chain);
            if (scalar @seq >= $min) {
                my $seq = join "", @seq;
                my $id = "$entry:$chain";
                $sequences{$seq} = $id;
            }
        }
    }
}
warn "\n$missing files not found\n";

foreach my $seq (keys %sequences) {
    if ($seq !~ m/X{$min,}/) {
        my $id = $sequences{$seq};
        say ">$id";
        say $seq;
    }
}
