#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Carp;
use AI::FANN;
use NNtrain::Measure;

my $net_file;
my $set_file;
my $out_file;

GetOptions( 'net|n=s'    =>  \$net_file,
        'set|s=s'    =>  \$set_file,
        'out|o=s'    =>  \$out_file );

sub parse_data {
    my ($file) = @_;

    open FH, $file or croak "Could not open $file\n";

    my @data;
    while (my $inputs = <FH>) {
        chomp $inputs;
        my $outputs = <FH>;
        chomp $outputs;
        push @data, [$inputs, $outputs];
    }
    close FH;
    return @data;
}

sub iostring2arrays {
    my $dp = shift;
    
    my @inputs = split /\s+/, $dp->[0];
    my @outputs = split /\s+/, $dp->[1];

    return (\@inputs, \@outputs);
}

my @data = parse_data($set_file);

my $ann = AI::FANN->new_from_file($net_file);
$ann->reset_MSE;

open OUT, ">", $out_file or croak "Could not open $out_file\n";

my @fakepoint = iostring2arrays($data[0]);
my $fakeout = $fakepoint[1];
my $measure = NNtrain::Measure->new(scalar @$fakeout);

foreach my $dp (@data) {
    my @dp_data = iostring2arrays($dp);
    my $pred = $ann->test(@dp_data);
    #$measure->add($dp_data[1], $pred);
    say OUT join " ", @$pred;
}
close OUT;


say $measure->Qn;
