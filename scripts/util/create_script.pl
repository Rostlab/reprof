#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Produces sets for the reprof neural
#           network using several data resources 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

use AI::FANN qw(:all);
use Getopt::Long;
use Prot::Tools::Translator qw(id2pdb aa2number ss2number);
use Prot::Parser::Dssp;
use File::Spec;
use List::Util qw(shuffle);

my $dssp_dir; 
my $pssm_dir;
my $fasta_file;
my $out_dir;
my $num_sets;
my $prefix = "set_";

my $num_desc = 3; # DP number as ss 
my $num_as = 21;
my $num_ss = 3;

my $debug = 0;

GetOptions(     'out=s' 	=> \$out_dir,
                'fasta=s'	=> \$fasta_file,
                'pssm=s'	=> \$pssm_dir,
                'dssp=s'	=> \$dssp_dir,
                'sets=i'	=> \$num_sets,
                'prefix=s'	=> \$prefix,
                'debug'		=> \$debug);

unless ($out_dir && $fasta_file && $pssm_dir && $dssp_dir && $num_sets) {
    say "\nDESC:\nproduces sets for the reprof neural network using several data resources";
    say "\nUSAGE:\n$0 -out <outputdir> -fasta <fastafile> -pssm <pssmdir> -dssp <dsspdir> -sets <numsets> -prefix <setprefix>";
    say "\nOPTS:\nfastafile:\n\tids which are used to create the sets\nsets:\n\tnumber of sets which are created\nprefix:\n\tthe prefix which should be in front of the set files (default: set_)\n";
    die "Invalid options";
}

