#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use List::Util qw(sum);

use Setbench::Parser::fasta;
use Setbench::Parser::pssm;
use Setbench::Parser::psic;
use AI::FANN;

#--------------------------------------------------
# constants 
#-------------------------------------------------- 
use constant {
    PATH        => 0,
    FEATURES    => 1,
    NN          => 2,
    INPUTS      => 3,
    OUTPUTS     => 4,
};

#--------------------------------------------------
# get parameters 
#-------------------------------------------------- 
my $fasta_file;
my $pssm_file;
my $psic_file;

#config direcory (basepath for the networks and features)
my $config_dir = "/mnt/project/reprof/cfg/reprof/";
my $out_file;
my $nn_filename         = "reprof.model";
my $features_filename   = "reprof.features";

GetOptions(
    'fasta|f=s'         => \$fasta_file,
    'blastPsiMat|b=s'   => \$pssm_file,
    'psic|p=s'          => \$psic_file,

    'out|o=s'           => \$out_file,
    'config|c=s'        => \$config_dir,
);

#--------------------------------------------------
# print usage if not enough parameters
#-------------------------------------------------- 
if (!defined $fasta_file || !defined $pssm_file || !defined $psic_file) {
    die "rtfc...\n";
}

#--------------------------------------------------
# create output filename if missing 
#-------------------------------------------------- 
if (!defined $out_file) {
    my ($file, $suffix) = split /\./, $fasta_file;
    $out_file = "$file.reprof";
    while (-e $out_file) {
        $out_file .= ".copy";
    }
}

#--------------------------------------------------
# init network variables
#-------------------------------------------------- 
my $acc_pre                         = ["$config_dir/precise/acc/pre/", undef, [], []];
#my $acc_final                       = ["$config_dir/precise/acc/final/", undef, [], []];
my $seq_unbalanced                  = ["$config_dir/precise/ss/seq/unbalanced/", undef, [], []];
my $seq_balanced                    = ["$config_dir/precise/ss/seq/balanced/", undef, [], []];
my $struc_unbalanced_seq_unbalanced = ["$config_dir/precise/ss/struc/unbalanced/seq_unbalanced/", undef, [], []];
my $struc_unbalanced_seq_balanced   = ["$config_dir/precise/ss/struc/unbalanced/seq_balanced/", undef, [], []];
my $struc_balanced_seq_unbalanced   = ["$config_dir/precise/ss/struc/balanced/seq_unbalanced/", undef, [], []];
my $struc_balanced_seq_balanced     = ["$config_dir/precise/ss/struc/balanced/seq_balanced/", undef, [], []];
#my $ss_final                        = ["$config_dir/precise/ss/final/", undef, [], []];

my $all_nets = [
    $acc_pre, 
    #$acc_final, 
    $seq_unbalanced, 
    $seq_balanced, 
    $struc_unbalanced_seq_unbalanced, 
    $struc_unbalanced_seq_balanced, 
    $struc_balanced_seq_unbalanced, 
    $struc_balanced_seq_balanced,
    #$ss_final,
];

#--------------------------------------------------
# load feature configs 
#-------------------------------------------------- 
foreach my $net (@$all_nets) {
    my $feature_file = "$net->[PATH]/$features_filename";
    open FH, $feature_file or croak "could not open feature file $feature_file\n";
    my @content = <FH>;
    chomp @content;
    close FH;

    my @features;
    foreach my $line (@content) {
        my ($source, $feature, $window) = split /\s+/, $line;
        if (defined $window) {
            push @features, [$source, $feature, $window];
        }
    }

    $net->[FEATURES] = \@features;
}

