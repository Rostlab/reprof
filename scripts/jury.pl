#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use List::Util qw(sum);

my @files = @ARGV;
my @data;
foreach my $file (@files) {
    open FH, "$file" or croak "Could not open $file\n";
    my @content = <FH>;
    chomp @content;
    close FH;
    
    my $row_iter = 0;
    foreach my $row (@content) {
        my @split = split /\s+/, $row;
        my $sum = sum @split;
        foreach my $s (@split) {
            $s /= $sum;
        }

        if (scalar @data <= $row_iter) {
            push @data, \@split;
        }
        else {
            my $ele_iter = 0;
            foreach my $element (@split) {
                $data[$row_iter][$ele_iter] += $element;

                $ele_iter++;
            }
        }

        $row_iter++;
    }
}

my $num_files = scalar @files;
foreach my $row (@data) {
    foreach my $element (@$row) {
        $element /= $num_files;
    }
}

foreach my $row (@data) {
    say join " ", @$row;
}
