#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use List::Util qw(shuffle);

my $fasta_file = shift;

open FH, $fasta_file or croak "fh error\n";
my @content = <FH>;
chomp @content;
close FH;

my $current_header;
my %head2seq;
foreach my $line (@content) {
    if ($line =~ m/^>/) {
        $current_header = substr $line, 1;
        if (exists $head2seq{$current_header}) {
            warn "double header $current_header";
        }
        $head2seq{$current_header} = "";
    }
    else {
        $head2seq{$current_header} .= $line;
    }
}

foreach my $id (shuffle keys %head2seq) {
    my $seq = $head2seq{$id};
    $seq =~ s/\s+//g;

    say ">$id";
    say $seq;
}

