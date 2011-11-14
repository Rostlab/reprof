#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use Reprof::Parser::redisis;
use Reprof::Parser::bisis;
use Reprof::Source::bisis;
use File::Spec;
use Reprof::Measure;

#--------------------------------------------------
# GetOptions(
#     ''    =>  \,
# );
#-------------------------------------------------- 

my @files = @ARGV;

my @l_vs_b;
my @l_vs_b_nonbinding;

my $measure = Reprof::Measure->new(2);
my $roc_data = [];
my $pr_data = [];

my $i = 0;
foreach my $file (@files) {
    #last if $i++ == 10;

    my ($v, $d, $id) = File::Spec->splitdir($file);
    $id =~ s/\.redisis$//;

    my $parser = Reprof::Parser::redisis->new($file);
    my @p_binding = $parser->p_binding;
    my @o_binding = $parser->o_binding;

    #my $is_binding = 0;
    #foreach my $b (@o_binding) {
    #if ($b == 1) {
    #$is_binding = 1;
    #}
    #}
    #if (! $is_binding) {
    #next;
    #}

    my $bisis_file = Reprof::Source::bisis->reprof($id);
    my $bisis_parser = Reprof::Parser::bisis->new($bisis_file);

    my @nn_binding = $parser->nn_binding;
    my @nn_non_binding = $parser->nn_non_binding;

    my $length = scalar @p_binding;
    
    my $num_p_binding = 0;
    my $num_o_binding = 0;
    foreach my $i (0 .. $length - 1)
    {
        if ($p_binding[$i] == 1) {
            $num_p_binding++;
        }
        if ($o_binding[$i] == 1) {
            $num_o_binding++;

            $measure->add([1, 0], [$nn_binding[$i], $nn_non_binding[$i]]);
        }
        else {
            $measure->add([0, 1], [$nn_binding[$i], $nn_non_binding[$i]]);
        }
        
    }
    
    if ($num_o_binding > 0) {
        push @l_vs_b, [$length, $num_p_binding, $num_o_binding, "\"green\"",  $id];
    }
    else {
        push @l_vs_b, [$length, $num_p_binding, $num_o_binding, "\"red\"", $id];
    }
}

my @aucs = $measure->aucs($roc_data);
my @pr_aucs = $measure->pr_aucs($pr_data);

sub plot {
    my ($name, $header, $data, $script) = @_;

    my $pid = $$;
    my $data_file = "/tmp/$pid.data";
    my $script_file = "/tmp/$pid.Rscript";

    open FH, "> $data_file" or croak "fh error\n";
    say FH $header;
    foreach my $p (@$data) {
        say FH join "\t", @$p;
    }
    close FH;

    open FH, "> $script_file" or croak "fh error\n";
    say FH "data <- read.table(\"$data_file\", header=T, sep=\"\\t\")";
    say FH "png(filename=\"$name\", height=600, width=600, bg=\"white\")";
    say FH $script;
    say FH 'dev.off()';
    close FH;

    say `Rscript /tmp/$pid.Rscript`;

    #unlink $data_file, $script_file;
}

my $s;
$s = '
plot(data$num_p_binding, data$length, pch=20, col=data$color, xlab="|Residues predicted as binding|", ylab="Chain length", main="Predicted binding residues per chain")
';
plot("l_vs_b.png", (join "\t", "length", "num_p_binding", "num_o_binding", "color", "file"), \@l_vs_b, $s);

$s = '
plot(data$fpr, data$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC")
';
plot("roc_0.png", (join "\t", "tpr", "fpr"), $roc_data->[0], $s);
$s = '
plot(data$fpr, data$tpr, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="FPR", ylab="TPR", main="ROC")
';
plot("roc_1.png", (join "\t", "tpr", "fpr"), $roc_data->[1], $s);

$s = '
plot(data$recall, data$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision")
';
plot("pr_0.png", (join "\t", "precision", "recall"), $pr_data->[0], $s);
$s = '
plot(data$recall, data$precision, type="l", xlim=c(0, 1), ylim=c(0, 1), pch=20, xlab="Recall", ylab="Precision", main="Recall/Precision")
';
plot("pr_1.png", (join "\t", "precision", "recall"), $pr_data->[1], $s);

say "ROC AUCS: ".(join " ", @aucs);
say "PR AUCS: ".(join " ", @pr_aucs);
