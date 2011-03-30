#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     parses a dssp file and outputs a easy
#           readable format 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);
use Getopt::Long;

use Reprof::Parser::Dssp;

my $dssp;
my $chain_regex = ".*";

my $linelength = 20;

GetOptions( 'dssp=s'    =>  \$dssp,
            'chain=s'    => \$chain_regex );

unless ($dssp) {
    say "desc:\nparses a dssp file and outputs a easy readable format";
    say "usage:\n$0 -dssp <dsspfile> [-chain <chainregex>]";
    say "opts:\nchainregex: a regular expression describing the chains to display";
    die "Invalid call";
}

if (!-e $dssp) {
    warn "Could not find $dssp\n";
    $dssp = "/mnt/project/rost_db/data/dssp/".(substr $dssp, 1, 2)."/pdb$dssp.dssp";
    warn "Trying $dssp\n";
}

my $parser = Reprof::Parser::Dssp->new;
$parser->parse($dssp);

my @chains = $parser->chains;

say "ID: $parser->id";
foreach my $chain (@chains) {
    next unless ($chain =~ /$chain_regex/i);

    my $as_seq = $parser->seq($chain);
    my $ss_seq = $parser->ss($chain);

    say sprintf "CHAIN: %s, LENGTH: %d", $chain, (length $as_seq);
    say "AS: $as_seq";
    say "SS: $ss_seq\n";
}