#--------------------------------------------------
# load neural networks 
#-------------------------------------------------- 
$acc_pre->[NN]                        = AI::FANN->new_from_file("$acc_pre->[PATH]/$nn_filename");
#$acc_final->[NN]                      = AI::FANN->new_from_file("$acc_final->[PATH]/$nn_filename");
$seq_unbalanced->[NN]                 = AI::FANN->new_from_file("$seq_unbalanced->[PATH]/$nn_filename");
$seq_balanced->[NN]                   = AI::FANN->new_from_file("$seq_balanced->[PATH]/$nn_filename");
$struc_unbalanced_seq_unbalanced->[NN]= AI::FANN->new_from_file("$struc_unbalanced_seq_unbalanced->[PATH]/$nn_filename");
$struc_unbalanced_seq_balanced->[NN]  = AI::FANN->new_from_file("$struc_unbalanced_seq_balanced->[PATH]/$nn_filename");
$struc_balanced_seq_unbalanced->[NN]  = AI::FANN->new_from_file("$struc_balanced_seq_unbalanced->[PATH]/$nn_filename");
$struc_balanced_seq_balanced->[NN]    = AI::FANN->new_from_file("$struc_balanced_seq_balanced->[PATH]/$nn_filename");
#$ss_final->[NN]                       = AI::FANN->new_from_file("$ss_final->[PATH]/$nn_filename");


#--------------------------------------------------
# parse files 
#-------------------------------------------------- 
my %parser = (
    fasta   => Setbench::Parser::fasta->new($fasta_file),
    pssm    => Setbench::Parser::pssm->new($pssm_file),
    psic    => Setbench::Parser::psic->new($psic_file),
);
my $chain_length = ($parser{fasta}->length)[0];

#--------------------------------------------------
# first layer - sequence to structure
#-------------------------------------------------- 
foreach my $net ($acc_pre, $seq_unbalanced, $seq_balanced) {
    my $inputs = [];
    foreach (0 .. $chain_length - 1) {
        push @$inputs, [];
    }

    foreach my $line (@{$net->[FEATURES]}) {
        my ($source, $feature, $window) = @$line;

        if ($source eq "output") {
            croak "invalid feature\n";
        }

        my @current_data = $parser{$source}->$feature;

        foreach my $center (0 .. $chain_length - 1) {
            my $win_start = $center - ($window - 1) / 2;
            my $win_end = $center + ($window - 1) / 2;

            foreach my $iter ($win_start .. $win_end) {
                if ($iter < 0 || $iter >= $chain_length) {
                    if (ref $current_data[$center]) {
                        push @{$inputs->[$center]}, (map {0} @{$current_data[$center]});
                    }
                    else {
                        push @{$inputs->[$center]}, 0;
                    }
                }
                else {
                    if (ref $current_data[$iter]) {
                        push @{$inputs->[$center]}, @{$current_data[$iter]};
                    }
                    else {
                        push @{$inputs->[$center]}, $current_data[$iter];
                    }
                }
            }
        }
    }

    $net->[INPUTS] = $inputs;
}

#--------------------------------------------------
# subroutine to run the neural network 
#-------------------------------------------------- 
sub run_network {
    my ($net) = @_;

    my $nn = $net->[NN];
    foreach my $inputs (@{$net->[INPUTS]}) {
        push @{$net->[OUTPUTS]}, $nn->run($inputs);
    }
}

#--------------------------------------------------
# second layer - structure to structure
#-------------------------------------------------- 
foreach my $net ($acc_pre, $seq_unbalanced, $seq_balanced) {
    run_network $net;
}

foreach my $nets (
    [$struc_unbalanced_seq_unbalanced, $seq_unbalanced],
    [$struc_unbalanced_seq_balanced, $seq_balanced],
    [$struc_balanced_seq_unbalanced, $seq_unbalanced],
    [$struc_balanced_seq_balanced, $seq_balanced],
) {
    my ($net, $pre_net) = @$nets;

    my $inputs = [];
    foreach (0 .. $chain_length - 1) {
        push @$inputs, [];
    }

    if (scalar @{$net->[FEATURES]} > 1) {
        croak "invalid feature\n";
    }

    my ($source, $feature, $window) = @{$net->[FEATURES]->[0]};

    my @current_data = @{$pre_net->[OUTPUTS]};

    foreach my $center (0 .. $chain_length - 1) {
        my $win_start = $center - ($window - 1) / 2;
        my $win_end = $center + ($window - 1) / 2;

        foreach my $iter ($win_start .. $win_end) {
            if ($iter < 0 || $iter >= $chain_length) {
                if (ref $current_data[$center]) {
                    push @{$inputs->[$center]}, (map {0} @{$current_data[$center]});
                }
                else {
                    push @{$inputs->[$center]}, 0;
                }
            }
            else {
                if (ref $current_data[$iter]) {
                    push @{$inputs->[$center]}, @{$current_data[$iter]};
                }
                else {
                    push @{$inputs->[$center]}, $current_data[$iter];
                }
            }
        }
    }

    $net->[INPUTS] = $inputs;
}

