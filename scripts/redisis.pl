#!/usr/bin/perl -w
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
use Reprof::Parser::profRdb;
use Reprof::Parser::profbval;
use Reprof::Parser::mdisorder;
use Reprof::Parser::coils;
use Reprof::Parser::isis;
use Reprof::Parser::bind;

use Reprof::Source::fasta;
use Reprof::Source::blastPsiMat;
use Reprof::Source::profRdb;
use Reprof::Source::profbval;
use Reprof::Source::mdisorder;
use Reprof::Source::coils;
use Reprof::Source::isis;
use Reprof::Source::bind;

my $fasta_file;
my $out_file;

my $l1_nn_file = "/mnt/project/reprof/runs/dna/ppall10/223/nntrain.model";
my $l1_feature_file = "/mnt/project/reprof/runs/dna/ppall10/223/test.setconvert";

my $l2_nn_file = "/mnt/project/reprof/runs/dna/ppall10filter/200/nntrain.model";
my $l2_feature_file = "/mnt/project/reprof/runs/dna/ppall10filter/200/test.setconvert";

GetOptions(
    'fasta=s'   => \$fasta_file,
    'out=s'     => \$out_file,
    'l1n=s'      => \$l1_nn_file,
    'l2n=s'      => \$l2_nn_file,
    'l1f=s'     => \$l1_feature_file,
    'l2f=s'     => \$l2_feature_file,
);

#--------------------------------------------------
# print usage if not enough parameters
#-------------------------------------------------- 
if (!-e $fasta_file) {
    die "rtfc...\n";
}

#--------------------------------------------------
# load neural networks 
#-------------------------------------------------- 
my $l1_nn = AI::FANN->new_from_file($l1_nn_file);
my $l2_nn = AI::FANN->new_from_file($l2_nn_file);

#--------------------------------------------------
# parse files 
#-------------------------------------------------- 
my $fasta_parser = Reprof::Parser::fasta->new($fasta_file);
my $header = $fasta_parser->header;
my $chain_length = ($fasta_parser->length())[0];
my @sequence = $fasta_parser->residue;
my $sequence_string = join "", @sequence;

my %files;
$files{fasta} = $fasta_file;
$files{blastPsiMat} = Reprof::Source::blastPsiMat->predictprotein($header, $sequence_string);
$files{profRdb} = Reprof::Source::profRdb->predictprotein($header, $sequence_string);
$files{profbval} = Reprof::Source::profbval->predictprotein($header, $sequence_string);
$files{mdisorder} = Reprof::Source::mdisorder->predictprotein($header, $sequence_string);
$files{coils} = Reprof::Source::coils->predictprotein($header, $sequence_string);
$files{isis} = Reprof::Source::isis->predictprotein($header, $sequence_string);
$files{bind} = Reprof::Source::bind->reprof($header, $sequence_string);

my %parsers;
$parsers{fasta} = $fasta_parser;
$parsers{blastPsiMat} = Reprof::Parser::blastPsiMat->new($files{blastPsiMat});
$parsers{profRdb} = Reprof::Parser::profRdb->new($files{profRdb});
$parsers{profbval} = Reprof::Parser::profbval->new($files{profbval});
$parsers{mdisorder} = Reprof::Parser::mdisorder->new($files{mdisorder});
$parsers{coils} = Reprof::Parser::coils->new($files{coils});
$parsers{isis} = Reprof::Parser::isis->new($files{isis});
$parsers{bind} = Reprof::Parser::bind->new($files{bind});

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

sub run_network {
    my ($nn, $inputs) = @_;

    my $outputs;
    foreach my $input (@$inputs) {
        push @$outputs, $nn->run($input);
    }

    return $outputs;
}

#--------------------------------------------------
# run, run, run...
#-------------------------------------------------- 

my $l1_features = parse_feature_file($l1_feature_file);
my $l1_inputs = create_inputs($l1_features->[0]);
my $l1_outputs = run_network($l1_nn, $l1_inputs);

my $l2_features = parse_feature_file($l2_feature_file);
my $l2_inputs = create_inputs($l2_features->[0], $l1_outputs);
my $l2_outputs = run_network($l2_nn, $l2_inputs);

$l2_outputs = $l1_outputs;

my @observed_results = $parsers{bind}->bind_2state;
#--------------------------------------------------
# output 
#-------------------------------------------------- 
if (! defined $out_file) {
    my ($vol, $dir);
    ($vol, $dir, $out_file) = File::Spec->splitpath($fasta_file);
    $out_file =~ s/\.fasta$/\.redisis/;
}
elsif (-d $out_file) {
    my $out_dir = $out_file;
    my ($vol, $dir);
    ($vol, $dir, $out_file) = File::Spec->splitpath($fasta_file);
    $out_file =~ s/\.fasta$/\.redisis/;
    $out_file = "$out_dir/$out_file";
}


open OUT, ">", $out_file or croak "fh error\n";

say OUT 
"# no                : residue number
# res               : residue type
# p_binding         : predicted DNA binding residue if 1, 0 otherwise
# score             : score of the prediction (-100 to +100)
# ri                : reliability index for the prediction
# o_binding         : observed DNA binding residue if 1, 0 otherwise
# nn_binding        : neural network output binding
# nn_non_binding    : neural network output non binding ";

say OUT join "\t", "no", "res", "p_binding", "score", "ri", "o_binding", "nn_binding", "nn_non_binding";
foreach my $i (0 .. $chain_length - 1) {
    my $no = $i + 1;
    my $res = $sequence[$i];

    my ($nn_binding, $nn_non_binding) = @{$l2_outputs->[$i]};

    my $score = floor(100 * ($nn_binding - $nn_non_binding));

    my $ri = floor(abs($score) / 10);

    my $p_binding = 0;
    if ($nn_binding - $nn_non_binding > 0) {
        $p_binding = 1;
    }

    my $o_binding = 0;
    if ($observed_results[$i]->[0] == 1) {
        $o_binding = 1;
    }

    say OUT join "\t", $no, $res, $p_binding, $score, $ri, $o_binding, $nn_binding, $nn_non_binding;
}

close OUT;
