#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Carp;

my $fasta_file;
my $out_dir;

GetOptions( 
    'fasta|f=s'    =>  \$fasta_file,
    'out|o=s'    =>  \$out_dir
);

my %data;
my $current_header;
open FASTA, $fasta_file or croak "Could not open $fasta_file\n";
while (my $line = <FASTA>) {
    chomp $line;
    if ($line =~ m/^>/) {
        $current_header = substr $line, 1;
        $data{$current_header} = "";
    }
    else {
        $line =~ s/\s+//g;
        $data{$current_header} .= $line;
    }
}

foreach my $header (keys %data) {
    open OUT, ">", "$out_dir/$header.fasta";
    say OUT ">$header";
    say OUT $data{$header};
    close OUT;
}