foreach my $net ($struc_unbalanced_seq_unbalanced, $struc_unbalanced_seq_balanced, $struc_balanced_seq_unbalanced, $struc_balanced_seq_balanced) {
    run_network $net;
}

#--------------------------------------------------
# third layer - jury 
#-------------------------------------------------- 
my $jury;
foreach my $iter (0 .. $chain_length - 1) {
    push @$jury, [0, 0, 0];

    foreach my $net ($seq_unbalanced, $seq_balanced, $struc_unbalanced_seq_unbalanced, $struc_unbalanced_seq_balanced, $struc_balanced_seq_unbalanced, $struc_balanced_seq_balanced) {
        my @outputs = @{$net->[OUTPUTS]->[$iter]};
        my $sum = sum @outputs;

        foreach my $col (0 .. 2) {
            $jury->[$iter]->[$col] += $outputs[$col] / $sum;
        }
    }
}

foreach my $row (0 .. $chain_length - 1) {
    foreach my $col (0 .. 2) {
        $jury->[$row]->[$col] = $jury->[$row]->[$col] / 6;
    }

    my $sum = sum @{$jury->[$row]};
    foreach my $col (0 .. 2) {
        $jury->[$row]->[$col] = $jury->[$row]->[$col] / $sum;
    }
}

#--------------------------------------------------
# fourth layer - acc/ss combination
#-------------------------------------------------- 

### TODO ###

#--------------------------------------------------
# output 
#-------------------------------------------------- 
my $ss_converter = {
    H => { number => 0, oneletter   => 'H' },
    E => { number => 1, oneletter   => 'E' },
    L => { number => 2, oneletter   => 'L' },
    0 => { number => 0, oneletter   => 'H' },
    1 => { number => 1, oneletter   => 'E' },
    2 => { number => 2, oneletter   => 'L' },
};

my $acc_converter = {
    b => { two => 0, three   => 0 },
    i => { two => 0, three   => 1 },
    e => { two => 1, three   => 2 },
};

sub max_pos {
    my ($array) = @_;

    my $mpos = 0;
    foreach my $pos (1 .. scalar @$array - 1) {
        if ($array->[$pos] > $array->[$mpos]) {
            $mpos = $pos;
        }
    }

    return $mpos;
}

sub acc_ten2rel {
    my ($accs) = @_;
    my $mpos = max_pos $accs;
    return int( (($mpos * $mpos) + (($mpos + 1) * ($mpos + 1))) / 2 );
}

sub acc_rel2three {
    my ($acc) = @_;
    
    if ($acc >= 36) {
        return 'e';
    }
    elsif ($acc >= 9) {
        return 'i';
    }
    else {
        return 'b';
    }
}

sub acc_rel2two {
    my ($acc) = @_;
    
    if ($acc >= 16) {
        return 'e';
    }
    else {
        return 'b';
    }
}

sub ss_three2one {
    my ($array) = @_;

    my $mpos = max_pos $array;
    return $ss_converter->{$mpos}->{oneletter};

}

sub reliability {
    my ($array) = @_;
    
    my @copy = @$array;
    my $nr = max_pos \@copy;
    my $val = $copy[$nr];
    $copy[$nr] = 0;
    $nr = max_pos \@copy;
    my $val2 = $copy[$nr];

    return int (10 * ($val - $val2));
}

#--------------------------------------------------
# translations
#-------------------------------------------------- 
my $nos = [1 .. $chain_length];
my @res_tmp = $parser{fasta}->residue;
my $res = \@res_tmp;

my $ss_raw = $jury;
my $ss_one = [];
my $ss_reli = [];
my $ss_u = [];
my $ss_b = [];
my $ss_uu = [];
my $ss_ub = [];
my $ss_bu = [];
my $ss_bb = [];

my $acc10_raw = $acc_pre->[OUTPUTS];
my $acc_rel = [];
my $acc3 = [];
my $acc2 = [];
my $acc10_reli = [];

