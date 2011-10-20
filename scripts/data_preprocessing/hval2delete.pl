#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $fasta_file;
my $hval_file;
my $threshold;

GetOptions(
    'fasta|f=s'    =>  \$fasta_file,
    'hval|h=s'    =>  \$hval_file,
    'threshold|t=s'    =>  \$threshold,
);

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

open HVAL, $hval_file or croak "Could not open $hval_file\n";
my @hval = <HVAL>;
chomp @hval;
close HVAL;

foreach my $line (@hval) {
    my ($query, $target, $hval) = split /\|{10}/, $line;
    if ($hval > $threshold) {
        if (exists $head2seq{$target}) {
            delete $head2seq{$target};
            warn "$target deleted $hval\n";
        }
        else {
            warn "$target deleted again $hval\n";
        }
    }
}

foreach my $id (keys %head2seq) {
    my $seq = $head2seq{$id};
    $seq =~ s/\s+//g;

    say ">$id";
    say $seq;
}

