#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use File::Spec;

my $infile = '/mnt/project/reprof/data/lists/pdb_diffraction.list';
my $min_res = 0;
my $max_res = 2;

GetOptions(
            'in=s'	=> \$infile,
            'min=i'	=> \$min_res,
            'max=i'	=> \$max_res );

open IN, $infile;
my @input = <IN>;
chomp @input;
close IN;

foreach my $in (@input) {
        my ($id, $type, $method, $res) = split /\s+/, $in;

        if ($res >= $min_res && $res <= $max_res) {
            say $in;
        }
}

