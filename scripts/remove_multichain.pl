#!/usr/bin/perl -w
use strict;
use Carp;
use Perlpred::Source::dssp;
use Perlpred::Parser::dssp;

my @fasta_files = @ARGV;

foreach my $fasta_file (@fasta_files) {

    my $fasta_out = $fasta_file;
    $fasta_out =~ s/\.fasta$//;
    $fasta_out .= "_onechain.fasta";
    open OUT, ">", "$fasta_out" or croak "Could not open $fasta_out\n";

    open FASTA, "$fasta_file" or croak "Could not open $fasta_file\n";

    print "$fasta_file -> $fasta_out\n";
    while (my $header = <FASTA>) {
        my $seq = <FASTA>;
        chomp $header;
        chomp $seq;
        my $id = substr $header, 1;
        my ($file, $chain) = Perlpred::Source::dssp->rost_db($id, $seq);
        my $dssp_parser = Perlpred::Parser::dssp->new($file);

        my $chains = $dssp_parser->get_chains;
        my $chain_count = scalar @$chains;

        if ($chain_count == 1) {
            print OUT ">$id\n";
            print OUT "$seq\n";
        }
    }
    close FASTA;

    close OUT;
}
