#!/usr/bin/perl -w
use lib "/mnt/project/resnap/trunk/training/";
#use Prediction;

use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use Reprof::Parser::redisis;
use Reprof::Parser::bisis;
use Reprof::Parser::bind;
use Reprof::Source::redisis;
use Reprof::Source::bisis;
use Reprof::Source::bind;
use File::Spec;
use Reprof::Measure;

#--------------------------------------------------
# GetOptions(
#     ''    =>  \,
# );
#-------------------------------------------------- 

my $fasta_file = shift;
my $out = shift || "redisis.pdf";
my $threshold = 0.0;

#my $prediction_red = Prediction->new();
#my $prediction_bis = Prediction->new();

my @l_vs_b_red;
my @l_vs_b_bis;

my @l_vs_b_mean_red = (0, 0, 0, 0);
my @l_vs_b_mean_bis = (0, 0, 0, 0);

my @prots_red;

my @measures_red;
my @measures_bis;

my $measure_red = Reprof::Measure->new(2);
my $roc_data_red = [];
my $pr_data_red = [];

my $measure_bis = Reprof::Measure->new(2);
my $roc_data_bis = [];
my $pr_data_bis = [];

my $i = 0;

my %sequences;
open FH, $fasta_file or confess "fh error\n";
while (my $header = <FH>) {
    chomp $header;
    my $id = substr $header, 1;
    my $sequence = <FH>;
    chomp $sequence;
    $sequences{$id} = $sequence;
}
close FH;

my $num_binding_prot = 0;
my $num_non_binding_prot = 0;
my $max_length = 0;
my $max_num_binding = 0;
my $max_num_o_binding = 0;
foreach my $id (keys %sequences) {
    #last if $i++ == 10;
    my $sequence = $sequences{$id};


    # observed data
    my $file_bind = Reprof::Source::bind->reprof($id, $sequence);
    my $parser_bind = Reprof::Parser::bind->new($file_bind);
    my @o_binding = $parser_bind->bind;
    my $length = scalar @o_binding;

    next if ($id eq "3cxe:C");

    # redisis data
    my $file_red = Reprof::Source::redisis->reprof($id, $sequence);
    my $parser_red = Reprof::Parser::redisis->new($file_red);
    my @nn_binding_red = $parser_red->nn_binding;
    my @nn_non_binding_red = $parser_red->nn_non_binding;

    # bisis data
    my $file_bis = Reprof::Source::bisis->reprof($id, $sequence);
    my $parser_bis = Reprof::Parser::bisis->new($file_bis);
    my @nn_binding_bis = $parser_bis->B;
    my @nn_non_binding_bis = $parser_bis->NB;
    
    my $tmp_measure_red = Reprof::Measure->new(2);
    my $tmp_measure_bis = Reprof::Measure->new(2);
    my $num_p_binding_red = 0;
    my $num_p_binding_bis = 0;
    my $num_o_binding = 0;
    foreach my $i (0 .. $length - 1)
    {
        if ($nn_binding_red[$i] - $nn_non_binding_red[$i] > $threshold) {
            $num_p_binding_red++;
        }
        if ($nn_binding_bis[$i] - $nn_non_binding_bis[$i] > $threshold) {
            $num_p_binding_bis++;
        }
        if ($o_binding[$i] == 1) {
            $num_o_binding++;

            $measure_red->add([1, 0], [$nn_binding_red[$i], $nn_non_binding_red[$i]]);
            $measure_bis->add([1, 0], [$nn_binding_bis[$i], $nn_non_binding_bis[$i]]);

            $tmp_measure_red->add([1, 0], [$nn_binding_red[$i], $nn_non_binding_red[$i]]);
            $tmp_measure_bis->add([1, 0], [$nn_binding_bis[$i], $nn_non_binding_bis[$i]]);

            #$prediction_red->add([$nn_binding_red[$i], $nn_non_binding_red[$i]],[1, 0]);
            #$prediction_bis->add([$nn_binding_bis[$i], $nn_non_binding_bis[$i]],[1, 0]);
        }
        else {
            $measure_red->add([0, 1], [$nn_binding_red[$i], $nn_non_binding_red[$i]]);
            $measure_bis->add([0, 1], [$nn_binding_bis[$i], $nn_non_binding_bis[$i]]);

            $tmp_measure_red->add([0, 1], [$nn_binding_red[$i], $nn_non_binding_red[$i]]);
            $tmp_measure_bis->add([0, 1], [$nn_binding_bis[$i], $nn_non_binding_bis[$i]]);

            #$prediction_red->add([$nn_binding_red[$i], $nn_non_binding_red[$i]],[0, 1]);
            #$prediction_bis->add([$nn_binding_bis[$i], $nn_non_binding_bis[$i]],[0, 1]);
        }
        
    }
    push @measures_red, $tmp_measure_red;
    push @measures_bis, $tmp_measure_bis;

    if ($num_p_binding_red > $max_num_binding) {
        $max_num_binding = $num_p_binding_red;
    }
    if ($num_p_binding_bis > $max_num_binding) {
        $max_num_binding = $num_p_binding_bis;
    }
    if ($length > $max_length) {
        $max_length = $length;
    }
    if ($num_o_binding > $max_num_o_binding) {
        $max_num_o_binding = $num_o_binding;
    }
    
    if ($num_o_binding > 0) {
        push @l_vs_b_red, [$length, $num_p_binding_red, $num_o_binding, "\"forestgreen\"",  "\"$id\""];
        push @l_vs_b_bis, [$length, $num_p_binding_bis, $num_o_binding, "\"forestgreen\"",  "\"$id\""];

        $l_vs_b_mean_red[0] += $num_p_binding_red;
        $l_vs_b_mean_red[1] += $length;

        $l_vs_b_mean_bis[0] += $num_p_binding_bis;
        $l_vs_b_mean_bis[1] += $length;

        $num_binding_prot++;
    }
    else {
        push @l_vs_b_red, [$length, $num_p_binding_red, $num_o_binding, "\"red\"", "\"$id\""];
        push @l_vs_b_bis, [$length, $num_p_binding_bis, $num_o_binding, "\"red\"", "\"$id\""];

        $l_vs_b_mean_red[2] += $num_p_binding_red;
        $l_vs_b_mean_red[3] += $length;

        $l_vs_b_mean_bis[2] += $num_p_binding_bis;
        $l_vs_b_mean_bis[3] += $length;

        $num_non_binding_prot++;
    }

}

