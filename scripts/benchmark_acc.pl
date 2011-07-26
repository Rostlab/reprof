#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Carp;
use NNtrain::Measure;

my $set_file;
my $output_file;

GetOptions( 'set|s=s'    =>  \$set_file,
        'output|o=s'    =>  \$output_file);

my @observed;

open SET, $set_file or croak "Could not open $set_file\n";
while (my $line = <SET>) {
    my $out = <SET>;
    chomp $out;
    my @split = split /\s+/, $out;
    push @observed, \@split;
}
close SET;

open OUTPUT, $output_file or croak "Could not open $output_file\n";
my @predicted;
while (my $line = <OUTPUT>) {
    my @split = split /\s+/, $line;
    push @predicted, \@split;
}
close OUTPUT;

# observed predicted
my $measure_2state = NNtrain::Measure->new(2);
my $measure_3state = NNtrain::Measure->new(3);
my $measure_10state = NNtrain::Measure->new(10);

sub max_pos {
    my ($array) = @_;

    my $mpos = 0;
    foreach my $pos (1 .. scalar @$array - 1) {
        if ($array->[$pos] > $array->[$mpos]) {
            $mpos = $pos;
        }
    }

    return $mpos;
}

sub ten2two {
    my ($ten) = @_;
    my $max_ten = max_pos($ten);

    if ($max_ten * $max_ten < 16) {
        return [1, 0];
    }
    else {
        return [0, 1];
    }
}

sub ten2three {
    my ($ten) = @_;
    my $max_ten = max_pos($ten);

    if ($max_ten * $max_ten < 9) {
        return [1, 0, 0];
    }
    elsif ($max_ten * $max_ten < 36) {
        return [0, 1, 0];
    }
    else {
        return [0, 0, 1];
    }
}

my $o_size = scalar @observed;
my $p_size = scalar @predicted;
say "o_size: $o_size, p_size: $p_size";

foreach my $i (0 .. $o_size - 1) {
    my $o_10 = $observed[$i];
    my $p_10 = $predicted[$i];
    my $o_3 = ten2three($observed[$i]);
    my $p_3 = ten2three($predicted[$i]);
    my $o_2 = ten2two($observed[$i]);
    my $p_2 = ten2two($predicted[$i]);

    #say (join ", ", @$o_10, @$p_10, @$o_3, @$p_3, @$o_2, @$p_2);

    $measure_2state->add($o_2, $p_2);
    $measure_3state->add($o_3, $p_3);
    $measure_10state->add($o_10, $p_10);
}

say "Q2: ".$measure_2state->Qn;
say "Q3: ".$measure_3state->Qn;
say "Q10: ".$measure_10state->Qn;
