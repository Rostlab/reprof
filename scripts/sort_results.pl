#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     sorts files according to their 
#           highest value in the given column
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

my $col = shift;
my @bests;
foreach my $file (@ARGV) {
    my $max_val = -1;
    my @max_col;
    
    open FH, $file or die "Could not open $file\n";
    while (<FH>) {
        my @split = split /\s+/;
        if ($split[$col] >= $max_val) {
            $max_val = $split[$col];
            @max_col = @split;
        }
    }
    close FH;
    
    push @max_col, $file;
    push @bests, \@max_col;
}

my @sorted = sort {$a->[$col] <=> $b->[$col]} @bests;

foreach my $item (@sorted) {
    say join "\t", @$item;
}