if ($num_binding_prot > 0) {
    $l_vs_b_mean_red[0] /= $num_binding_prot;
    $l_vs_b_mean_red[1] /= $num_binding_prot;
    $l_vs_b_mean_bis[0] /= $num_binding_prot;
    $l_vs_b_mean_bis[1] /= $num_binding_prot;
}

if ($num_non_binding_prot > 0) {
    $l_vs_b_mean_red[2] /= $num_non_binding_prot;
    $l_vs_b_mean_red[3] /= $num_non_binding_prot;
    $l_vs_b_mean_bis[2] /= $num_non_binding_prot;
    $l_vs_b_mean_bis[3] /= $num_non_binding_prot;
}

# y/x
my $l_vs_b_slope_red = (($l_vs_b_mean_red[1] + $l_vs_b_mean_red[3]) / 2) / (($l_vs_b_mean_red[0] + $l_vs_b_mean_red[2]) / 2);
my $l_vs_b_slope_bis = (($l_vs_b_mean_bis[1] + $l_vs_b_mean_bis[3]) / 2) / (($l_vs_b_mean_bis[0] + $l_vs_b_mean_bis[2]) / 2);

say $l_vs_b_slope_red;
say $l_vs_b_slope_bis;

my @aucs_red = $measure_red->aucs($roc_data_red);
my @pr_aucs_red = $measure_red->pr_aucs($pr_data_red);

my @aucs_bis = $measure_bis->aucs($roc_data_bis);
my @pr_aucs_bis = $measure_bis->pr_aucs($pr_data_bis);

sub write_data_file {
    my ($data_file, $data, @header) = @_;

    open FH, "> $data_file" or croak "fh error\n";
    say FH join "\t", @header;
    foreach my $p (@$data) {
        say FH join "\t", @$p;
    }
    close FH;
}

# print confusion tables
sub print_confusion {
    my $matrix = shift;

    foreach my $row (@$matrix) {
        say join "\t", @$row;
    }
}

my $confusion_red = $measure_red->confusion;
my $confusion_bis = $measure_bis->confusion;
say "confusion red";
print_confusion($confusion_red);
say "";
say "confusion bis";
print_confusion($confusion_bis);

# start plot
my $pid = $$;
say "pid: $pid";
my $data_tmp = "/tmp/plot_$pid";

my $script_file = "/tmp/plot_$pid.Rscript";
open SCRIPT, "> $script_file" or confess "fh error\n";
say SCRIPT "pdf(\"$out\")";

#
my @measure_data;
push @measure_data, [$measure_red->Qn, $measure_red->aucs, $measure_red->pr_aucs, $measure_red->precisions, $measure_red->recalls, $measure_red->fmeasures, $measure_red->mccs];
push @measure_data, [$measure_bis->Qn, $measure_bis->aucs, $measure_bis->pr_aucs, $measure_bis->precisions, $measure_bis->recalls, $measure_bis->fmeasures, $measure_bis->mccs];
my $measure_file = "$data_tmp.measures";
write_data_file($measure_file, \@measure_data, qw(q2 rocb rocnb prb prnb pb pnb rb rnb fb fnb mccb mccnb));
say SCRIPT "measure <- read.table(\"$measure_file\", header=T, sep=\"\\t\")";
say SCRIPT 'barplot(as.matrix(measure), beside=TRUE, cex.names=0.7, main="Different Measures", legend.text=c("redisis", "bisis"))';

