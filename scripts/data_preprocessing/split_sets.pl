#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use POSIX qw(floor);
use List::Util qw(shuffle);

my $num_bins = 10;
my $fasta_out;

GetOptions(
    'bins|b=s'    =>  \$num_bins,
    'fasta|f=s'    =>  \$fasta_out,
);

my @fasta_files = @ARGV;

my $bins = [];
foreach (1 .. $bins) {
    push @$bins, [];
}

foreach my $fasta_file (@fasta_files) {
    my $sequences = [];
    open FASTA, $fasta_file or croak "fh error\n";
    while (my $header = <FASTA>) {
        my $sequence = <FASTA>;
        chomp $header;
        my $id = substr $header, 1;
        chomp $sequence;
        push @$sequences, [$id, $sequence];
    }

    my $bin_size = floor((scalar @$sequences) / $num_bins);

    my $iter = 0;
    foreach my $seq (shuffle @$sequences) {
        my $current_bin = $iter % $num_bins;
        push @{$bins->[$current_bin]}, $seq;

        $iter++;
    }
}

$fasta_out=~ s/\.fasta$//;
foreach my $i (1 .. $num_bins) {
    open FH, ">", "$fasta_out"."_$i.fasta" or croak "fh error\n";
    foreach my $seq (@{$bins->[$i - 1]}) {
        say FH ">".$seq->[0];
        say FH $seq->[1];
    }
    close FH;

    my $to = $i + ($num_bins - 3);
    open FH, ">", "$fasta_out"."_$i-".($to % $num_bins).".fasta" or croak "fh error\n";
    foreach my $bin ($i - 1 .. $to - 1) {
        foreach my $seq (@{$bins->[$bin % $num_bins]}) {
            say FH ">".$seq->[0];
            say FH $seq->[1];
        }
    }
    close FH;
}
