#!/usr/bin/perl -w
use strict;
use Carp;
use Getopt::Long;
use Perlpred::Parser::fasta_multi;
use Perlpred::Parser::reprof;
use Perlpred::Parser::dssp;
use Perlpred::Parser::profRdb;
use Perlpred::Parser::horiz;
use Perlpred::Source::horiz;
use Perlpred::Source::dssp;
use Perlpred::Source::reprof;
use Perlpred::Source::profRdb;
use Perlpred::Measure;

my $fasta_file = shift;
my $out_file = shift || "reprof.pdf";

my $fasta_multi_parser = Perlpred::Parser::fasta_multi->new($fasta_file);

my $measure_rep = Perlpred::Measure->new(3);
my @measures_rep;
my $class_measure_rep = Perlpred::Measure->new(4);
my @ri_measures_rep;
foreach my $i (0 .. 9) {
    push @ri_measures_rep, Perlpred::Measure->new(3);
}

my $measure_psi = Perlpred::Measure->new(3);
my @measures_psi;
my $class_measure_psi = Perlpred::Measure->new(4);
my @ri_measures_psi;
foreach my $i (0 .. 9) {
    push @ri_measures_psi, Perlpred::Measure->new(3);
}

my $measure_prof = Perlpred::Measure->new(3);
my @measures_prof;
my $class_measure_prof = Perlpred::Measure->new(4);
my @ri_measures_prof;
foreach my $i (0 .. 9) {
    push @ri_measures_prof, Perlpred::Measure->new(3);
}

my $count = 0;
while ($fasta_multi_parser->next) {
    print ++$count, "\n";
    #last if $count == 10;
    my ($id, $sequence) = $fasta_multi_parser->get_entry;

    my $reprof_file = Perlpred::Source::reprof->reprof($id, $sequence);
    my $reprof_parser = Perlpred::Parser::reprof->new($reprof_file);

    my $psipred_file = Perlpred::Source::horiz->reprof($id, $sequence);
    my $psipred_parser = Perlpred::Parser::horiz->new($psipred_file);

    my $prof_file = Perlpred::Source::profRdb->predictprotein($id, $sequence);
    my $prof_parser = Perlpred::Parser::profRdb->new($prof_file);

    my ($dssp_file, $chain) = Perlpred::Source::dssp->rost_db($id, $sequence);
    my $dssp_parser = Perlpred::Parser::dssp->new($dssp_file);

    my @sec_rep = $reprof_parser->PHEL_3state;
    my @ri_rep = $reprof_parser->RI_S;
    my @class_rep = $reprof_parser->class_4state;

    my @sec_psi = $psipred_parser->PHEL_3state;
    my @ri_psi = $psipred_parser->conf;
    my @class_psi = $psipred_parser->class_4state;

    my @sec_prof = $prof_parser->PHEL_3state;
    my @ri_prof = $prof_parser->RI_S;
    my @class_prof = $prof_parser->class_4state;

    my @sec_dssp = $dssp_parser->sec_3state($chain);
    my @class_dssp = $dssp_parser->class_4state($chain);

    my $length = scalar @sec_dssp;
    
    $class_measure_rep->add(\@class_dssp, \@class_rep);
    $class_measure_psi->add(\@class_dssp, \@class_psi);
    $class_measure_prof->add(\@class_dssp, \@class_prof);
    my $tmp_measure_rep = Perlpred::Measure->new(3);
    my $tmp_measure_psi = Perlpred::Measure->new(3);
    my $tmp_measure_prof = Perlpred::Measure->new(3);
    foreach my $i (0 .. $length - 1) {
        $measure_rep->add($sec_dssp[$i], $sec_rep[$i]);
        $measure_psi->add($sec_dssp[$i], $sec_psi[$i]);
        $measure_prof->add($sec_dssp[$i], $sec_prof[$i]);

        $tmp_measure_rep->add($sec_dssp[$i], $sec_rep[$i]);
        $tmp_measure_psi->add($sec_dssp[$i], $sec_psi[$i]);
        $tmp_measure_prof->add($sec_dssp[$i], $sec_prof[$i]);

        foreach my $ri (0 .. $ri_rep[$i]) {
            $ri_measures_rep[$ri]->add($sec_dssp[$i], $sec_rep[$i]);
        }
        foreach my $ri (0 .. $ri_psi[$i]) {
            $ri_measures_psi[$ri]->add($sec_dssp[$i], $sec_psi[$i]);
        }
        foreach my $ri (0 .. $ri_prof[$i]) {
            $ri_measures_prof[$ri]->add($sec_dssp[$i], $sec_prof[$i]);
        }
    }
    push @measures_rep, $tmp_measure_rep;
    push @measures_psi, $tmp_measure_psi;
    push @measures_prof, $tmp_measure_prof;
}

