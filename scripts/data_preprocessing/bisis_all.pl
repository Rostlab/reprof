#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use File::Spec;

my $dir = shift;

my $out_dir = "/mnt/project/reprof/data/bisis/";

foreach my $fasta_file (glob "$dir/*.fasta") {
    my $fasta_file_abs = File::Spec->rel2abs($fasta_file);
    my ($v, $d, $out_file) = File::Spec->splitpath($fasta_file_abs);
    $out_file =~ s/\.fasta$//;
    
    open FH, "> job.sh" or croak "File error\n";
    say FH join "\n", 
        "#!/bin/sh",
        "perl /mnt/project/bisis/runBISIS.pl $fasta_file_abs $out_dir/$out_file";
    close FH;
    say `qsub job.sh`;
}
