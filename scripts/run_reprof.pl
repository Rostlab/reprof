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
use Reprof::Methods::Jury qw(jury_sum jury_avg jury_majority);
use AI::FANN;

my $seqnet_glob;
my $strucnet_glob;
my $fasta_file;
my $pssm_file;
my $dssp_file;
my $chain;
my $set_file;

GetOptions( 
    'seqnets=s'     =>  \$seqnet_glob,
    'strucnets=s'   =>  \$strucnet_glob,
    'pssm=s'        =>  \$pssm_file,
    'fasta=s'       =>  \$fasta_file,
    'dssp=s'        =>  \$dssp_file,
    'chain=s'       =>  \$chain,
    'set=s'        =>   \$set_file
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
elsif (defined $fasta_file) {
    # parse FASTA
}
elsif (defined $set_file) {
    # parse SET
}

my $dssp_ss;
if (defined $dssp_file && defined $chain) {
    my $dssp = Reprof::Parser::Dssp->new($dssp_file);

    $dssp_ss = $dssp->get_fields($chain, 'ss');
}

#--------------------------------------------------
# Create set
#-------------------------------------------------- 
my $set = Reprof::Tools::Set->new;
$set->add(\@descs, \@features, \@outputs);

#--------------------------------------------------
# Do nns
#-------------------------------------------------- 
say "Sequence networks:";

my @seq_resultsets;
my $seq_count = 0;
foreach my $file (glob $seqnet_glob) {
    $file =~ m/\.w(\d+)\./;
    $set->win($1);
    my $nn = AI::FANN->new_from_file($file);
    
    my $preds = run_nn($nn, $set);
    say "SEQ_$seq_count: " . pretty_prediction($preds);

    my $result_set = Reprof::Tools::Set->new;
    $result_set->add([], [$preds], []);
    push @seq_resultsets, $result_set;

    $seq_count++;
}

#--------------------------------------------------
# Do structure nns
#-------------------------------------------------- 
say "\nStructure networks:";
my @struc_results;
my $struc_count = 0;
foreach my $file (glob $strucnet_glob) {
    $file =~ m/\.w(\d+)\./;
    my $nn = AI::FANN->new_from_file($file);
    
    foreach my $seq_set (@seq_resultsets) {
        $seq_set->win($1);
        
        my $preds = run_nn($nn, $seq_set);
        say "STR_$struc_count: " . pretty_prediction($preds);

        push @struc_results, $preds;
        $struc_count++;
    }
}

say "\nJury decision:";
my $res_sum = jury_sum(\@struc_results);
say "J_SUM: " . pretty_prediction($res_sum);

my $res_majority = jury_majority(\@struc_results);
say "J_MAJ: " . pretty_prediction($res_majority);

my $res_avg = jury_avg(\@struc_results);
say "J_AVG: " . pretty_prediction($res_avg, "J_AVG");

if (defined $dssp_ss) {
    print "\nDSSP : ";
    foreach my $res (@{$dssp_ss->[0]}) {
        print $res;
    }
    say "";
}

sub pretty_prediction {
    my $prediction = shift;
    
    my $result = "";
    foreach my $res (@$prediction) {
        $result .=  convert_ss($res);
    }

    return $result;
}