# start plot
sub write_data_file {
    my ($data_file, $data, @header) = @_;

    open FH, "> $data_file" or croak "fh error\n";
    print FH join "\t", @header, "\n";
    foreach my $p (@$data) {
        print FH join "\t", @$p, "\n";
    }
    close FH;
}

my $pid = $$;
print "pid: $pid", "\n";
my $data_tmp = "/tmp/plot_$pid";

my $script_file = "/tmp/plot_$pid.Rscript";
open SCRIPT, "> $script_file" or confess "fh error\n";
print SCRIPT "pdf(\"$out_file\")", "\n";

#
my @measure_data;
push @measure_data, [$measure_rep->Qn, $measure_rep->precisions, $measure_rep->recalls, $measure_rep->fmeasures, $measure_rep->mccs];
push @measure_data, [$measure_psi->Qn, $measure_psi->precisions, $measure_psi->recalls, $measure_psi->fmeasures, $measure_psi->mccs];
push @measure_data, [$measure_prof->Qn, $measure_prof->precisions, $measure_prof->recalls, $measure_prof->fmeasures, $measure_prof->mccs];
my $measure_file = "$data_tmp.measures";
write_data_file($measure_file, \@measure_data, qw(q3 pH pE pL rH rE rL fH fE fL mH mE mL));
print SCRIPT "measure <- read.table(\"$measure_file\", header=T, sep=\"\\t\")\n";
print SCRIPT 'barplot(as.matrix(measure), beside=TRUE, cex.names=0.7, main="Different Measures (per residue)", ylim=c(0, 1), legend.text=c("reprof", "psipred", "prof"))', "\n";

#
my @avg_measure_data;

my @avg_measure_rep_data = map {0} (1 .. 13);
my @hist_rep_data;
my @l_rep_data;
foreach my $measure (@measures_rep) {
    my @current_values = ($measure->Qn * 100, map {$_ * 100} $measure->precisions, map {$_ * 100} $measure->recalls, map {$_ * 100} $measure->fmeasures, map {$_ * 100} $measure->mccs);
    push @l_rep_data, [$measure->num_points, @current_values];
    push @hist_rep_data, \@current_values;
    foreach my $i (0 .. scalar @avg_measure_rep_data - 1) {
        $avg_measure_rep_data[$i] += $current_values[$i];
    }
}
foreach my $val (@avg_measure_rep_data) {
    $val /= $count;
}
push @avg_measure_data, \@avg_measure_rep_data;

my @avg_measure_psi_data = map {0} (1 .. 13);
my @hist_psi_data;
my @l_psi_data;
foreach my $measure (@measures_psi) {
    my @current_values = ($measure->Qn, $measure->precisions, $measure->recalls, $measure->fmeasures, $measure->mccs);
    push @l_psi_data, [$measure->num_points, @current_values];
    push @hist_psi_data, \@current_values;
    foreach my $i (0 .. scalar @avg_measure_psi_data - 1) {
        $avg_measure_psi_data[$i] += $current_values[$i];
    }
}
foreach my $val (@avg_measure_psi_data) {
    $val /= $count;
}
push @avg_measure_data, \@avg_measure_psi_data;

my @avg_measure_prof_data = map {0} (1 .. 13);
my @hist_prof_data;
my @l_prof_data;
foreach my $measure (@measures_prof) {
    my @current_values = ($measure->Qn, $measure->precisions, $measure->recalls, $measure->fmeasures, $measure->mccs);
    push @l_prof_data, [$measure->num_points, @current_values];
    push @hist_prof_data, \@current_values;
    foreach my $i (0 .. scalar @avg_measure_prof_data - 1) {
        $avg_measure_prof_data[$i] += $current_values[$i];
    }
}
foreach my $val (@avg_measure_prof_data) {
    $val /= $count;
}
push @avg_measure_data, \@avg_measure_prof_data;

