#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Setbench::Source::profRdb;
use Setbench::Source::dssp;
use Setbench::Parser::profRdb;
use Setbench::Parser::dssp;
use NNtrain::Measure;
use Data::Dumper;


my $list_file = shift;


open LIST, $list_file or croak "Could not open $list_file\n";
my @list = <LIST>;
chomp @list;
close LIST;

my $count = 0;

my $ss_3state_per_res = NNtrain::Measure->new(3);
my $acc_10state_per_res = NNtrain::Measure->new(10);
my $acc_3state_per_res = NNtrain::Measure->new(3);
my $acc_2state_per_res = NNtrain::Measure->new(2);

my @ss_3state_per_prot;
my @acc_10state_per_prot;
my @acc_3state_per_prot;
my @acc_2state_per_prot;

foreach my $id (@list) {
    my $prof_file = Setbench::Source::profRdb->predictprotein($id);
    my ($dssp_file, $chain) = Setbench::Source::dssp->rost_db($id);

    my $prof_parser = Setbench::Parser::profRdb->new($prof_file);
    my $dssp_parser = Setbench::Parser::dssp->new($dssp_file);

    my @prof_ss = $prof_parser->PHEL_3state;
    my @prof_acc_10state = $prof_parser->PREL_10state;
    my @prof_acc_3state = $prof_parser->Pbie_3state;
    my @prof_acc_2state = $prof_parser->Pbe_2state;

    my @dssp_ss = $dssp_parser->ss_3state($chain);
    my @dssp_acc_10state = $dssp_parser->acc_10state($chain);
    my @dssp_acc_3state = $dssp_parser->acc_3state($chain);
    my @dssp_acc_2state = $dssp_parser->acc_2state($chain);

    my $ss_3state_per_prot = NNtrain::Measure->new(3);
    my $acc_10state_per_prot = NNtrain::Measure->new(10);
    my $acc_3state_per_prot = NNtrain::Measure->new(3);
    my $acc_2state_per_prot = NNtrain::Measure->new(2);

    foreach my $i (0 .. scalar @dssp_ss - 1) {
        $ss_3state_per_res->add($dssp_ss[$i], $prof_ss[$i]);
        $acc_10state_per_res->add($dssp_acc_10state[$i], $prof_acc_10state[$i]);
        $acc_3state_per_res->add($dssp_acc_3state[$i], $prof_acc_10state[$i]);
        $acc_2state_per_res->add($dssp_acc_2state[$i], $prof_acc_2state[$i]);

        $ss_3state_per_prot->add($dssp_ss[$i], $prof_ss[$i]);
        $acc_10state_per_prot->add($dssp_acc_10state[$i], $prof_acc_10state[$i]);
        $acc_3state_per_prot->add($dssp_acc_3state[$i], $prof_acc_10state[$i]);
        $acc_2state_per_prot->add($dssp_acc_2state[$i], $prof_acc_2state[$i]);
    }

    push @ss_3state_per_prot, $ss_3state_per_prot;
    push @acc_10state_per_prot, $acc_10state_per_prot;
    push @acc_3state_per_prot, $acc_3state_per_prot;
    push @acc_2state_per_prot, $acc_2state_per_prot;
}

my $prot_count = scalar @list;
my ($ss_q3, $acc_q10, $acc_q3, $acc_q2) = (0, 0, 0, 0);
open SS3, ">", "prof.ss_3state";
open ACC10, ">", "prof.acc_10state";
open ACC3, ">", "prof.acc_3state";
open ACC2, ">", "prof.acc_2state";
foreach my $i (0 .. $prot_count - 1) {
    $ss_q3 += $ss_3state_per_prot[$i]->Qn;
    $acc_q10 += $acc_10state_per_prot[$i]->Qn;
    $acc_q3 += $acc_3state_per_prot[$i]->Qn;
    $acc_q2 +=  $acc_2state_per_prot[$i]->Qn;

    

    say SS3 join " ", $list[$i], $ss_3state_per_prot[$i]->num_points, $ss_3state_per_prot[$i]->Qn, $ss_3state_per_prot[$i]->precisions, $ss_3state_per_prot[$i]->recalls, $ss_3state_per_prot[$i]->fmeasures;
    say ACC10 join " ", $list[$i], $acc_10state_per_prot[$i]->num_points, $acc_10state_per_prot[$i]->Qn, $acc_10state_per_prot[$i]->precisions, $acc_10state_per_prot[$i]->recalls, $acc_10state_per_prot[$i]->fmeasures;
    say ACC3 join " ", $list[$i], $acc_3state_per_prot[$i]->num_points, $acc_3state_per_prot[$i]->Qn, $acc_3state_per_prot[$i]->precisions, $acc_3state_per_prot[$i]->recalls, $acc_3state_per_prot[$i]->fmeasures;
    say ACC2 join " ", $list[$i], $acc_2state_per_prot[$i]->num_points, $acc_2state_per_prot[$i]->Qn, $acc_2state_per_prot[$i]->precisions, $acc_2state_per_prot[$i]->recalls, $acc_2state_per_prot[$i]->fmeasures;
}
close SS3;
close ACC10;
close ACC3;
close ACC2;



say "per res";
say $ss_3state_per_res->Qn;
say $acc_10state_per_res->Qn;
say $acc_3state_per_res->Qn;
say $acc_2state_per_res->Qn;

say "avg per prot";
say $ss_q3 / $prot_count;
say $acc_q10 / $prot_count;
say $acc_q3 / $prot_count;
say $acc_q2 / $prot_count;
