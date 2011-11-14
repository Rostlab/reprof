#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use File::Spec;
use Getopt::Long;

my $out;

GetOptions(
    'out=s'    =>  \$out,
);

my @files = @ARGV;

foreach my $file (@files) {
    my $file_abs = File::Spec->rel2abs($file);
    my ($d, $path, $file) = File::Spec->splitpath($file_abs);

    my $file_base = $file;
    $file_base =~ s/\.fasta$//;

    my $out_file = "$out/$file_base.blastPsiMat";

    open FH, "> job.sh" or croak "File error\n";
    say FH join "\n", 
        "#!/bin/sh",
        "/mnt/project/rost_db/src/fetchNr20_hhblits",
        "/mnt/project/rost_db/src/fetchUniprot20_hhblits",
        "time perl /opt/hhblits/hhblits/hhblits_pssm.pl -i $file_abs -o $out_file -h /var/tmp/opt/hhblits/hhblits/databases/nr20/nr20_current";
    close FH;
    say `qsub job.sh`;
}
unlink "job.sh";
