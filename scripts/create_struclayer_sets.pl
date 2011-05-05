#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Produces sets for the reprof neural
#           network structure layer using several 
#           data resources 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

use AI::FANN qw(:all);
use Getopt::Long;
use Reprof::Tools::Translator qw(id2pdb aa2number ss2number);
use Reprof::Parser::Dssp;
use File::Spec;
use List::Util qw(shuffle);
use Reprof::Tools::Set;
use Reprof::Tools::Measure;

my $seq_net;
my $out_file;
my $inset_dir;
my $win;

my $num_desc = 3; # DP number as ss 
my $num_features = 3;
my $num_outputs = 3;

my $debug = 0;

GetOptions(
    'out=s' 	=> \$out_file,
    'net=s'	=> \$seq_net,
    'set=s'    	=> \$inset_dir,
    'win=i'     => \$win,
    'debug'	=> \$debug);

unless ($out_file && $seq_net && $inset_dir && $win) {
    say "\nDESC:\n!!! NOT UP TO DATE !!!\nproduces sets for the reprof neural network using several data resources";
    say "\nUSAGE:\n$0 -out <outputdir> -seqnet <seqnet>  -sets <numsets> -prefix <setprefix>";
    say "\nOPTS:\nsets:\n\tnumber of sets which are created\nprefix:\n\tthe prefix which should be in front of the set files (default: set_)\n";
    die "Invalid options";
}


#--------------------------------------------------
# Load set
#-------------------------------------------------- 
say "Loading sets...";
my $set = Reprof::Tools::Set->new($inset_dir, $win);
$set->reset_iter_original;

#--------------------------------------------------
# Load nn 
#-------------------------------------------------- 

say "Loading nn...";
my $nn = AI::FANN->new_from_file($seq_net);

#--------------------------------------------------
# Open outputfiles and write headers
#-------------------------------------------------- 
open OUT, '>', $out_file or die "Could not open $out_file\n";
say OUT "HD\t$num_desc\t$num_features\t$num_outputs";

#--------------------------------------------------
# Run through the data and write out setfile 
#-------------------------------------------------- 
my $measure = Reprof::Tools::Measure->new($num_outputs);
my $last_pos = 1337;
my $prot_count = 0;

while (my $dp = $set->next_dp) {
    if ($dp->[0][0] <= $last_pos) {
        say OUT "ID\t$prot_count";
        ++$prot_count;
    }
    
    $last_pos = $dp->[0][0];

    my $result = $nn->run($dp->[1]);

    $measure->add($dp->[2], $result);

    print OUT "DP\t";
    print OUT (join "\t", @{$dp->[0]}) . "\t";
    foreach my $val (@$result) {
        printf OUT "%.5f\t", $val;
    }
    print OUT (join "\t", @{$dp->[2]});
    print OUT "\n";
}

printf "Q3 on given input sets: %.3f\n", $measure->Q3;

#--------------------------------------------------
# Closing filehandles
#-------------------------------------------------- 
close OUT;

#--------------------------------------------------
# Little helpers
#-------------------------------------------------- 
#--------------------------------------------------
# name:        normalize_pssm
# args:        pssm value
# return:      normalized pssm value
#-------------------------------------------------- 
sub normalize_pssm {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

#--------------------------------------------------
# name:        empty_array
# args:        size of the resulting array
# return:      an array of given length filled with
#              zeroes 
#-------------------------------------------------- 
sub empty_array {
    my $size = shift;

    my @array;
    foreach (1..$size) {
        push @array, 0;
    }

    return @array;
}

sub output_to_ss {
    my ($h, $e, $l) = @_;

    my $maxpos = -1;
    if ($h >= $e && $h >= $l) {
        $maxpos = 0;
    }
    elsif ($e >= $h && $e >= $l) {
        $maxpos = 1;
    }
    elsif ($l >= $h && $l >= $e) {
        $maxpos = 2;
    }

    return ss2number($maxpos);
}
