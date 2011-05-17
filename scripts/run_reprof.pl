#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use Data::Dumper;

use Reprof::Tools::Converter qw(convert_ss convert_id);
use Reprof::Tools::Set;
use Reprof::Tools::Measure;
use Reprof::Tools::Featurefactory;
use Reprof::Parser::Set;
use Reprof::Parser::Pssm;
use Reprof::Parser::Dssp;
use Reprof::Parser::Fasta;
use Reprof::Methods::Fann qw(run_nn);
use Reprof::Methods::Jury qw(jury_sum jury_avg jury_majority);
use AI::FANN;

my $ssseqnet_file = "/mnt/project/reprof/data/nets/tseq.tr1.ct2.te3.w19.h240.lr0.01.lm0.1.net";
my $ssstrucnet_file = "/mnt/project/reprof/data/nets/tstruc2.tr11.ct12.te13.w29.h185.lr0.01.lm0.1.net";

#my $ssseqnet_file = "/mnt/project/reprof/data/nets/tssseq.tr2.ct3.te1.w17.h245.lr0.01.lm0.1.net";
#my $ssstrucnet_file = "/mnt/project/reprof/data/nets/tssstruc2.tr22.ct23.te21.w23.h185.lr0.01.lm0.1.net";

#my $ssseqnet_file = "/mnt/project/reprof/data/nets/tssseq.tr3.ct1.te2.w17.h225.lr0.01.lm0.1.net";
#my $ssstrucnet_file = "/mnt/project/reprof/data/nets/tssstruc2.tr33.ct31.te32.w25.h115.lr0.01.lm0.1.net";

#my $ssseqnet_file = "/mnt/project/reprof/data/nets/tssseq.tr3.ct1.te2.w17.h225.lr0.01.lm0.1.net";
#my $ssstrucnet_file = "/mnt/project/reprof/data/nets/tssstruc2.tr33.ct31.te32.w25.h115.lr0.01.lm0.1.net";

#my $ssseqnet_file = "/mnt/project/reprof/data/nets/tssseq.tr3.ct1.te2.w17.h225.lr0.01.lm0.1.net";
#my $ssstrucnet_file = "/mnt/project/reprof/data/nets/tssstruc2.tr33.ct31.te32.w25.h115.lr0.01.lm0.1.net";

my $accseqnet_file = "/mnt/project/reprof/tyacc.stseq.tr1.ct2.te3.w9.h15.lr0.01.lm0.1.net";
my $accstrucnet_file = "/mnt/project/reprof/accstruc.w11.net";

my $fasta_glob;
my $pssm_glob;
my $dssp;
my $set_file;
my $ext_out;

GetOptions( 
    'ssseq=s'     =>  \$ssseqnet_file,
    'ssstruc=s'        =>   \$ssstrucnet_file,
    'accseq=s'     =>  \$accseqnet_file,
    'accstruc=s'        =>   \$accstrucnet_file,
    'fasta=s'        =>   \$fasta_glob,
    'pssm=s'        =>   \$pssm_glob,
    'set=s'        =>   \$set_file,
    'dssp'        =>   \$dssp,
    'ext'        =>   \$ext_out
);

unless (defined $pssm_glob || defined $fasta_glob || -e $set_file) {
    say join "\n",
        "Usage:",
        "$0 -pssm PSSM_FILEGLOB [-dssp]";
    exit 0;
}

my $ss_available = 0;

my $ssseq_set = Reprof::Tools::Set->new;
my ($ssseqwin) = ($ssseqnet_file =~ m/\.w(\d+)\./);
my ($ssstrucwin) = ($ssstrucnet_file =~ m/\.w(\d+)\./);

my $ssseqnn = AI::FANN->new_from_file($ssseqnet_file);
my $ssstrucnn = AI::FANN->new_from_file($ssstrucnet_file);

