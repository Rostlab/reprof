#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use List::Util qw(sum);

use Reprof::Parser::fasta;
use Reprof::Parser::blastPsiMat;
use AI::FANN;

my @amino_acids = ( 'A', 'R', 'N', 'D', 'C', 'Q', 'E', 'G', 'H', 'I', 'L', 'K', 'M', 'F', 'P', 'S', 'T', 'W', 'Y', 'V', );

my $fasta_file;
my $blastPsiMat_file;

my $fasta_mode = 0;
my $mutation_mode = 0;

my $out_file;
my $sec_nn_file = "/mnt/project/reprof/runs/final/u/87/nntrain.model";
my $acc_nn_file = "/mnt/project/reprof/runs/final/a/58/nntrain.model";

GetOptions(
    'fasta|f=s'         => \$fasta_file,
    'blastPsiMat|b=s'   => \$blastPsiMat_file,
    'fmode=s'      => \$fasta_mode,
    'mmode=s'      => \$mutation_mode,

    'out|o=s'           => \$out_file,
);

#--------------------------------------------------
# print usage if not enough parameters
#-------------------------------------------------- 
if (!-e $fasta_file) {
    die "rtfc...\n";
}

if (! defined $out_file) {
    my @split = split /\./, $fasta_file;
    my @split_sub = @split[0 .. scalar @split - 2];
    $out_file = join "", @split_sub, ".reprof";
    while (-e $out_file) {
        $out_file .= ".copy";
    }
}

#--------------------------------------------------
# load neural networks 
#-------------------------------------------------- 
my $sec_nn = AI::FANN->new_from_file($sec_nn_file);
my $acc_nn = AI::FANN->new_from_file($acc_nn_file);

#--------------------------------------------------
# parse files 
#-------------------------------------------------- 
my $fasta_parser = Reprof::Parser::fasta->new($fasta_file);
my $blastPsiMat_parser = Reprof::Parser::blastPsiMat->new($blastPsiMat_file);
my $chain_length = ($fasta_parser->length())[0];
my @sequence = $fasta_parser->residue;
say join "", @sequence;
say scalar @sequence;

my $features_sec_ori;
my $features_acc_ori;
if (-e $blastPsiMat_file && !$mutation_mode) {
    $features_sec_ori = [
        [[ $fasta_parser->aa_composition ],      1], 
        [[ $fasta_parser->length_4state ],       1], 
        [[ $fasta_parser->distanceN ],           1], 
        [[ $fasta_parser->distanceC ],           1], 
        [[ $blastPsiMat_parser->normalized ],    17], 
        [[ $fasta_parser->in_sequence_bit ],     17], 
        [[ $blastPsiMat_parser->info ],          17], 
        [[ $blastPsiMat_parser->weight ],        17], 
    ];
    $features_acc_ori = [
        [[ $fasta_parser->aa_composition ],      1], 
        [[ $fasta_parser->length_4state ],       1], 
        [[ $fasta_parser->distanceN ],           1], 
        [[ $fasta_parser->distanceC ],           1], 
        [[ $blastPsiMat_parser->normalized ],    11], 
        [[ $fasta_parser->in_sequence_bit ],     11], 
        [[ $blastPsiMat_parser->info ],          11], 
        [[ $blastPsiMat_parser->weight ],        11], 
    ];
}
else {
    $features_sec_ori = [
        [[ $fasta_parser->aa_composition ],     1], 
        [[ $fasta_parser->length_4state ],      1], 
        [[ $fasta_parser->distanceN ],          1], 
        [[ $fasta_parser->distanceC ],          1], 
        [[ $fasta_parser->profile ],            17], 
        [[ $fasta_parser->in_sequence_bit ],    17], 
        [[ map {0} (1 .. $chain_length) ],      17], 
        [[ map {0} (1 .. $chain_length) ],      17], 
    ];
    $features_acc_ori = [
        [[ $fasta_parser->aa_composition ],     1], 
        [[ $fasta_parser->length_4state ],      1], 
        [[ $fasta_parser->distanceN ],          1], 
        [[ $fasta_parser->distanceC ],          1], 
        [[ $fasta_parser->profile ],            11], 
        [[ $fasta_parser->in_sequence_bit ],    11], 
        [[ map {0} (1 .. $chain_length) ],      11], 
        [[ map {0} (1 .. $chain_length) ],      11], 
    ];
}

my $inputs_sec_ori = create_inputs($features_sec_ori);
my $inputs_acc_ori = create_inputs($features_acc_ori);

my $sec_ori = run_network($sec_nn, $inputs_sec_ori);
my $acc_ori = run_network($acc_nn, $inputs_acc_ori);

