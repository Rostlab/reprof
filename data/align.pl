#!/usr/bin/perl -w
use strict;
use feature qw(say);
use File::Spec;
use Getopt::Long;
use Prot::Tools::Translator qw(hval id2pdbchain);

my $file_i;
my $fastadir_j;
my $outfile;
my $gap_open = 3.0;
my $gap_ext = 0.3;

my $tmpfile = '/tmp/needle'.(rand 1000000000000).'.out';
while (-e $tmpfile) {
    $tmpfile = '/tmp/needle'.(rand 1000000000000).'.out';
}
my $bin = 'water';

GetOptions( "i=s"   => \$file_i,
            "j=s"   => \$fastadir_j,
            "open=s"   => \$gap_open,
            "extend=s"   => \$gap_ext,
            "out=s" => \$outfile );

opendir FASTA_J, $fastadir_j;
my @fastafiles_j = grep !/^\./, (readdir FASTA_J);
close FASTA_J;

my $num_j = scalar @fastafiles_j;
my $count = 0;

say "Computing $num_j alignments...";

open IN, $file_i;
my $id1 = id2pdbchain(<IN>);
close IN;

open OUT, '>', $outfile;
foreach my $j (@fastafiles_j) {
    say "$count done..." if ++$count % 100 == 0;

    my $file_j = File::Spec->catfile($fastadir_j, $j);

    my $cmd = join ' ', (   $bin,
                            "-asequence", $file_i,
                            "-bsequence", $file_j,
                            "-gapopen", $gap_open,
                            "-gapextend", $gap_ext,
                            "-outfile", $tmpfile,
                            "2> /dev/null" );

    my $output = `$cmd`;

    open IN, $file_j;
    my $id2 = id2pdbchain(<IN>);
    close IN;

    open IN, $tmpfile;
    my $tmpoutput = join '', (<IN>);
    close IN;

    my ($length) = ($tmpoutput =~ m/# Length:\s+(\d+)/);
    my ($seqid) = ($tmpoutput =~ m/# Identity:\s+(\d+)/);
    my ($seqsim) = ($tmpoutput =~ m/# Similarity:\s+(\d+)/);
    my ($seqgaps) = ($tmpoutput =~ m/# Gaps:\s+(\d+)/);

    my $nlength = $length - $seqgaps;
    my $pid = (100 * $seqid) / $nlength;
    my $hval = hval($nlength, $pid);

#--------------------------------------------------
#     say "$tmpoutput\n\nlength: $length, seqid: $seqid, seqsim: $seqsim, seqgaps: $seqgaps, nlength: $nlength, pid: $pid, hval: $hval" if $length >= 100;
#-------------------------------------------------- 
    printf OUT "%s %s %d %.3f %.3f\n", $id1, $id2, $nlength, $pid, $hval;

    unlink $tmpfile;
}
close OUT;
