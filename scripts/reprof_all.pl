#!/usr/bin/perl -w
use strict;
use Carp;
use Getopt::Long;
use Perlpred::Parser::fasta_multi;
use Perlpred::Source::blastPsiMat;

my $out_dir = "/mnt/project/reprof/data/reprof/";
my $net_prefix = "/mnt/project/reprof/runs/test/";

my $params = [
    [
        "/mnt/project/reprof//data/fasta_multi/train/train_1.fasta", "a/309", "u/345", "b/374", "uu/480", "ub/423", "bu/413", "bb/449",
    ],
    [
        "/mnt/project/reprof//data/fasta_multi/train/train_2.fasta", "a/564", "u/615", "b/644", "uu/680", "ub/629", "bu/694", "bb/642",
    ],
    [
        "/mnt/project/reprof//data/fasta_multi/train/train_3.fasta", "a/85", "u/105", "b/119", "uu/192", "ub/178", "bu/191", "bb/167",
    ],
];

foreach my $param (@$params) {
    my ($fasta, $a, $u, $b, $uu, $ub, $bu, $bb) = @$param;

    my $fasta_multi_parser = Perlpred::Parser::fasta_multi->new($fasta);
    
    while ($fasta_multi_parser->next) {
        my ($id, $seq) = $fasta_multi_parser->get_entry;
        print $id, "\n";

        my $blastPsiMat_file = Perlpred::Source::blastPsiMat->predictprotein($id, $seq);
        my $out_file = "$out_dir/$id.reprof";

        my @cmd = ("/mnt/project/reprof/scripts/reprof.pl -blastPsiMat $blastPsiMat_file -out $out_file");
        push @cmd, "--spec a_model=$net_prefix/$a/nntrain.model --spec a_features=$net_prefix/$a/train.setconvert";
        push @cmd, "--spec u_model=$net_prefix/$u/nntrain.model --spec u_features=$net_prefix/$u/train.setconvert";
        push @cmd, "--spec b_model=$net_prefix/$b/nntrain.model --spec b_features=$net_prefix/$b/train.setconvert";
        push @cmd, "--spec uu_model=$net_prefix/$uu/nntrain.model --spec uu_features=$net_prefix/$uu/train.setconvert";
        push @cmd, "--spec ub_model=$net_prefix/$ub/nntrain.model --spec ub_features=$net_prefix/$ub/train.setconvert";
        push @cmd, "--spec bu_model=$net_prefix/$bu/nntrain.model --spec bu_features=$net_prefix/$bu/train.setconvert";
        push @cmd, "--spec bb_model=$net_prefix/$bb/nntrain.model --spec bb_features=$net_prefix/$bb/train.setconvert";
        
        my $cmd_string = join " ", @cmd;
        print `$cmd_string`, "\n";
    }
}




      



      



      



      



      



