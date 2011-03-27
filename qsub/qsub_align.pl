#!/usr/bin/perl -w
use strict;
use feature qw(say);
use File::Spec;
use Getopt::Long;
use Prot::Tools::Translator qw(id2pdbchain);

my $dir1 = "/mnt/project/reprof/data/fasta/pdb_nmr_min60_hval5/";
my $dir2 = "/mnt/project/reprof/data/fasta/pdb_diffraction_max2A_min60_hval5/";
my $outdir = "/mnt/project/reprof/data/align/";
my $tmpdir1 = '/tmp/reprof_q';
my $tmpdir2 = '/tmp/reprof_t';

my $base = "/mnt/project/reprof/";
my $bin = "/mnt/project/reprof/scripts/data/align.pl";

my $qsub_file_head =    "#!/bin/sh\n".
                        "export PERL5LIB=/mnt/project/reprof/perl/lib/perl/5.10.1\n".
                        "mkdir -p $tmpdir1\n".
                        "mkdir -p $tmpdir2\n".
                        "cp -u $dir1/* $tmpdir1\n".
                        "cp -u $dir2/* $tmpdir2\n";

GetOptions( "dir1=s"    => \$dir1,
            "dir2=s"    => \$dir2,
            "out=s"     => \$outdir );

opendir FASTA, $dir1 or die "Could not open dir $dir1 ...\n";
my @dir1files = grep !/^\./, (readdir FASTA);
close FASTA;

foreach my $file1 (@dir1files) {
    my $fastafile = File::Spec->catfile($dir1, $file1);
    my $tmpfile1 = File::Spec->catfile($tmpdir1, $file1);

    open FH, $fastafile or die "Could not open $fastafile ...\n";
    my $header = <FH>;
    my $id = id2pdbchain($header);
    close FH;

    my $outfile = File::Spec->catfile($outdir, "$id.align");
    my $tmpfile = File::Spec->catfile("/tmp/", "j$id.sh");
    $tmpfile =~ s/:/_/g;

    my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/ -e '.$base.'data/grid/ '.$tmpfile;

    my @cmd = ( $bin,
                "-i", $tmpfile1,
                "-j", $tmpdir2,
                "-out", $outfile);

    open FH, '>', $tmpfile or die "Could not open $tmpfile\n";
    say FH $qsub_file_head;
    say FH (join ' ', @cmd);
    close FH;
    chmod 0777, $tmpfile or die "Could not change file permissions of $tmpfile\n";
    say `$qsub`;
    unlink $tmpfile or die "Could not delete $tmpfile\n";
}