my $avg_measure_file = "$data_tmp.avg_measures";
write_data_file($avg_measure_file, \@avg_measure_data, qw(q3 pH pE pL rH rE rL fH fE fL mH mE mL));
print SCRIPT "avg_measure <- read.table(\"$avg_measure_file\", header=T, sep=\"\\t\")\n";
print SCRIPT 'barplot(as.matrix(avg_measure), beside=TRUE, cex.names=0.7, main="Different Measures (per chain)", ylim=c(0, 1), legend.text=c("reprof", "psipred", "prof"))', "\n";

#
my @class_measure_data;
push @class_measure_data, [$class_measure_rep->Qn, $class_measure_rep->precisions, $class_measure_rep->recalls, $class_measure_rep->fmeasures, $class_measure_rep->mccs];
push @class_measure_data, [$class_measure_psi->Qn, $class_measure_psi->precisions, $class_measure_psi->recalls, $class_measure_psi->fmeasures, $class_measure_psi->mccs];
push @class_measure_data, [$class_measure_prof->Qn, $class_measure_prof->precisions, $class_measure_prof->recalls, $class_measure_prof->fmeasures, $class_measure_prof->mccs];
my $class_measure_file = "$data_tmp.class_measures";
write_data_file($class_measure_file, \@class_measure_data, qw(q3 pH pE pM pO rH rE rM rO fH fE fM fO mH mE mM mO));
print SCRIPT "class_measure <- read.table(\"$class_measure_file\", header=T, sep=\"\\t\")\n";
print SCRIPT 'barplot(as.matrix(class_measure), beside=TRUE, cex.names=0.7, main="Different Measures (structural class)", ylim=c(0, 1), legend.text=c("reprof", "psipred", "prof"))', "\n";

#
my $hist_rep_file = "$data_tmp.hist_rep";
write_data_file($hist_rep_file, \@hist_rep_data, qw(q3 pH pE pL rH rE rL fH fE fL mH mE mL));
say SCRIPT "hist_rep <- read.table(\"$hist_rep_file\", header=T, sep=\"\\t\")";
say SCRIPT 'hist(hist_rep$q3, main="Q3 Histogram", xlab="Q3", ylab="number of chains", xlim=c(0, 1), breaks=50)';
say SCRIPT 'hist(hist_rep$pH, main="Precision Helix Histogram", xlab="Precision", ylab="number of chains", xlim=c(0, 1), breaks=50)';
say SCRIPT 'hist(hist_rep$pE, main="Precision Sheet Histogram", xlab="Precision", ylab="number of chains", xlim=c(0, 1), breaks=50)';
say SCRIPT 'hist(hist_rep$rH, main="Recall Helix Histogram", xlab="Recall", ylab="number of chains", xlim=c(0, 1), breaks=50)';
say SCRIPT 'hist(hist_rep$rE, main="Recall Sheet Histogram", xlab="Recall", ylab="number of chains", xlim=c(0, 1), breaks=50)';

#
my $l_rep_file = "$data_tmp.l_rep";
write_data_file($l_rep_file, \@l_rep_data, qw(length q3 pH pE pL rH rE rL fH fE fL mH mE mL));
say SCRIPT "l_rep <- read.table(\"$l_rep_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(l_rep$length, l_rep$q3, ylim=c(0, 1), main="Q3 / chain length", xlab="chain length", ylab="Q3")';

#
my $l_psi_file = "$data_tmp.l_psi";
write_data_file($l_psi_file, \@l_psi_data, qw(length q3 pH pE pL rH rE rL fH fE fL mH mE mL));
say SCRIPT "l_psi <- read.table(\"$l_psi_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(l_psi$length, l_psi$q3, ylim=c(0, 1), main="Q3 / chain length", xlab="chain length", ylab="Q3")';

#
my $l_prof_file = "$data_tmp.l_prof";
write_data_file($l_prof_file, \@l_prof_data, qw(length q3 pH pE pL rH rE rL fH fE fL mH mE mL));
say SCRIPT "l_prof <- read.table(\"$l_prof_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(l_prof$length, l_prof$q3, ylim=c(0, 1), main="Q3 / chain length", xlab="chain length", ylab="Q3")';