my $mutations;
if ($mutation_mode) {
    foreach my $pos (0 .. $chain_length - 1) {
        my $current_res = $sequence[$pos];
        foreach my $mut_aa (@amino_acids) {
            if ($current_res ne $mut_aa) {
                my @mut_seq = @sequence;
                $mut_seq[$pos] = $mut_aa;
                my $mut_sequence_string = join "", @mut_seq;
                my $fasta_parser = Reprof::Parser::fasta->new_sequence($mut_sequence_string);

                my $sec_max_win = 17;
                my $features_sec_mut = [
                    [[ $fasta_parser->aa_composition ],     1], 
                    [[ $fasta_parser->length_4state ],      1], 
                    [[ $fasta_parser->distanceN ],          1], 
                    [[ $fasta_parser->distanceC ],          1], 
                    [[ $fasta_parser->profile ],            17], 
                    [[ $fasta_parser->in_sequence_bit ],    17], 
                    [[ map {0} (1 .. $chain_length) ],      17], 
                    [[ map {0} (1 .. $chain_length) ],      17], 
                ];
                my $acc_max_win = 11;
                my $features_acc_mut = [
                    [[ $fasta_parser->aa_composition ],     1], 
                    [[ $fasta_parser->length_4state ],      1], 
                    [[ $fasta_parser->distanceN ],          1], 
                    [[ $fasta_parser->distanceC ],          1], 
                    [[ $fasta_parser->profile ],            11], 
                    [[ $fasta_parser->in_sequence_bit ],    11], 
                    [[ map {0} (1 .. $chain_length) ],      11], 
                    [[ map {0} (1 .. $chain_length) ],      11], 
                ];

                my $inputs_sec_mut = create_inputs($features_sec_mut);
                my $inputs_acc_mut = create_inputs($features_acc_mut);

                my $sec_from;
                my $sec_to;
                my $acc_from;
                my $acc_to;

                my $sec_ori_copy;

                #my $sec_mut = run_network($sec_nn, $inputs_sec_mut);
                #my $acc_mut = run_network($acc_nn, $inputs_acc_mut);

                #$mutations->{$pos}{$current_res}{$mut_aa} = { 
                #sec         => $sec_mut,
                #acc         => $acc_mut,
                #};
            }
        }
    }
}

sub create_inputs {
    my $features = shift;
    my $inputs;
    foreach (1 .. $chain_length) {
        push @$inputs, [];
    }

    foreach my $feature (@$features) {
        my ($current_data, $window) = @$feature;


        foreach my $center (0 .. $chain_length - 1) {
            my $win_start = $center - ($window - 1) / 2;
            my $win_end = $center + ($window - 1) / 2;

            foreach my $iter ($win_start .. $win_end) {
                if ($iter < 0 || $iter >= $chain_length) {
                    if (ref $current_data->[$center]) {
                        push @{$inputs->[$center]}, (map {0} @{$current_data->[$center]});
                    }
                    else {
                        push @{$inputs->[$center]}, 0;
                    }
                }
                else {
                    if (ref $current_data->[$iter]) {
                        push @{$inputs->[$center]}, @{$current_data->[$iter]};
                    }
                    else {
                        push @{$inputs->[$center]}, $current_data->[$iter];
                    }
                }
            }
        }
    }
    return $inputs;
}

sub run_network {
    my ($nn, $inputs, $from, $to) = @_;
    if (! defined $from) {
        $from = 0;
    }
    if (! defined $to) {
        $to = scalar @$inputs - 1;
    }
    my $outputs;
    foreach my $i ($from .. $to) {
        push @$outputs, $nn->run($inputs->[$i]);
    }

    return $outputs;
}

