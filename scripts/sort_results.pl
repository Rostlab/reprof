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
my $reverse = 0;
if ($col eq 'r') {
    $reverse = 1;
    $col = shift;
}
my @bests;
foreach my $file (@ARGV) {
    my @vals;

    open FH, $file or die "Could not open $file\n";
    while (<FH>) {
        next if /^#/;

        my @split = split /\s+/;
        push @split, $file;
        push @vals, \@split;
    }
    close FH;
    
    if (scalar @vals > 0) {
        my $winner;
        if ($reverse) {
            $winner = (sort {$a->[$col] <=> $b->[$col]} @vals)[0];
        }
        else {
            $winner = (sort {$b->[$col] <=> $a->[$col]} @vals)[0];
        }
        push @bests, $winner;
    }
}

my @sorted;
if ($reverse) {
    @sorted = sort {$a->[$col] <=> $b->[$col]} @bests;
}
else {
    @sorted = sort {$b->[$col] <=> $a->[$col]} @bests;
}

foreach my $item (@sorted) {
    say join "\t", @$item;
}
