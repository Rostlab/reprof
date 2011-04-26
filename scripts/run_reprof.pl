#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

use Reprof::Parser::Pssm;

my $seqnet_dir;
my $strucnet_dir;
my $fasta_file;
my $pssm_file;

GetOptions( 'seqnet=s'      =>  \$seqnet_dir,
            'strucnet=s'    =>  \$strucnet_dir,
            'pssm=s'        =>  \$pssm_file,
            'fasta=s'       =>  \$fasta_file );

my $pssm = Reprof::Parser::Pssm->new($pssm_file);