#
my @ri_rep_data;
foreach my $i (0 .. 9) {
    push @ri_rep_data, [$i, 
        $ri_measures_rep[$i]->num_points,
        100 * ($ri_measures_rep[$i]->num_points / $measure_rep->num_points),
        100 * $ri_measures_rep[$i]->Qn,
        map {$_ * 100} $ri_measures_rep[$i]->precisions,
        map {$_ * 100} $ri_measures_rep[$i]->recalls,
        map {$_ * 100} $ri_measures_rep[$i]->fmeasures,
        map {$_ * 100} $ri_measures_rep[$i]->mccs,
        ];
}
my $ri_rep_file = "$data_tmp.ri_rep";
write_data_file($ri_rep_file, \@ri_rep_data, qw(RI abs rel q3 pH pE pL rH rE rL fH fE fL mH mE mL));

my @ri_psi_data;
foreach my $i (0 .. 9) {
    push @ri_psi_data, [$i, 
        $ri_measures_psi[$i]->num_points,
        ($ri_measures_psi[$i]->num_points / $measure_psi->num_points),
        $ri_measures_psi[$i]->Qn,
        $ri_measures_psi[$i]->precisions,
        $ri_measures_psi[$i]->recalls,
        $ri_measures_psi[$i]->fmeasures,
        $ri_measures_psi[$i]->mccs,
        ];
}
my $ri_psi_file = "$data_tmp.ri_psi";
write_data_file($ri_psi_file, \@ri_psi_data, qw(RI abs rel q3 pH pE pL rH rE rL fH fE fL mH mE mL));

my @ri_prof_data;
foreach my $i (0 .. 9) {
    push @ri_prof_data, [$i, 
        $ri_measures_prof[$i]->num_points,
        ($ri_measures_prof[$i]->num_points / $measure_prof->num_points),
        $ri_measures_prof[$i]->Qn,
        $ri_measures_prof[$i]->precisions,
        $ri_measures_prof[$i]->recalls,
        $ri_measures_prof[$i]->fmeasures,
        $ri_measures_prof[$i]->mccs,
        ];
}
my $ri_prof_file = "$data_tmp.ri_prof";
write_data_file($ri_prof_file, \@ri_prof_data, qw(RI abs rel q3 pH pE pL rH rE rL fH fE fL mH mE mL));

say SCRIPT "ri_rep <- read.table(\"$ri_rep_file\", header=T, sep=\"\\t\")";
say SCRIPT 'plot(ri_rep$rel, ri_rep$q3, type="o", ylim=c(0, 1), xlim=c(0, 1), main="Q3 for predictions above RI index", xlab="percentage of residues", ylab="Q3", col="green")';
say SCRIPT 'text(ri_rep$rel, y=ri_rep$q3, labels=ri_rep$RI, pos=3, col="green")';#, offset=0.2, cex=0.5)';

say SCRIPT "ri_psi <- read.table(\"$ri_psi_file\", header=T, sep=\"\\t\")";
say SCRIPT 'points(ri_psi$rel, ri_psi$q3, type="o", col="orange")';
say SCRIPT 'text(ri_psi$rel, y=ri_psi$q3, labels=ri_psi$RI, pos=3, col="orange")';#, offset=0.2, cex=0.5)';

say SCRIPT "ri_prof <- read.table(\"$ri_prof_file\", header=T, sep=\"\\t\")";
say SCRIPT 'points(ri_prof$rel, ri_prof$q3, type="o", col="red")';
say SCRIPT 'text(ri_prof$rel, y=ri_prof$q3, labels=ri_prof$RI, pos=3, col="red")';#, offset=0.2, cex=0.5)';

# end
say SCRIPT "dev.off()";

# single plots
say SCRIPT 'tiff("./hist_50.tiff")';
say SCRIPT 'hist(hist_rep$q3, xlab="Q3 [%]", ylab="Number of chains", xlim=c(0, 100), breaks=50, main=NULL, cex.lab=1.5)';
say SCRIPT 'grid()';
say SCRIPT 'box()';
say SCRIPT 'dev.off()';

say SCRIPT 'tiff("./ri.tiff")';
say SCRIPT 'plot(ri_rep$rel, ri_rep$q3, type="o", ylim=c(0, 100), xlim=c(0, 100), xlab="% of residues", ylab="Q3 [%]", main=NULL, cex.lab=1.5)';
say SCRIPT 'text(x=ri_rep$rel, y=ri_rep$q3, labels=ri_rep$RI, pos=3)';#, offset=0.2, cex=0.5)';
say SCRIPT 'grid()';
say SCRIPT 'box()';
say SCRIPT 'dev.off()';

close SCRIPT;
say `Rscript $script_file`;

say `rm /tmp/plot_*`;

