#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Carp;
use AI::FANN;
use Reprof::Measure;

my $out_file;

GetOptions('out=s' => \$out_file);

my @dirs = @ARGV;

open OUT, ">", $out_file or croak "Could not open $out_file\n";
foreach my $dir (@dirs) {
    next unless -d $dir;

    my $setconvert_file = "$dir/test.setconvert";
    my $net_file = "$dir/nntrain.model";

    say `/mnt/project/reprof/scripts/setconvert.pl -config $setconvert_file`;

    open SETCONVERT, $setconvert_file or croak "Could not open $setconvert_file\n";
    my ($set_out_line) = grep /^option out/, (<SETCONVERT>);
    my @set_out_split = split /\s+/, $set_out_line;
    my $set_file = $set_out_split[2];
    close SETCONVERT;

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


    my @fakepoint = iostring2arrays($data[0]);
    my $fakeout = $fakepoint[1];

    my $count = 1;
    foreach my $dp (@data) {
        say $count++ if $count % 1000 == 0;
        my ($inputs, $outputs) = iostring2arrays($dp);
        my $pred = $ann->run($inputs);
        say OUT join " ", @$pred, @$outputs;
    }
}
close OUT;
