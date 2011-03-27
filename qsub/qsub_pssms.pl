#!/usr/bin/perl -w
use strict;
use feature qw(say);
use File::Spec;
use Getopt::Long;
use Prot::Tools::Translator qw(id2pdbchain);

my $fastadir;
my $pssmdir;
my $db = '/var/tmp/rost_db/data/big/big_80';

my $bin = "blastpgp -F F -j 3 -e 1 -h 1e-3 -d $db";

my $base = "/mnt/project/reprof/";

my $qsub_file_head =    "#!/bin/sh\n".
                        "export PERL5LIB=/mnt/project/reprof/perl/lib/perl/5.10.1\n".
                        "/mnt/project/rost_db/src/spreadBig_80.pl\n";

GetOptions( "fasta=s"   => \$fastadir,
            "db=s"      => \$db,
            "pssm=s"    => \$pssmdir );

opendir FASTA, $fastadir or die "Could not open dir $fastadir ...\n";
my @fastafiles = grep !/^\./, (readdir FASTA);
close FASTA;

foreach my $fasta (@fastafiles) {
    my $fastafile = File::Spec->catfile($fastadir, $fasta);

    open FH, $fastafile or die "Could not open $fastafile ...\n";
    my $header = <FH>;
    my $id = id2pdbchain($header);
    close FH;

    my $pssmfile = File::Spec->catfile($pssmdir, "$id.pssm");
    my $tmpfile = File::Spec->catfile("/tmp/", "j$id.sh");
    $tmpfile =~ s/:/_/g;

    my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/ -e '.$base.'data/grid/ '.$tmpfile;

    my @cmd = ( $bin,
                "-i", $fastafile,
                "-Q", $pssmfile);

    open FH, '>', $tmpfile or die "Could not open $tmpfile\n";
    say FH $qsub_file_head;
    say FH (join ' ', @cmd);
    close FH;
    chmod 0777, $tmpfile or die "Could not change file permissions of $tmpfile\n";
    say `$qsub`;
    unlink $tmpfile or die "Could not delete $tmpfile\n";
}
