#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     trains the fann neural network
#           with the given datasets
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Getopt::Long;
use List::Util qw(sum shuffle);
use Reprof::Measure;

my $test_file;
my $out;

GetOptions(
    "set=s" =>  \$test_file,
    "out=s" =>  \$out,
);

my $result_file = "$out/nntrain.result";
my $num_outputs;

sub out2prob {
    my @array = @_;
    my $sum = sum @array;
    foreach my $p (@array) {
        $p /= $sum;
    }
    return @array;
}

my $data = [];
open DATA, "$test_file" or croak "fh error\n";
while (my $inputs = <DATA>) {
    chomp $inputs;
    my $outputs = <DATA>;
    chomp $outputs;
    my @split_inputs = split /\s+/, $inputs;
    my @split_outputs = split /\s+/, $outputs;
    $num_outputs = scalar @split_outputs;

    my $count = 0;
    my @tmp = map {0} (1 .. $num_outputs);
    
    while (scalar @split_inputs > 0) {
        $count++;
        my @tmp_data;
        foreach my $i (0 .. $num_outputs - 1) {
            push @tmp_data, (shift @split_inputs);
        }
        my @tmp_data_prob = out2prob @tmp_data;
        foreach my $i (0 .. $num_outputs - 1) {
            $tmp[$i] += $tmp_data_prob[$i];
        }
    }
    foreach my $i (0 .. $num_outputs - 1) {
        $tmp[$i] /= $count;
    }
    push @$data, [\@split_outputs, \@tmp];
}
close DATA;

my $test_measure = Reprof::Measure->new($num_outputs);
foreach my $dp (@$data) {
    my ($observed, $predicted) = @$dp;
    say "o: ".(join " ", @$observed)." p: ".(join " ", @$predicted);
    $test_measure->add($observed, $predicted);
}


open RESULT, ">", $result_file  or die "Could not open $result_file\n";
say RESULT join " ", "test_qn", (map {sprintf "%.3f", $_*100} ($test_measure->Qn));
say RESULT join " ", "test_precisions", (map {sprintf "%.3f", $_*100} ($test_measure->precisions));
say RESULT join " ", "test_recalls", (map {sprintf "%.3f", $_*100} ($test_measure->recalls));
say RESULT join " ", "test_fmeasures", (map {sprintf "%.3f", $_*100} ($test_measure->fmeasures));
say RESULT join " ", "test_aucs", (map {sprintf "%.3f", $_*100} ($test_measure->aucs));
say RESULT join " ", "test_mccs", (map {sprintf "%.3f", $_*100} ($test_measure->mccs));
close RESULT;
