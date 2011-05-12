#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Reprof::Parser::Dssp;
use Reprof::Tools::Converter qw(convert_id);
use Getopt::Long;

my $minlength = 60;
my $dssp_glob;
my $fasta_file;

GetOptions( 
    "d|dssp=s"      => \$dssp_glob,
    "m|minlength=i" => \$minlength,
    "f|fasta=s"     => \$fasta_file
);

my @dssp_files = glob $dssp_glob;

open FASTA, '>', $fasta_file;

foreach my $file (@dssp_files) {
    say "Parsing $file";

    my $id = convert_id($file, 'pdb');

    my $parser = Reprof::Parser::Dssp->new($file);

    foreach my $chain (@{$parser->get_chains}) {
        my $seq = join '', @{$parser->get_res($chain)};
        if (length $seq >= $minlength) {
                printf  FASTA ">%s\n%s\n", $parser->get_id($chain), $seq;
        }
    }
}
close FASTA;
