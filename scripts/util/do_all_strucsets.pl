#!/usr/bin/perl -w
use strict;
use feature qw(say);

my @types = 

my $seqdir = "./data/sets_seqlayer/";
my $strucdir = "./data/sets_struclayer/";
my $netdir = "./data/nets/";

foreach my $nr (1 .. 3) {
    my $net = `ls $netdir/$nr/`;
    chomp $net;
    say "net: $net";
    $net =~ m/\.w(\d+)\./;
    my $win = $1;
    say "win: $win";
    foreach my $type (qw(train valid test)) {
        
        my @call = (    "time", "./scripts/create_struclayer_sets.pl",
                        "-set", "$seqdir/$type/$nr/",
                        "-net", "$netdir/$nr/$net",
                        "-win", "$win",
                        "-out", "$strucdir/$type/$nr/$type$nr.struc.set");

        system @call;
        #say "$call";
    }
}