my $accseq_set = Reprof::Tools::Set->new;
my ($accseqwin) = ($accseqnet_file =~ m/\.w(\d+)\./);
my ($accstrucwin) = ($accstrucnet_file =~ m/\.w(\d+)\./);

my $accseqnn = AI::FANN->new_from_file($accseqnet_file);
my $accstrucnn = AI::FANN->new_from_file($accstrucnet_file);

#--------------------------------------------------
# input 
#-------------------------------------------------- 
my $descriptions;
my $ss_outs;
my $acc_outs;
if (defined $pssm_glob) {
    #--------------------------------------------------
    # pssm 
    #-------------------------------------------------- 
    my @pssm_files = glob $pssm_glob;
    say "Found ".(scalar @pssm_files)." files, parsing them";

    my $count = 0;
    foreach my $pssm_file (@pssm_files) {
        $count++;
        #--------------------------------------------------
        # guess id 
        #-------------------------------------------------- 
        my $id = convert_id($pssm_file, 'pdbchain') // $count;

        #--------------------------------------------------
        # parse pssm file 
        #-------------------------------------------------- 
        my $pssm_parser = Reprof::Parser::Pssm->new($pssm_file);

        my $res = $pssm_parser->get_res;
        my $profile = $pssm_parser->get_normalized;
        my $info = $pssm_parser->get_info;
        my $weight = $pssm_parser->get_weight;

        #--------------------------------------------------
        # create additional features 
        #-------------------------------------------------- 
        my $featurefactory = Reprof::Tools::Featurefactory->new($res);
        my $feat_loc = $featurefactory->get_loc;
        my $feat_polarity = $featurefactory->get_polarity;
        my $feat_charge = $featurefactory->get_charge;

        #--------------------------------------------------
        # trie to quess and parse dssp file if option is set 
        #-------------------------------------------------- 
        my $ss;
        my $acc;
        if (defined $dssp) {
            my $shortid = convert_id($id, 'pdb');
            my $chain = (split ':', $id)[1];

            my $dssp_file = "/mnt/project/rost_db/data/dssp/".(substr $shortid, 1, 2)."/pdb$shortid.dssp";
            if (-e $dssp_file) {
                my $dssp_parser = Reprof::Parser::Dssp->new($dssp_file);
                $ss = $dssp_parser->get_ss($chain);
                $acc = $dssp_parser->get_acc($chain);
            }
        }

        #--------------------------------------------------
        # accumulate descriptions/features/outputs 
        #-------------------------------------------------- 
        foreach my $pos (0 .. scalar @$res - 1) {
            my $desc;
            my $feat;
            my $ssout;
            my $accout;

            # descriptions
            push @$desc, $id, $pos, $res->[$pos];

            # features
            push @$feat, @{$profile->[$pos]}, $info->[$pos], $weight->[$pos], $feat_loc->[$pos], $feat_polarity->[$pos], $feat_charge->[$pos];

            # outputs
            if (defined $ss) {
                push @$ssout, @{convert_ss($ss->[$pos], 'profile')};
            }
            else {
                $ssout = [];
            }
            if (defined $acc) {
                push @$accout, $acc->[$pos];
            }
            else {
                $accout = [];
            }

            push @$descriptions, $desc;
            push @$ss_outs, $ssout;
            push @$acc_outs, $accout;

            $ssseq_set->add($id, [], $feat, $ssout);
            $accseq_set->add($id, [], $feat, $accout);
        }
    }
}
elsif (defined $fasta_glob) {
    #--------------------------------------------------
    # TODO 
    # parse fasta etc.
    #-------------------------------------------------- 
}
elsif (defined $set_file) {
    #--------------------------------------------------
    # TODO
    # parse setfile if given 
    #-------------------------------------------------- 
}

#--------------------------------------------------
# sssequence nn 
#-------------------------------------------------- 
say "Running sssequence nn";
my $ssseq_measure = Reprof::Tools::Measure->new(3);
$ssseq_set->win($ssseqwin);
my $ssseq_results = run_nn($ssseqnn, $ssseq_set, $ssseq_measure);


