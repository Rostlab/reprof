#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Reprof::Parser::Dssp;
use Reprof::Tools::Converter qw(convert_id);
use Getopt::Long;

my $minlength = 60;
my $dssp_glob;
my $fasta_file;
my $list_file;

GetOptions( 
    "d|dssp=s"      => \$dssp_glob,
    "m|minlength=i" => \$minlength,
    "f|fasta=s"     => \$fasta_file,
    "l|list=s"     => \$list_file
);

my @dssp_files = glob $dssp_glob;

my %seqs;
my %allowed;

open LIST, $list_file or die "Could not open $list_file\n";
while (my $line = <LIST>) {
    chomp $line;
    my @split = split /\s+/, $line;
    if ($split[1] eq "prot" && $split[2] eq "diffraction") {
        $allowed{$split[0]} = 1;
    }
}

foreach my $file (@dssp_files) {

    my $id = convert_id($file, 'pdb');

    say "Parsing $file";
    unless ($allowed{$id}) {
        say "Skipping $id";
        next;
    }

    my $parser = Reprof::Parser::Dssp->new($file);

    foreach my $chain (@{$parser->get_chains}) {
        my $seq = join '', @{$parser->get_res($chain)};
        if (length $seq >= $minlength) {
            $seqs{$seq} = "$id:$chain";
        }
    }
}

say "Found ".(scalar keys %seqs)." seqs".

open FASTA, '>', $fasta_file;
while (my ($seq, $id) = each %seqs) {
    printf  FASTA ">%s\n%s\n", $id, $seq;
}
close FASTA;
