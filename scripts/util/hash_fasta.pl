#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my $fasta;
my $out;

GetOptions( 'f|fasta=s' => \$fasta,
            'o|out=s'   => \$out);

my %seqs;
open FASTA, $fasta or die "Could not open $fasta\n";
while (my $line = <FASTA>) {
    if ($line =~ m/^>/) {
        my $header = $line;
        my $sequence = <FASTA>;

        $seqs{$sequence} = $header;
    }
}
close FASTA;

open OUT, '>', $out or die "Could not open $out\n";
while (my ($seq, $id) = each %seqs) {
    print OUT "$id$seq";
}
close OUT;

say scalar keys %seqs;

