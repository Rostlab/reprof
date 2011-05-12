#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Reprof::Tools::Converter qw(convert_id);

my $big = '/var/tmp/rost_db/data/big/big_80';
my $fasta_glob = '/mnt/project/reprof/data/fasta/tmp/fasta*';
my $pssm_dir = '/mnt/project/reprof/data/pssm/';

my $qsub_file_head =    "#!/bin/sh\n".
                        "export PERL5LIB=/mnt/project/reprof/lib/perl\n".
                        "/mnt/project/rost_db/src/spreadBig_80.pl\n";

GetOptions( "f|fasta=s"   => \$fasta_glob,
            "b|big=s"     => \$big,
            "p|pssm=s"    => \$pssm_dir );

my $bin = "blastpgp -F F -j 3 -e 1 -h 1e-3 -d $big";
my $base = "/mnt/project/reprof/";

my @fastafiles = glob "$fasta_glob";

foreach my $fastafile (@fastafiles) {

    open FH, $fastafile or die "Could not open $fastafile ...\n";
    my $header = <FH>;
    my $id = convert_id($header, 'pdbchain');
    close FH;

    my $pssmfile = "$pssm_dir/$id.pssm";
    my $tmpfile = "/tmp/j$id.sh";
    $tmpfile =~ s/:/_/g;

    # check if pssm file exists or if it is empty
    if (-e $pssmfile) {
        open FH, $pssmfile;
        my $cont = <FH>;
        $cont = <FH>;
        close FH;

        next if length $cont > 1;
    }

    my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/ -e '.$base.'data/grid/ '.$tmpfile;

    my @cmd = ( $bin,
                "-i", $fastafile,
                "-Q", $pssmfile);

    open FH, '>', $tmpfile or die "Could not open $tmpfile\n";
    say  $qsub_file_head;
    say  (join ' ', @cmd);
    close FH;
    chmod 0777, $tmpfile or die "Could not change file permissions of $tmpfile\n";
    say "$qsub";
    unlink $tmpfile or die "Could not delete $tmpfile\n";
}
