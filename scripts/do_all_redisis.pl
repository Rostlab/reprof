#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;

my $bin = "/mnt/project/reprof/scripts/redisis.pl";
my $out_dir = "/mnt/project/reprof/data/redisis_l1/";
my $fasta_base = "/mnt/project/reprof/data/fasta_multi/dna/";
my $net_base = "/mnt/project/reprof/runs/dna/";
my $params = [ # fastadir, prenet_dir, net_dir
    ["all10/10", "ppall10/223",  "ppall10filter/200"],
    [ "all10/1", "ppall10/446",  "ppall10filter/439"],
    [ "all10/2", "ppall10/639",  "ppall10filter/647"],
    [ "all10/3", "ppall10/686",  "ppall10filter/859"],
    [ "all10/4", "ppall10/1103", "ppall10filter/1101"],
    [ "all10/5", "ppall10/1121", "ppall10filter/1336"],
    [ "all10/6", "ppall10/1510", "ppall10filter/1528"],
    [ "all10/7", "ppall10/1570", "ppall10filter/1715"],
    [ "all10/8", "ppall10/2002", "ppall10filter/2009"],
    [ "all10/9", "ppall10/2194", "ppall10filter/2040"],
];

foreach my $i (@$params) {
    my ($fasta_dir_suffix, $prenet_dir_suffix, $net_dir_suffix) = @$i;

    my $fasta_dir = "$fasta_base/$fasta_dir_suffix";
    my $prenet_dir = "$net_base/$prenet_dir_suffix";
    my $net_dir = "$net_base/$net_dir_suffix";

    my @fasta_files = glob "$fasta_dir/*.fasta";
    foreach my $fasta_file (@fasta_files) {
        say "predicting $fasta_file";
        say `$bin -f $fasta_file -l1n $prenet_dir/nntrain.model -l1f $prenet_dir/test.setconvert -l2n $net_dir/nntrain.model -l2f $net_dir/test.setconvert -o $out_dir`;
    }
}
