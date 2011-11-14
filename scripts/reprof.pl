#!/usr/bin/perl -w
#--------------------------------------------------
# Predict secondary structure and solvent
# accessibility from sequece
#
# Author: hoenigschmid@rostlab.org
#-------------------------------------------------- 
use lib qw(/mnt/project/reprof/lib/perl/);

use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use List::Util qw(sum);

use AI::FANN;
use POSIX qw(floor);
use Cwd;
use File::Spec;

use Reprof::Parser::fasta;
use Reprof::Parser::blastPsiMat;

# Usage
my $usage = "
NAME:
Reprof

DESCRIPTION:
Secondary structure and solvent accessibility prediction using neural networsk

USAGE:
reprof.pl [-blastPsiMat [query.blastPsiMat] | -fasta [query.fasta]] [OPTIONS]

OPTIONS:
-b, -blastPsiMat
\tInput BLAST PSSM matrix file
-f, -fasta
\tInput (single) FASTA file
-o, -out
\tEither an output file or a directory. If not provided or a directory, the suffix of the input filename is replaced to create an output filename
-mutations
\tEither the keyword \"all\" to predict all possible mutations or a file containing mutations one per line such as \"C12M\" for C is mutated to M on position 12. This mutation code is also attached to the filename using \"_\". An additional file ending \"_ORI\" contains the prediction using no evolutionary information even if the blastPsiMat file was provided
-modeldir
\tDirectory where the model and feature files are stored

EXAMPLE:
reprof.pl -blastPsiMat query.blastPsiMat -out myPrediction.reprof

COMMENT:
The output fileformat is similar to the profRdb format except the \"O\" and \"Ot\" prefixed columns, the introducing comment and the added P10 column.
";

# Parameters
my $fasta_file;
my $blastPsiMat_file;
my $out_file;
my $model_dir = "/mnt/project/reprof/models/";
my $mutation_file;

GetOptions(
    "fasta=s"       => \$fasta_file,
    "blastPsiMat=s" => \$blastPsiMat_file,
    "out=s"         => \$out_file,
    "modeldir=s"    => \$model_dir,
    "mutations=s" => \$mutation_file,
);