#
my $l_vs_b_red_file = "$data_tmp.l_vs_b_red";
write_data_file($l_vs_b_red_file, \@l_vs_b_red, "length", "num_p_binding_red", "num_o_binding", "color", "id");
say SCRIPT "l_vs_b_red <- read.table(\"$l_vs_b_red_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(l_vs_b_red$num_p_binding_red, l_vs_b_red$length, pch=20, col=l_vs_b_red$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain (redisis)", xlim=c(0,'.$max_num_binding.'), ylim=c(0,'.$max_length.'))';
say SCRIPT "abline(a=0, b=$l_vs_b_slope_red)";

#
#my $pred_red_file = "$data_tmp.pred_red";
#my $pred_red = [];
#my $prediction_red_tmp = [];
#$prediction_red->best_threshold(-1, 1, 0.01, $prediction_red_tmp);
#foreach my $row (0 .. scalar @$prediction_red_tmp - 1) {
#foreach my $col (0 .. scalar @{$prediction_red_tmp->[$row]} - 1) {
#$pred_red->[$col][$row] = $prediction_red_tmp->[$row][$col];
#}
#}
#write_data_file($pred_red_file, $pred_red, "x", "a", "b", "c", "d", "e");
#say SCRIPT "pred_red <- read.table(\"$pred_red_file\", header=T, sep=\"\\t\")";
#say SCRIPT 'plot(pred_red$x, type="l", pred_red$a, pch=20, xlim=c(-1,1), ylim=c(0,1), col="red")';
#say SCRIPT 'lines(pred_red$x, pred_red$b, pch=20, col="green")';
#say SCRIPT 'lines(pred_red$x, pred_red$c, pch=20, col="blue")';
#say SCRIPT 'lines(pred_red$x, pred_red$d, pch=20, col="black")';
##say SCRIPT 'lines(pred_red$x, pred_red$e, pch=20, col="magenta")';


#
#my $pred_bis_file = "$data_tmp.pred_bis";
#my $pred_bis = [];
#my $prediction_bis_tmp = [];
#$prediction_bis->best_threshold(-1, 1, 0.01, $prediction_bis_tmp);
#foreach my $row (0 .. scalar @$prediction_bis_tmp - 1) {
#foreach my $col (0 .. scalar @{$prediction_bis_tmp->[$row]} - 1) {
#$pred_bis->[$col][$row] = $prediction_bis_tmp->[$row][$col];
#}
#}
#write_data_file($pred_bis_file, $pred_bis, "x", "a", "b", "c", "d", "e");
#say SCRIPT "pred_bis <- read.table(\"$pred_bis_file\", header=T, sep=\"\\t\")";
#say SCRIPT 'plot(pred_bis$x, type="l", pred_bis$a, pch=20, xlim=c(-1,1), ylim=c(0,1), col="red")';
#say SCRIPT 'lines(pred_bis$x, pred_bis$b, pch=20, col="green")';
#say SCRIPT 'lines(pred_bis$x, pred_bis$c, pch=20, col="blue")';
#say SCRIPT 'lines(pred_bis$x, pred_bis$d, pch=20, col="black")';
#say SCRIPT 'lines(pred_bis$x, pred_bis$e, pch=20, col="magenta")';

#
my $l_vs_b_bis_file = "$data_tmp.l_vs_b_bis";
write_data_file($l_vs_b_bis_file, \@l_vs_b_bis, "length", "num_p_binding_bis", "num_o_binding", "color", "id");
say SCRIPT "l_vs_b_bis <- read.table(\"$l_vs_b_bis_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(l_vs_b_bis$num_p_binding_bis, l_vs_b_bis$length, pch=20, col=l_vs_b_bis$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain (bisis)", xlim=c(0,'.$max_num_binding.'), ylim=c(0,'.$max_length.'))';
say SCRIPT "abline(a=0, b=$l_vs_b_slope_bis)";

#
say SCRIPT 'plot(l_vs_b_red$num_p_binding_red, l_vs_b_red$length, pch=20, col=l_vs_b_red$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain (redisis)", xlim=c(0,'.$max_num_binding.'), ylim=c(0,'.$max_length.'))';
say SCRIPT 'text(l_vs_b_red$num_p_binding_red, y=l_vs_b_red$length, labels=l_vs_b_red$id, pos=4, offset=0.2, cex=0.5)';
say SCRIPT "abline(a=0, b=$l_vs_b_slope_red)";

