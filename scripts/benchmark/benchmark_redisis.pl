#!/usr/bin/perl -w
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
my $threshold = 0.0;

my @l_vs_b_red;
my @l_vs_b_bis;

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
        }
        else {
            $measure_red->add([0, 1], [$nn_binding_red[$i], $nn_non_binding_red[$i]]);
            $measure_bis->add([0, 1], [$nn_binding_bis[$i], $nn_non_binding_bis[$i]]);
        }
        
    }
    
    if ($num_o_binding > 0) {
        push @l_vs_b_red, [$length, $num_p_binding_red, $num_o_binding, "\"forestgreen\"",  $id];
        push @l_vs_b_bis, [$length, $num_p_binding_bis, $num_o_binding, "\"forestgreen\"",  $id];
    }
    else {
        push @l_vs_b_red, [$length, $num_p_binding_red, $num_o_binding, "\"red\"", $id];
        push @l_vs_b_bis, [$length, $num_p_binding_bis, $num_o_binding, "\"red\"", $id];
    }
}

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

plot(data$num_p_binding_red, data$length, pch=20, col=data$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain (redisis)")
plot("l_vs_b_red.png", (join "\t", "length", "num_p_binding_red", "num_o_binding", "color", "file"), \@l_vs_b_red, $s);

plot(data$fpr, data$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC (redisis)")
plot("roc_0_red.png", (join "\t", "tpr", "fpr"), $roc_data_red->[0], $s);
plot(data$fpr, data$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC (redisis)")
plot("roc_1_red.png", (join "\t", "tpr", "fpr"), $roc_data_red->[1], $s);

plot(data$recall, data$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision (redisis)")
plot("pr_0_red.png", (join "\t", "precision", "recall"), $pr_data_red->[0], $s);
plot(data$recall, data$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision (redisis)")
plot("pr_1_red.png", (join "\t", "precision", "recall"), $pr_data_red->[1], $s);


#--------------------------------------------------
# $s = '
# plot(data$num_p_binding_bis, data$length, pch=20, col=data$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain (bisis)")
# ';
# plot("l_vs_b_bis.png", (join "\t", "length", "num_p_binding_bis", "num_o_binding", "color", "file"), \@l_vs_b_bis, $s);
# 
# $s = '
# plot(data$fpr, data$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC (bisis)")
# ';
# plot("roc_0_bis.png", (join "\t", "tpr", "fpr"), $roc_data_bis->[0], $s);
# $s = '
# plot(data$fpr, data$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC (bisis)")
# ';
# plot("roc_1_bis.png", (join "\t", "tpr", "fpr"), $roc_data_bis->[1], $s);
# 
# $s = '
# plot(data$recall, data$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision (bisis)")
# ';
# plot("pr_0_bis.png", (join "\t", "precision", "recall"), $pr_data_bis->[0], $s);
# $s = '
# plot(data$recall, data$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision (bisis)")
# ';
# plot("pr_1_bis.png", (join "\t", "precision", "recall"), $pr_data_bis->[1], $s);
#-------------------------------------------------- 

say "REDISIS ROC AUCS: ".(join " ", @aucs_red);
say "REDISIS PR AUCS: ".(join " ", @pr_aucs_red);
say "BISIS ROC AUCS: ".(join " ", @aucs_bis);
say "BISIS PR AUCS: ".(join " ", @pr_aucs_bis);
