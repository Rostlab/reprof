#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Produces sets for the reprof neural
#           network sequence layer using several 
#           data resources 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

use AI::FANN qw(:all);
use Getopt::Long;
use Reprof::Tools::Converter qw(convert_id convert_ss);
use Reprof::Parser::Dssp;
use Reprof::Parser::Pssm;
use Reprof::Tools::Featurefactory;
use List::Util qw(shuffle);
use Data::Dumper;

my $dssp_dir = "/mnt/project/rost_db/data/dssp/"; 
my $pssm_dir = "data/pssm/";
my $fasta_file;
my $out_dir;
my $num_sets;

my $num_desc = 4; # DP number as ss 
my %num_features = (norm => 25, pc => 25, both => 45);
my %num_outputs = (ss => 3, acc => 1);

my $debug = 0;

my @modes = qw(ss acc);
my @submodes = qw(norm pc both);

GetOptions(     'out=s' 	=> \$out_dir,
                'fasta=s'	=> \$fasta_file,
                'pssm=s'	=> \$pssm_dir,
                'dssp=s'	=> \$dssp_dir,
                'sets=i'	=> \$num_sets,
                'debug'		=> \$debug);

unless ($out_dir && $fasta_file && $pssm_dir && $dssp_dir && $num_sets) {
    say "\nDESC:\nproduces sets for the reprof neural network using several data resources";
    say "\nUSAGE:\n$0 -out <outputdir> -fasta <fastafile> -pssm <pssmdir> -dssp <dsspdir> -sets <numsets> -prefix <setprefix>";
    say "\nOPTS:\nfastafile:\n\tids which are used to create the sets\nsets:\n\tnumber of sets which are created\nprefix:\n\tthe prefix which should be in front of the set files (default: set_)\n";
    die "Invalid options";
}

#--------------------------------------------------
# Load fasta and store ids in hash
#-------------------------------------------------- 
say "Getting ids/chains from fasta...";
my %proteins;
open FASTA, $fasta_file or die "Could not open $fasta_file\n";
while (my $line = <FASTA>) {
	if ($line =~ m/^>/) {
		my $id = convert_id($line, 'pdbchain');
        $proteins{$id}++;
	}
}
close FASTA;
say "".(scalar keys %proteins)." ids found in fasta file...";

#--------------------------------------------------
# Shuffle proteins/chains
#-------------------------------------------------- 
say "Shuffling proteins...";
my @shuffled_protein_ids = shuffle(keys %proteins);

#--------------------------------------------------
# Open outputfiles and write headers
#-------------------------------------------------- 
my $out_fhs;
foreach my $mode (@modes) {
    foreach my $submode (@submodes) {
        foreach my $set (1 .. $num_sets) {
            my $fh;
            open $fh, '>', "$out_dir/$set.$mode.$submode.set" or die "Could not open outputfil\n";
            say $fh "HD\t$num_desc\t$num_features{$submode}\t$num_outputs{$mode}";
            push @{$out_fhs->{$mode}{$submode}}, $fh;
        }
    }
}

#--------------------------------------------------
# Iterate through proteins, gather data from DSSP
# and PSSM files, write output
#-------------------------------------------------- 
my $filecount = 0;
my $faulty = 0;
my $current_fh;

for my $chainid (@shuffled_protein_ids) {
    my ($id, $chain) = split /:/, $chainid;

    my $dssp_file = "$dssp_dir/" . (substr $id, 1, 2) . "/pdb$id.dssp";
    my $pssm_file = "$pssm_dir/$id:$chain.pssm";

    unless (-e $dssp_file) {
        warn "$dssp_file does not exist\n" unless -e $dssp_file;
        $faulty++;
        next;
    }
    unless (-e $pssm_file) {
        warn "$pssm_file does not exist\n" unless -e $pssm_file;
        $faulty++;
        next;
    }

    say sprintf("Parsing %s %s (%d/%d)", $dssp_file, $pssm_file, ++$filecount, scalar(@shuffled_protein_ids));

#--------------------------------------------------
# DSSP
#-------------------------------------------------- 
    my $dssp_parser = Reprof::Parser::Dssp->new($dssp_file);

    my $res = $dssp_parser->get_res($chain);
    my $ss = $dssp_parser->get_ss($chain);
    my $acc = $dssp_parser->get_acc($chain);

#--------------------------------------------------
# PSSM and output
#-------------------------------------------------- 
    my $pssm_parser = Reprof::Parser::Pssm->new($pssm_file);
    my $pssm_pc = $pssm_parser->get_pc;
    my $pssm_norm = $pssm_parser->get_normalized;
    my $pssm_info = $pssm_parser->get_info;
    my $pssm_weight = $pssm_parser->get_weight;

#--------------------------------------------------
# IMPLICIT FEATURES
#-------------------------------------------------- 
    my $featurefactory = Reprof::Tools::Featurefactory->new($res);
    my $feat_loc = $featurefactory->get_loc;
    my $feat_polarity = $featurefactory->get_polarity;
    my $feat_charge = $featurefactory->get_charge;

    for my $mode (@modes) {
        for my $submode (@submodes) {

            $current_fh = shift @{$out_fhs->{$mode}{$submode}};
            push @{$out_fhs->{$mode}{$submode}}, $current_fh;

            say $current_fh "ID $chainid";
            foreach my $pos (0 .. scalar @{$res} - 1) {
                print $current_fh "DP\t";
                print $current_fh $pos."\t";
                print $current_fh $res->[$pos]."\t";
                print $current_fh $ss->[$pos]."\t";
                print $current_fh (sprintf "%.2f", $acc->[$pos])."\t";
                my $joined_pssm;
                if ($submode eq "norm") {
                    $joined_pssm = join "\t", @{$pssm_norm->[$pos]};
                }
                elsif ($submode eq "pc") {
                    $joined_pssm = join "\t", @{$pssm_pc->[$pos]};
                }
                elsif ($submode eq "both") {
                    $joined_pssm = join "\t", @{$pssm_norm->[$pos]}, @{$pssm_pc->[$pos]};
                }
                print $current_fh "$joined_pssm\t";
                print $current_fh $pssm_info->[$pos]."\t";
                print $current_fh $pssm_weight->[$pos]."\t";
                print $current_fh $feat_loc->[$pos]."\t";
                print $current_fh $feat_polarity->[$pos]."\t";
                print $current_fh $feat_charge->[$pos]."\t";
                if ($mode eq 'ss') {
                    my $joined_ss = join "\t", @{convert_ss($ss->[$pos], 'profile')};
                    say $current_fh $joined_ss; 
                }
                elsif ($mode eq 'acc') {
                    say $current_fh $acc->[$pos];
                }
            }
        }
    }
}

#--------------------------------------------------
# Closing filehandles
#-------------------------------------------------- 
foreach my $mode (@modes) {
    foreach my $submode (@submodes) {
        foreach my $fh (@{$out_fhs->{$mode}{$submode}}) {
            close $fh;
        }
    }
}
say "$faulty faulty ids...";
