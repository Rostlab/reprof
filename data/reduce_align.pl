#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my $file;
my $min_hval;
my $max_hval;

GetOptions( "file=s"    => \$file,
        "minhval=i" => \$min_hval,
        "maxhval=i" => \$max_hval );

open IN, $file or die "Could not open $file...\n";

while (<IN>) {
    my ($query, $target, $length, $seqid, $hval) = split /\s+/;
    if ((!defined $min_hval || $hval >= $min_hval) && (!defined $max_hval || $hval <= $max_hval)) {
        print $_;
    }
}

close IN;
    
