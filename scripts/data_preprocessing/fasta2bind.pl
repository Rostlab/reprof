#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $fasta_file;
my $bind_out;

GetOptions(
    'fasta|f=s'    =>  \$fasta_file,
    'bind|b=s'    =>  \$bind_out,
);

open FASTA, $fasta_file or croak "fh error\n";
while (my $header = <FASTA>) {
    chomp $header;
    my $id = substr $header, 1;
    my $seq = <FASTA>;
    chomp $seq;

    my $out_file = "$bind_out/$id.bind";
    if (-e $out_file) {
        say "$out_file exists...";
    }
    open BIND, ">", $out_file;
    say BIND "#RES BINDING NOT_BINDING";
    my @split_seq = split //, $seq;
    foreach my $res (@split_seq) {
        say BIND "$res 0 1";
    }
    close BIND;
}
