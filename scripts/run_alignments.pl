#!/usr/bin/perl -w
use strict;
use feature qw(say);
use File::Spec;
use Getopt::Long;
use Reprof::Tools::Translator qw(hval id2pdbchain);

my $query_file;
my $targets_dir;
my $result_file;
my $ali_dir;
my $gap_open = 10.0;
my $gap_ext = 0.5;

my $bin = 'water';

GetOptions( "i=s"   => \$query_file,
            "j=s"   => \$targets_dir,
            "open=s"   => \$gap_open,
            "extend=s"   => \$gap_ext,
            "ali=s"   => \$ali_dir,
            "out=s" => \$result_file );

opendir FASTA_J, $targets_dir or die "Could not open $targets_dir\n";
my @target_files = grep !/^\./, (readdir FASTA_J);
close FASTA_J;

my $num_targets = scalar @target_files;
my $count = 0;

say "Computing $num_targets alignments...";

open IN, $query_file or die "Could not open $query_file";
my $query_id = id2pdbchain(<IN>);
close IN;

open OUT, '>', $result_file;
foreach my $tfile (@target_files) {
    say "$count done..." if ++$count % 100 == 0;

    my $target_file = "$targets_dir/$tfile";

    open FH, $target_file or die "Could not open $target_file ...\n";
    my $target_id = id2pdbchain(<FH>);
    close FH;

    my $alifile = "$ali_dir/$query_id.$target_id.align";

    my $cmd = join ' ', (   $bin,
                            "-asequence", $query_file,
                            "-bsequence", $target_file,
                            "-gapopen", $gap_open,
                            "-gapextend", $gap_ext,
                            "-outfile", $alifile,
                            "2> /dev/null");

    my $output = `$cmd`;

    open ALI, $alifile or die "Could not open $alifile\n";
    my $tmpoutput = join ' ', (<ALI>);
    close ALI;

    my ($length) = ($tmpoutput =~ m/# Length:\s+(\d+)/);
    my ($seqid) = ($tmpoutput =~ m/# Identity:\s+(\d+)/);
    my ($seqsim) = ($tmpoutput =~ m/# Similarity:\s+(\d+)/);
    my ($seqgaps) = ($tmpoutput =~ m/# Gaps:\s+(\d+)/);

    my $nlength = $length - $seqgaps;
    my $pid = (100 * $seqid) / $nlength;
    my $hval = hval($nlength, $pid);

    printf OUT "%s %s %d %.3f %.3f\n", $query_id, $target_id, $nlength, $pid, $hval;
}
close OUT;