#--------------------------------------------------
# output 
#-------------------------------------------------- 
#--------------------------------------------------
# my $sec_converter = {
#     H => { number => 0, oneletter   => 'H' },
#     E => { number => 1, oneletter   => 'E' },
#     L => { number => 2, oneletter   => 'L' },
#     0 => { number => 0, oneletter   => 'H' },
#     1 => { number => 1, oneletter   => 'E' },
#     2 => { number => 2, oneletter   => 'L' },
# };
# 
# my $acc_converter = {
#     b => { two => 0, three   => 0 },
#     i => { two => 0, three   => 1 },
#     e => { two => 1, three   => 2 },
# };
# 
# sub max_pos {
#     my ($array) = @_;
# 
#     my $mpos = 0;
#     foreach my $pos (1 .. scalar @$array - 1) {
#         if ($array->[$pos] > $array->[$mpos]) {
#             $mpos = $pos;
#         }
#     }
# 
#     return $mpos;
# }
# 
# sub acc_ten2rel {
#     my ($accs) = @_;
#     my $mpos = max_pos $accs;
#     return int( (($mpos * $mpos) + (($mpos + 1) * ($mpos + 1))) / 2 );
# }
# 
# sub acc_rel2three {
#     my ($acc) = @_;
#     
#     if ($acc >= 36) {
#         return 'e';
#     }
#     elsif ($acc >= 9) {
#         return 'i';
#     }
#     else {
#         return 'b';
#     }
# }
# 
# sub acc_rel2two {
#     my ($acc) = @_;
#     
#     if ($acc >= 16) {
#         return 'e';
#     }
#     else {
#         return 'b';
#     }
# }
# 
# sub sec_three2one {
#     my ($array) = @_;
# 
#     my $mpos = max_pos $array;
#     return $sec_converter->{$mpos}->{oneletter};
# 
# }
# 
# sub reliability {
#     my ($array) = @_;
#     
#     my @copy = @$array;
#     my $nr = max_pos \@copy;
#     my $val = $copy[$nr];
#     $copy[$nr] = 0;
#     $nr = max_pos \@copy;
#     my $val2 = $copy[$nr];
# 
#     return int (10 * ($val - $val2));
# }
# 
# #--------------------------------------------------
# # translations
# #-------------------------------------------------- 
# my $nos = [1 .. $chain_length];
# my @res_tmp = $parser{fasta}->residue;
# my $res = \@res_tmp;
# 
# my $sec_raw = $jury;
# my $sec_one = [];
# my $sec_reli = [];
# my $sec_u = [];
# my $sec_b = [];
# my $sec_uu = [];
# my $sec_ub = [];
# my $sec_bu = [];
# my $sec_bb = [];
# 
# my $acc10_raw = $acc_pre->[OUTPUTS];
# my $acc_rel = [];
# my $acc3 = [];
# my $acc2 = [];
# my $acc10_reli = [];
# 
# foreach my $row (0 .. $chain_length - 1) {
#     #--------------------------------------------------
#     # sec 
#     #-------------------------------------------------- 
#     my $sec = $sec_raw->[$row];
#     push @$sec_one, sec_three2one $sec;
#     push @$sec_reli, reliability $sec;
#     push @$sec_u, sec_three2one $seq_unbalanced->[OUTPUTS]->[$row];
#     push @$sec_b, sec_three2one $seq_balanced->[OUTPUTS]->[$row];
#     push @$sec_uu, sec_three2one $struc_unbalanced_seq_unbalanced->[OUTPUTS]->[$row];
#     push @$sec_ub, sec_three2one $struc_unbalanced_seq_balanced->[OUTPUTS]->[$row];
#     push @$sec_bu, sec_three2one $struc_balanced_seq_unbalanced->[OUTPUTS]->[$row];
#     push @$sec_bb, sec_three2one $struc_balanced_seq_balanced->[OUTPUTS]->[$row];
# 
#     #--------------------------------------------------
#     # acc 
#     #-------------------------------------------------- 
#     my $sum = sum @{$acc10_raw->[$row]};
#     foreach my $col (0 .. 9) {
#         $acc10_raw->[$row]->[$col] = $acc10_raw->[$row]->[$col] / $sum;
#     }
# 
#     my $acc = $acc10_raw->[$row];
#     my $rel = acc_ten2rel $acc;
#     push @$acc_rel, $rel;
#     push @$acc3, acc_rel2three $rel;
#     push @$acc2, acc_rel2two $rel;
#     push @$acc10_reli, reliability $acc;
# }
# 
# #--------------------------------------------------
# #  
# #-------------------------------------------------- 
# my @header = (
#     "# ------------------------------------------------------------------------",
#     "# GENERAL FIELDS",
#     "# ------------------------------------------------------------------------",
#     "# No        : number of residue",
#     "# AA        : residue as 1-letter code",
#     "# ------------------------------------------------------------------------",
#     "# SECONDARY STRUCTURE",
#     "# ------------------------------------------------------------------------",
#     "# PHEL      : final predicted secondary structure: H=helix, E=extended (sheet), L=other (loop)",
#     "# RI_S      : reliability index for prediction (0=lo 9=high) Note: for the brief presentation strong predictions marked by '*'",
#     "#",
#     "# PHEL_u    :",
#     "# PHEL_b    :",
#     "# PHEL_uu   :",
#     "# PHEL_ub   :",
#     "# PHEL_bu   :",
#     "# PHEL_bb   :",
#     "# ------------------------------------------------------------------------",
#     "# SOLVENT ACCESSIBILITY",
#     "# ------------------------------------------------------------------------",
#     "# PREL      : final predicted relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
#     "# RI_A      : reliability index for prediction (0=low to 9=high) Note: for the brief presentation strong predictions marked by '*'",
#     "# Pbe       : predicted  relative solvent accessibility (acc) in 2 states: b = 0-16%, e = 16-100%.",
#     "# Pbie      : predicted relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
#     "# --------------------------------------------------------------------------------",
# );
# my @columns = (
#     "No",
#     "AA",
#     "PHEL",
#     "RI_S",
#     "PHEL_u",
#     "PHEL_b",
#     "PHEL_uu",
#     "PHEL_ub",
#     "PHEL_bu",
#     "PHEL_bb",
#     "PREL",
#     "RI_A",
#     "Pbe",
#     "Pbie",
# );
# 
# open FH, ">", $out_file or croak "Could not open $out_file\n";
# say FH join "\n", @header;
# say FH join "\t", @columns;
# foreach my $row (0 .. $chain_length - 1) {
#     say FH join "\t" , $nos->[$row] , $res->[$row] , $sec_one->[$row] , $sec_reli->[$row] , $sec_u->[$row] , $sec_b->[$row] , $sec_uu->[$row] , $sec_ub->[$row] , $sec_bu->[$row] , $sec_bb->[$row] , $acc_rel->[$row] , $acc10_reli->[$row] , $acc3->[$row] , $acc2->[$row];
# }
# close FH;
#-------------------------------------------------- 
