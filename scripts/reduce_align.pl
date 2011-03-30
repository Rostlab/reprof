#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my $file;
my $min_hval;
my $max_hval;
my $c;

GetOptions( "count|c"   => \$c,
            "min=i"     => \$min_hval,
            "max=i"     => \$max_hval );

my $count = 0;

while (<>) {
    my ($query, $target, $length, $seqid, $hval) = split /\s+/;
    if ((!defined $min_hval || $hval > $min_hval) && (!defined $max_hval || $hval <= $max_hval)) {
        unless ($query eq $target) {
            print $_;
            $count++;
        }
    }
}

say $count if $c;
    