foreach my $row (0 .. $chain_length - 1) {
    #--------------------------------------------------
    # ss 
    #-------------------------------------------------- 
    my $ss = $ss_raw->[$row];
    push @$ss_one, ss_three2one $ss;
    push @$ss_reli, reliability $ss;
    push @$ss_u, ss_three2one $seq_unbalanced->[OUTPUTS]->[$row];
    push @$ss_b, ss_three2one $seq_balanced->[OUTPUTS]->[$row];
    push @$ss_uu, ss_three2one $struc_unbalanced_seq_unbalanced->[OUTPUTS]->[$row];
    push @$ss_ub, ss_three2one $struc_unbalanced_seq_balanced->[OUTPUTS]->[$row];
    push @$ss_bu, ss_three2one $struc_balanced_seq_unbalanced->[OUTPUTS]->[$row];
    push @$ss_bb, ss_three2one $struc_balanced_seq_balanced->[OUTPUTS]->[$row];

    #--------------------------------------------------
    # acc 
    #-------------------------------------------------- 
    my $sum = sum @{$acc10_raw->[$row]};
    foreach my $col (0 .. 9) {
        $acc10_raw->[$row]->[$col] = $acc10_raw->[$row]->[$col] / $sum;
    }

    my $acc = $acc10_raw->[$row];
    my $rel = acc_ten2rel $acc;
    push @$acc_rel, $rel;
    push @$acc3, acc_rel2three $rel;
    push @$acc2, acc_rel2two $rel;
    push @$acc10_reli, reliability $acc;
}

#--------------------------------------------------
#  
#-------------------------------------------------- 
my @header = (
    "# ------------------------------------------------------------------------",
    "# GENERAL FIELDS",
    "# ------------------------------------------------------------------------",
    "# No        : number of residue",
    "# AA        : residue as 1-letter code",
    "# ------------------------------------------------------------------------",
    "# SECONDARY STRUCTURE",
    "# ------------------------------------------------------------------------",
    "# PHEL      : final predicted secondary structure: H=helix, E=extended (sheet), L=other (loop)",
    "# RI_S      : reliability index for prediction (0=lo 9=high) Note: for the brief presentation strong predictions marked by '*'",
    "#",
    "# PHEL_u    :",
    "# PHEL_b    :",
    "# PHEL_uu   :",
    "# PHEL_ub   :",
    "# PHEL_bu   :",
    "# PHEL_bb   :",
    "# ------------------------------------------------------------------------",
    "# SOLVENT ACCESSIBILITY",
    "# ------------------------------------------------------------------------",
    "# PREL      : final predicted relative solvent accessibility (acc) in 10 states: a value of n (=0-9) corresponds to a relative acc. of between n*n % and (n+1)*(n+1) % (e.g. for n=5: 16-25%).",
    "# RI_A      : reliability index for prediction (0=low to 9=high) Note: for the brief presentation strong predictions marked by '*'",
    "# Pbe       : predicted  relative solvent accessibility (acc) in 2 states: b = 0-16%, e = 16-100%.",
    "# Pbie      : predicted relative solvent accessibility (acc) in 3 states: b = 0-9%, i = 9-36%, e = 36-100%.",
    "# --------------------------------------------------------------------------------",
);
my @columns = (
    "No",
    "AA",
    "PHEL",
    "RI_S",
    "PHEL_u",
    "PHEL_b",
    "PHEL_uu",
    "PHEL_ub",
    "PHEL_bu",
    "PHEL_bb",
    "PREL",
    "RI_A",
    "Pbe",
    "Pbie",
);

open FH, ">", $out_file or croak "Could not open $out_file\n";
say FH join "\n", @header;
say FH join "\t", @columns;
foreach my $row (0 .. $chain_length - 1) {
    say FH join "\t" , $nos->[$row] , $res->[$row] , $ss_one->[$row] , $ss_reli->[$row] , $ss_u->[$row] , $ss_b->[$row] , $ss_uu->[$row] , $ss_ub->[$row] , $ss_bu->[$row] , $ss_bb->[$row] , $acc_rel->[$row] , $acc10_reli->[$row] , $acc3->[$row] , $acc2->[$row];
}
close FH;