#--------------------------------------------------
# ssstructure nn 
#-------------------------------------------------- 
say "Creating ssstructure nn input";
my $ssstruc_set = Reprof::Tools::Set->new;
my $pos = 0;
while (my $dp = $ssseq_set->next_dp) {
    $ssstruc_set->add($dp->[4], [], $ssseq_results->[$pos], $dp->[2]);

    ++$pos;
}

say "Running ssstructure nn";
my $ssstruc_measure = Reprof::Tools::Measure->new(3);
$ssstruc_set->win($ssstrucwin);
my $ssstruc_results = run_nn($ssstrucnn, $ssstruc_set, $ssstruc_measure);

#--------------------------------------------------
# accsequence nn 
#-------------------------------------------------- 
say "Running accsequence nn";
my $accseq_measure = Reprof::Tools::Measure->new(1);
$accseq_set->win($accseqwin);
my $accseq_results = run_nn($accseqnn, $accseq_set, $accseq_measure);

#--------------------------------------------------
# accstructure nn 
#-------------------------------------------------- 
say "Creating accstructure nn input";
my $accstruc_set = Reprof::Tools::Set->new;
$pos = 0;
while (my $dp = $accseq_set->next_dp) {
    $accstruc_set->add($dp->[4], [], $accseq_results->[$pos], $dp->[2]);

    ++$pos;
}

say "Running accstructure nn";
my $accstruc_measure = Reprof::Tools::Measure->new(1);
$accstruc_set->win($accstrucwin);
my $accstruc_results = run_nn($accstrucnn, $accstruc_set, $accstruc_measure);
#--------------------------------------------------
# output 
#-------------------------------------------------- 
say "#nr\tres\tssseq\tssstr\taccseq\taccstr\tssdssp\taccdssp";
$pos = 0;
my $last_id = "iMaGINarY superProTEiN";
foreach my $desc (@$descriptions) {
    if ($last_id ne $desc->[0]) {
        $last_id = $desc->[0];
        say "ID $last_id";
    }

    # desc
    print join "\t",
          ((@{$desc})[1 .. scalar @$desc - 1]);

    # ss
    print "\t", join "\t", 
          convert_ss($ssseq_results->[$pos]), 
          convert_ss($ssstruc_results->[$pos]);

    # acc
    printf "\t%.3f\t%.3f",
          @{$accseq_results->[$pos]}, 
          @{$accstruc_results->[$pos]};

    if (defined $dssp) {
        print "\t", join "\t", 
              convert_ss($ss_outs->[$pos]),
              @{$acc_outs->[$pos]};
    }

    if ($ext_out) {
    print "\t", join "\t", 
          (sprintf "%.1f\t%.1f\t%.1f", @{$ssseq_results->[$pos]}),
          (sprintf "%.1f\t%.1f\t%.1f", @{$ssstruc_results->[$pos]});
    }

    print "\n";

    ++$pos;
}

if (defined $dssp) {
            printf "#SSSEQ   Q3:%.1f QL:%.1f QH:%.1f QE:%.3f\n",
                   $ssseq_measure->Q3 * 100,
                   $ssseq_measure->Q_i(0) * 100,
                   $ssseq_measure->Q_i(1) * 100,
                   $ssseq_measure->Q_i(2) * 100;
            printf "#SSSTRUC Q3:%.1f QL:%.1f QH:%.1f QE:%.1f\n",
                   $ssstruc_measure->Q3 * 100,
                   $ssstruc_measure->Q_i(0) * 100,
                   $ssstruc_measure->Q_i(1) * 100,
                   $ssstruc_measure->Q_i(2) * 100;
            printf "#ACCSEQ   E:%.3f\n", $accseq_measure->mse;
            printf "#ACCSTRUC E:%.3f\n", $accstruc_measure->mse;
}
