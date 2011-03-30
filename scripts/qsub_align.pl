#!/usr/bin/perl -w
use strict;
use feature qw(say);
use File::Spec;
use Getopt::Long;
use Reprof::Tools::Translator qw(id2pdbchain);

my $queries_dir = "/mnt/project/reprof/data/fasta/split/";
my $targets_dir = "/mnt/project/reprof/data/fasta/split/";
my $outdir = "/mnt/project/reprof/data/align/";

my $base = "/mnt/project/reprof/";
my $bin = "/mnt/project/reprof/scripts/run_alignments.pl";


opendir FASTA, $queries_dir or die "Could not open dir $queries_dir ...\n";
my @queries_files = grep !/^\./, (readdir FASTA);
close FASTA;

my $count = 0;
foreach my $query_file (@queries_files) {
    my $queries_tmpdir = "/tmp/reprof/align_$count/q/";
    my $targets_tmpdir = "/tmp/reprof/align_$count/t/";
    my $aligns_tmpdir = "/tmp/reprof/align_$count/a/";
    

    my $fastafile = "$queries_dir/$query_file";
    my $tmpquery_file = "$queries_tmpdir/$query_file";

    open FH, $fastafile or die "Could not open $fastafile ...\n";
    my $header = <FH>;
    my $query_id = id2pdbchain($header);
    close FH;

    my $outfile = "$outdir/$query_id.alignresult";
    my $jobtmp = "/tmp/j$query_id.sh";
    $jobtmp =~ s/:/_/g;

    my $qsub = 'qsub -M hoenigschmid@rostlab.org -o '.$base.'data/grid/align/ -e '.$base.'data/grid/align/ '.$jobtmp;

    my @cmd = ( $bin,
                "-i", $tmpquery_file,
                "-j", $targets_tmpdir,
                "-ali", $aligns_tmpdir,
                "-out", $outfile);

    my $qsub_file_head =    "#!/bin/sh\n".
                            "export PERL5LIB=/mnt/project/reprof/perl/lib/perl/5.10.1\n".
                            "mkdir -p $queries_tmpdir\n".
                            "mkdir -p $targets_tmpdir\n".
                            "mkdir -p $aligns_tmpdir\n".
                            "cp -u $queries_dir/* $queries_tmpdir\n".
                            "cp -u $targets_dir/* $targets_tmpdir";

    my $qsub_file_tail =    "cat $aligns_tmpdir/* > $outdir/$query_id.align\n".
                            "rm -rf $queries_tmpdir $targets_tmpdir $aligns_tmpdir";

    open FH, '>', $jobtmp or die "Could not open $jobtmp\n";
    say FH $qsub_file_head;
    say FH (join ' ', @cmd);
    say FH $qsub_file_tail;
    close FH;
    chmod 0777, $jobtmp or die "Could not change file permissions of $jobtmp\n";
    say `$qsub`;
    unlink $jobtmp or die "Could not delete $jobtmp\n";
    $count++;
}
