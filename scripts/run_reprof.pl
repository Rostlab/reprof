#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

my $seqnet;
my $strucnet;
my $fasta;
my $pssm;

GetOptions( 'seqnet=s'      =>  \$seqnet,
            'strucnet=s'    =>  \$strucnet,
            'pssm=s'        =>  \$pssm,
            'fasta=s'       =>  \$fasta );

