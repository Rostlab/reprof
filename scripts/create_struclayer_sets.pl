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
use Reprof::Tools::Set;
use Reprof::Parser::Set;
use Reprof::Tools::Measure;

my $net_file;
my $out_file;
my $inset_file;
my $win;

my $num_desc = 3; # DP number as ss 
#my $num_features = 8;
my $num_features = 3;
my $num_outputs = 3;

my $debug = 0;

GetOptions(
    'out=s' 	=> \$out_file,
    'net=s'	=> \$net_file,
    'set=s'    	=> \$inset_file,
    'win=i'     => \$win,
    'debug'	=> \$debug);

unless ($out_file && $net_file && $inset_file && $win) {
    say "\nDESC:\n!!! NOT UP TO DATE !!!\nproduces sets for the reprof neural network using several data resources";
    say "\nUSAGE:\n$0 -out <outputdir> -seqnet <seqnet>  -sets <numsets> -prefix <setprefix>";
    say "\nOPTS:\nsets:\n\tnumber of sets which are created\nprefix:\n\tthe prefix which should be in front of the set files (default: set_)\n";
    die "Invalid options";
}


#--------------------------------------------------
# Load set
#-------------------------------------------------- 
say "Loading sets...";
my $set_parser = Reprof::Parser::Set->new($inset_file);
my $set = $set_parser->get_set;
$set->win($win);

#--------------------------------------------------
# Load nn 
#-------------------------------------------------- 

say "Loading nn...";
my $nn = AI::FANN->new_from_file($net_file);

#--------------------------------------------------
# Open outputfiles and write headers
#-------------------------------------------------- 
open OUT, '>', $out_file or die "Could not open $out_file\n";
say OUT "HD\t$num_desc\t$num_features\t$num_outputs";

#--------------------------------------------------
# Run through the data and write out setfile 
#-------------------------------------------------- 
my $measure = Reprof::Tools::Measure->new($num_outputs);

my $last_id = "";
while (my $dp = $set->next_dp) {
    if ($dp->[4] ne $last_id) {
        $last_id = $dp->[4];
        say "Doing $last_id";
        say OUT "ID $last_id";
    }

    my $result = $nn->run($dp->[1]);

    $measure->add($dp->[2], $result);

    print OUT "DP\t";
    print OUT (join "\t", @{$dp->[0]}) . "\t";
    print OUT (join "\t", @$result) . "\t";
#my @add_features = (@{$dp->[3]})[20 .. scalar @{$dp->[3]} - 1];
#print OUT (join "\t", @add_features) . "\t";
    say OUT (join "\t", @{$dp->[2]});
}

printf "Q3 on given input sets: %.3f\n", $measure->Q3;

#--------------------------------------------------
# Closing filehandles
#-------------------------------------------------- 
close OUT;
