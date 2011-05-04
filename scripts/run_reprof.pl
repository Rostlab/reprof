#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Data::Dumper;

use Reprof::Tools::Converter qw(convert_ss);
use Reprof::Tools::Set;
use Reprof::Tools::Measure;
use Reprof::Parser::Pssm;
use Reprof::Parser::Dssp;
use Reprof::Parser::Fasta;
use Reprof::Methods::Fann qw(run_nn);
use AI::FANN;

my $seqnet_glob;
my $strucnet_glob;
my $fasta_file;
my $pssm_file;
my $dssp_file;

GetOptions( 
    'seqnets=s'     =>  \$seqnet_glob,
    'strucnets=s'   =>  \$strucnet_glob,
    'pssm=s'        =>  \$pssm_file,
    'fasta=s'       =>  \$fasta_file,
    'dssp=s'        =>  \$dssp_file
);

#--------------------------------------------------
# Parse files
#-------------------------------------------------- 
my @descs;
my @features;
my @outputs;

if (defined $pssm_file) {
    my $pssm = Reprof::Parser::Pssm->new($pssm_file);
    push @descs, @{$pssm->get_fields(qw(pos res))};
    push @features, @{$pssm->get_fields(qw(norm_score info weight loc))};
}
else {
    # parse FASTA
}

if (defined $dssp_file) {
    # parse DSSP
}

#--------------------------------------------------
# Create set
#-------------------------------------------------- 
my $set = Reprof::Tools::Set->new;
$set->add(\@descs, \@features, \@outputs);

#--------------------------------------------------
# Do nns
#-------------------------------------------------- 
my @seq_resultsets;
foreach my $file (glob $seqnet_glob) {
    $file =~ m/\.w(\d+)\./;
    $set->win($1);
    my $nn = AI::FANN->new_from_file($file);
    
    my $preds = run_nn($nn, $set);
    say "\n$file";
    foreach my $pred (@$preds) {
        print convert_ss($pred);
    }
    say "";

    my $result_set = Reprof::Tools::Set->new;
    $result_set->add([], [$preds], []);
    push @seq_resultsets, $result_set;
}

#--------------------------------------------------
# Do structure nns
#-------------------------------------------------- 
my @struc_resultsets;
foreach my $file (glob $strucnet_glob) {
    $file =~ m/\.w(\d+)\./;
    my $nn = AI::FANN->new_from_file($file);
    
    foreach my $seq_set (@seq_resultsets) {
        $seq_set->win($1);
        
        my $preds = run_nn($nn, $seq_set);
        foreach my $pred (@$preds) {
            print convert_ss($pred);
        }
        say "";

        my $result_set = Reprof::Tools::Set->new;
        $result_set->add([], [$preds], []);
        push @struc_resultsets, $result_set;
    }
}

#say Dumper(\@struc_resultsets);