# Global variables
my @amino_acids = qw(A R N D C Q E G H I L K M F P S T W Y V);
my @model_names = qw(a u b uu ub bu bb);
my @fasta_model_names = qw(fa fu fb fuu fub fbu fbb);
my %parsers;
my %models;
my %features;
my @mutations;
my $sec_converter = {
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

my $acc_norm = {
    A => 106,  
    B => 160,         # D or N
    C => 135,  
    D => 163, 
    E => 194,
    F => 197, 
    G => 84, 
    H => 184,
    I => 169, 
    K => 205, 
    L => 164,
    M => 188, 
    N => 157, 
    P => 136,
    Q => 198, 
    R => 248, 
    S => 130,
    T => 142, 
    V => 142, 
    W => 227,
    X => 180,         # undetermined (deliberate)
    Y => 222, 
    Z => 196,         # E or Q
    max=>248
};


# Check if either blastPsiMat or fasta file is present
if (defined $blastPsiMat_file && -e $blastPsiMat_file) {
    # Load blastPsiMat file, and create fasta parser from sequence
    $parsers{blastPsiMat} = Reprof::Parser::blastPsiMat->new($blastPsiMat_file);
    my @res = $parsers{blastPsiMat}->res();
    $parsers{fasta} = Reprof::Parser::fasta->new_sequence(join "", @res);
}
elsif (defined $fasta_file && -e $fasta_file) {
    # Load fasta file
    $parsers{fasta} = Reprof::Parser::fasta->new($fasta_file);
}
else {
    # Print usage
    croak $usage;
}

# Load models and feature lists
foreach my $model_name (@model_names, @fasta_model_names) {
    my $model_file = "$model_dir/$model_name.model";
    my $feature_file = "$model_dir/$model_name.features";

    if (! -e $model_file || ! -e $feature_file) {
        croak "*** Could not load model files\n";


    }

    $models{$model_name} = AI::FANN->new_from_file($model_file);
    $features{$model_name} = parse_feature_file($feature_file);
}


# Do prediction for the inputfile
my $chain_length = ($parsers{fasta}->length())[0];
my @sequence = $parsers{fasta}->residue;
my $sequence_string = join "", @sequence;

my $predictions;
if (exists $parsers{blastPsiMat}) {
    $predictions = predict(@model_names);
}
else {
    $predictions = predict(@fasta_model_names);
}

if (! defined $out_file) {
    my ($vol, $dir);
    ($vol, $dir, $out_file) = File::Spec->splitpath($fasta_file || $blastPsiMat_file);
    $out_file =~ s/\.(fasta|blastPsiMat)$//;
    $out_file .= ".reprof";
}
elsif (-d $out_file) {
    my $out_dir = $out_file;
    my ($vol, $dir);
    ($vol, $dir, $out_file) = File::Spec->splitpath($fasta_file || $blastPsiMat_file);
    $out_file =~ s/\.(fasta|blastPsiMat)$//;
    $out_file .= ".reprof";
    $out_file = "$out_dir/$out_file";
}

write_output($out_file, @$predictions);

# Load mutations if any
if (defined $mutation_file) {
    if (-e $mutation_file) {
        open MUTATIONS, "$mutation_file" or croak "*** Could not open mutation file";
        while (my $mutation_string = <MUTATIONS>) {
            chomp $mutation_string;
            if ($mutation_string =~ m/(\w)(\d+)(\w)/) {
                push @mutations, [$1, $2, $3];
            }
        }
        close MUTATIONS;
    }
    elsif ($mutation_file eq "all") {
        my $i = 0;
        foreach my $aa_ori (@sequence) {
            $i++;
            foreach my $aa_mut (@amino_acids) {
                if ($aa_ori ne $aa_mut) {
                    push @mutations, [$aa_ori, $i, $aa_mut];
                }
            }
        }
    }
    else {
        croak "*** Could not find the mutation file, or the keyword\"all\"";
    }

    # Predict original sequence with fasta
    $predictions = predict(@fasta_model_names);
    write_output("$out_file\_ORI", @$predictions);
}

# Do predictions for the mutations
foreach my $mutation (@mutations) {
    my ($aa_ori, $i, $aa_mut) = @$mutation;
    my @sequence_mut = @sequence;
    $sequence_mut[$i - 1] = $aa_mut;
    $parsers{fasta} = Reprof::Parser::fasta->new_sequence(join "", @sequence_mut);
    $predictions = predict(@fasta_model_names);

    write_output("$out_file\_$aa_ori$i$aa_mut", @$predictions);
}

# Subs
sub write_output {
    my ($out_file, $sec_prediction, $acc_prediction) = @_;
    open OUT, ">", $out_file or croak "*** Outputfile could not be created.\n";

    say OUT 
"##General
# No\t: Residue number
# AA\t: Amino acid
##Secondary structure
# PHEL\t: Secondary structure (H = Helix, E = Extended, L = Loop)
# RI_S\t: Reliability index (0 to 9 (most reliable))
# pH\t: Probability helix (0 to 1)
# pE\t: Probability extended (0 to 1)
# pL\t: Probability loop (0 to 1)
##Solvent accessibility
# PACC\t: Absolute
# PREL\t: Relative
# P10\t: Relative in 10 states (0 - 9 (most exposed))
# RI_A\t: Reliability index (0 to 9 (most reliable))
# Pbe\t: Two states (b = buried, e = exposed)
# Pbie\t: Three states (b = buried, e = exposed)
# ";

    say OUT join "\t", qw(No AA PHEL RI_S pH pE pL PACC PREL P10  RI_A Pbe Pbie);
    foreach my $i (0 .. $chain_length - 1) {
        my $No = $i + 1;
        my $AA = ($parsers{fasta}->residue())[$i];

        my $PHEL = sec_three2one($sec_prediction->[$i]);
        my $RI_S = reliability($sec_prediction->[$i]);
        my $PREL = acc_ten2rel($acc_prediction->[$i]);
        my $PACC = acc_rel2abs($PREL, $AA);
        my $P10 = max_pos($acc_prediction->[$i]);
        my $RI_A = reliability($acc_prediction->[$i]);
        my $pH = floor($sec_prediction->[$i][0] * 100);
        my $pE = floor($sec_prediction->[$i][1] * 100);
        my $pL = floor($sec_prediction->[$i][2] * 100);
        my $Pbe = acc_rel2two($PREL);
        my $Pbie = acc_rel2three($PREL);

        say OUT join "\t", $No, $AA, $PHEL, $RI_S, $pH, $pE, $pL, $PACC, $PREL, $P10, $RI_A, $Pbe, $Pbie;
    }
    close OUT;
}

sub parse_feature_file {
    my $file = shift;

    my $inputs = [];
    my $outputs = [];
    open FH, $file or croak "fh error\n";
    while (my $line = <FH>) {
        chomp $line;
        if ($line =~ m/^input\s+(.+)\s+(.+)\s+(\d+)$/) {
            push @$inputs, [$1, $2, $3];
        }
        elsif ($line =~ m/^output\s+(.+)\s+(.+)\s+(\d+)$/) {
            push @$outputs, [$1, $2, $3];
        }
    }
    close FH;

    return [$inputs, $outputs];
}

sub jury {
    my @arrays = @_;

    my @result;

    my $num_arrays = scalar @arrays;
    my $num_pos = scalar @{$arrays[0]->[0]};

    foreach my $i_line (0 .. scalar @{$arrays[0]} - 1) {
        my @tmp = map {0} (1 .. $num_pos);
        foreach my $i_array (0 .. $num_arrays - 1) {
            my $sum = sum @{$arrays[$i_array]->[$i_line]};
            foreach my $i_pos (0 .. $num_pos - 1) {
                $tmp[$i_pos] += $arrays[$i_array]->[$i_line][$i_pos] / $sum;
            }
        }
        foreach my $val (@tmp) {
            $val /= $num_arrays;
        }
        push @result, \@tmp;
    }

    return \@result;
}

sub predict {
    my ($a, $u, $b, $uu, $ub, $bu, $bb) = @_;

    my %outputs;
    $outputs{$a} = run_model($models{$a}, create_inputs($features{$a}->[0]));
    $outputs{$u} = run_model($models{$u}, create_inputs($features{$u}->[0]));
    $outputs{$b} = run_model($models{$b}, create_inputs($features{$b}->[0]));

    $outputs{$uu} = run_model($models{$uu}, create_inputs($features{$uu}->[0], $outputs{$u}));
    $outputs{$ub} = run_model($models{$ub}, create_inputs($features{$ub}->[0], $outputs{$u}));
    $outputs{$bu} = run_model($models{$bu}, create_inputs($features{$bu}->[0], $outputs{$b}));
    $outputs{$bb} = run_model($models{$bb}, create_inputs($features{$bb}->[0], $outputs{$b}));

    my $sec = jury($outputs{$uu}, $outputs{$ub}, $outputs{$bu}, $outputs{$bb});
    return [$sec, $outputs{$a}];
}

sub create_inputs {
    my ($features, $pre_output) = @_;

    my $inputs;
    foreach (1 .. $chain_length) {
        push @$inputs, [];
    }

    foreach my $f (@$features) {
        my ($source, $feature, $window) = @$f;
        my @current_data;
        if ($source eq "output") {
            @current_data = @$pre_output;
        }
        else {
            @current_data = $parsers{$source}->$feature;
        }

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
    return $inputs;
}

sub run_model {
    my ($nn, $inputs) = @_;

    my $outputs;
    foreach my $input (@$inputs) {
        push @$outputs, $nn->run($input);
    }

    return $outputs;
}

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

sub acc_rel2abs {
    my ($acc, $res) = @_;
    return floor(($acc / 100) * $acc_norm->{$res});
}

sub acc_ten2rel {
    my ($accs) = @_;
    my $mpos = max_pos $accs;
    return floor( (($mpos * $mpos) + (($mpos + 1) * ($mpos + 1))) / 2 );
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

sub sec_three2one {
    my ($array) = @_;

    my $mpos = max_pos $array;
    return $sec_converter->{$mpos}->{oneletter};

}

sub reliability {
    my ($array) = @_;
    
    my @copy = @$array;
    my $nr = max_pos \@copy;
    my $val = $copy[$nr];
    $copy[$nr] = 0;
    $nr = max_pos \@copy;
    my $val2 = $copy[$nr];

    return floor(10 * ($val - $val2));
}