say SCRIPT 'plot(l_vs_b_bis$num_p_binding_bis, l_vs_b_bis$length, pch=20, col=l_vs_b_bis$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain (bisis)", xlim=c(0,'.$max_num_binding.'), ylim=c(0,'.$max_length.'))';
say SCRIPT 'text(l_vs_b_bis$num_p_binding_bis, y=l_vs_b_bis$length, labels=l_vs_b_bis$id, pos=4, offset=0.2, cex=0.5)';
say SCRIPT "abline(a=0, b=$l_vs_b_slope_bis)";

#
say SCRIPT 'plot(l_vs_b_red$num_p_binding_red, l_vs_b_red$num_o_binding, pch=20, xlab="|Residues predicted as binding|", ylab="|Residues observed as binding|", main="Predicted/Observed binding residues per chain (redisis)", xlim=c(0,'.$max_num_binding.'), ylim=c(0,'.$max_num_o_binding.'))';
say SCRIPT 'abline(a=0, b=1)';

say SCRIPT 'plot(l_vs_b_bis$num_p_binding_bis, l_vs_b_bis$num_o_binding, pch=20, xlab="|Residues pbisicted as binding|", ylab="|Residues observed as binding|", main="Predicted/Observed binding residues per chain (bisis)", xlim=c(0,'.$max_num_binding.'), ylim=c(0,'.$max_num_o_binding.'))';
say SCRIPT 'abline(a=0, b=1)';

#
my $roc_0_red_file = "$data_tmp.roc_0_red";
my $roc_0_bis_file = "$data_tmp.roc_0_bis";
write_data_file($roc_0_red_file, $roc_data_red->[0], "fpr", "tpr", "threshold");
write_data_file($roc_0_bis_file, $roc_data_bis->[0], "fpr", "tpr", "threshold");
say SCRIPT "roc_0_bis <- read.table(\"$roc_0_bis_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(roc_0_red$fpr, roc_0_red$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC binding", col="red")';
say SCRIPT "roc_0_red <- read.table(\"$roc_0_red_file\", header=T, sep=\"\\t\")";
say SCRIPT 'lines(roc_0_bis$fpr, roc_0_bis$tpr, type="l")';

#
my $roc_1_red_file = "$data_tmp.roc_1_red";
my $roc_1_bis_file = "$data_tmp.roc_1_bis";
write_data_file($roc_1_red_file, $roc_data_red->[1], "fpr", "tpr", "threshold");
write_data_file($roc_1_bis_file, $roc_data_bis->[1], "fpr", "tpr", "threshold");
say SCRIPT "roc_1_red <- read.table(\"$roc_1_red_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(roc_1_red$fpr, roc_1_red$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC non binding", col="red")';
say SCRIPT "roc_1_bis <- read.table(\"$roc_1_bis_file\", header=T, sep=\"\\t\")";
say SCRIPT 'lines(roc_1_bis$fpr, roc_1_bis$tpr, type="l")';

#
my $pr_0_red_file = "$data_tmp.pr_0_red";
my $pr_0_bis_file = "$data_tmp.pr_0_bis";
write_data_file($pr_0_red_file, $pr_data_red->[0], "recall", "precision", "threshold");
write_data_file($pr_0_bis_file, $pr_data_bis->[0], "recall", "precision", "threshold");
say SCRIPT "pr_0_red <- read.table(\"$pr_0_red_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(pr_0_red$recall, pr_0_red$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision binding", col="red")';
say SCRIPT "pr_0_bis <- read.table(\"$pr_0_bis_file\", header=T, sep=\"\\t\")";
say SCRIPT 'lines(pr_0_bis$recall, pr_0_bis$precision, type="l")';

#
my $pr_1_red_file = "$data_tmp.pr_1_red";
my $pr_1_bis_file = "$data_tmp.pr_1_bis";
write_data_file($pr_1_red_file, $pr_data_red->[1], "recall", "precision", "threshold");
write_data_file($pr_1_bis_file, $pr_data_bis->[1], "recall", "precision", "threshold");
say SCRIPT "pr_1_red <- read.table(\"$pr_1_red_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(pr_1_red$recall, pr_1_red$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision non binding", col="red")';
say SCRIPT "pr_1_bis <- read.table(\"$pr_1_bis_file\", header=T, sep=\"\\t\")";
say SCRIPT 'lines(pr_1_bis$recall, pr_1_bis$precision, type="l")';

# end
say SCRIPT "dev.off()";
close SCRIPT;
say `Rscript $script_file`;

say "REDISIS ROC AUCS: ".(join " ", @aucs_red);
say "REDISIS PR AUCS: ".(join " ", @pr_aucs_red);
say "BISIS ROC AUCS: ".(join " ", @aucs_bis);
say "BISIS PR AUCS: ".(join " ", @pr_aucs_bis);
