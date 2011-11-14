#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $fasta_file;
my $test_id_file;
my $ctrain_id_file;

GetOptions(
    'fasta=s'    =>  \$fasta_file,
    'test=s'    =>  \$test_id_file,
    'ctrain=s'  =>  \$ctrain_id_file,
);

my %test_ids;
open TEST, $test_id_file or croak "fh error";
while (my $line = <TEST>) {
    chomp $line;
    $test_ids{$line} = 1;
}
close TEST;

my %ctrain_ids;
open CTRAIN, $ctrain_id_file or croak "fh error";
while (my $line = <CTRAIN>) {
    chomp $line;
    $ctrain_ids{$line} = 1;
}
close CTRAIN;

my %sequences;
open FASTA, $fasta_file  or croak "fh error";
my $id;
while (my $line = <FASTA>) {
    chomp $line;
    if ($line =~ m/^>/) {
        my $header = substr $line, 1;
        my ($i, $c) = split /_/, $header;
        $id = (lc $i).":".(uc $c);
        $sequences{$id} = "";
    }
    else {
        $line =~ s/ //g;
        $sequences{$id} .= uc $line;
    }
}

open TRAIN, ">./train.fasta" or croak "fh error";
open CTRAIN, ">./ctrain.fasta" or croak "fh error";
open TEST, ">./test.fasta" or croak "fh error";

foreach my $id (keys %sequences) {
    my $sequence = $sequences{$id};
    if (exists $test_ids{$id}) {
        say TEST ">$id";
        say TEST $sequence;
        say "$id -> test";
    }
    elsif (exists $ctrain_ids{$id}) {
        say CTRAIN ">$id";
        say CTRAIN $sequence;
        say "$id -> ctrain";
    }
    else {
        say TRAIN ">$id";
        say TRAIN $sequence;
        say "$id -> train";
    }
}

close TRAIN;
close CTRAIN;
close TEST;
