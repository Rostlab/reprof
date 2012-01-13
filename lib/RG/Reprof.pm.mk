=pod

=head1 NAME

RG::Reprof::Reprof - protein secondary structure and accessibility predictor

=head1 SYNOPSIS

use RG::Reprof::Reprof;

=head1 DESCRIPTION

See module commented source for further details.

=head2 Methods

=cut

package RG::Reprof::Reprof;
use strict;
use Carp qw| cluck :DEFAULT |;
use List::Util qw(sum min max);
use POSIX qw(floor);
use File::Spec;
use AI::FANN;

use RG::Reprof::fasta;
use RG::Reprof::blastPsiMat;
#use Perlpred::Parser::fasta;
#use Perlpred::Parser::blastPsiMat;

=pod

=over

=item I<OBJ> RG::Reprof::Reprof->new( model_dir => I<PATH> )

Default model_dir: F<__pkgdatadir__>.

Returns new instance of RG::Reprof::Reprof.

=cut

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = {};
    bless $self, $class;
    $self->_init( @_ );
    return $self;
}

sub               _init
{
  my( $self, %__p ) = @_;
  $self->{model_dir} = $__p{model_dir} || '__pkgdatadir__';
}

# Global variables
# Constants
my @amino_acids = qw(A R N D C Q E G H I L K M F P S T W Y V);
my @model_names = qw(a u b uu ub bu bb);
my @fasta_model_names = qw(fa fu fb fuu fub fbu fbb);

# Convert secondary structure
my $sec_converter = {
    H => { number => 0, oneletter   => 'H' },
    E => { number => 1, oneletter   => 'E' },
    L => { number => 2, oneletter   => 'L' },
    0 => { number => 0, oneletter   => 'H' },
    1 => { number => 1, oneletter   => 'E' },
    2 => { number => 2, oneletter   => 'L' },
};
  
# Convert acc
my $acc_converter = {
    b => { two => 0, three   => 0 },
    i => { two => 0, three   => 1 },
    e => { two => 1, three   => 2 },
};

# Acc normalization values
my $acc_norm = {
    A => 106,  
    B => 160,         
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
    X => 180,        
    Y => 222, 
    Z => 196,       
    max=>248
};
  
=pod

=item I<int> $OBJ->run( B<input_file> => I<PATH>, B<out_file> => I<PATH>, B<mutation_file> => I<PATH>, B<specific_models> => I<hashref>, B<output_func> => I<coderef> )

=over

=item B<out_file> may be a directory.

=item B<mutation_file> may be undefined.

=item B<specific_models> may be undefined.

This is a hash of model and feature files with 'model_name' keys like:

 {
   'fub_model' => '/path/to/model_file',
   'fub_features' => '/path/to/features_file'
 }

Check the module source for the list for model names.

=item I<void> B<output_func>( out_file, sec_pred, acc_pred, sequence ) - function to call when output is ready.

If undefined, the built-in write_output() function is called that prints results to one or more files.  The following positional parameters are passed to this function:

=over

=item out_file

Output file name.

=item sec_pred

Secondary structure prediction, see source for details.

=item acc_pred

Accessibility prediction, see source for details.

=item sequence

Reference to array of residues of input sequence (e.g. [ 'M', 'A', 'G', ... ] ).

=back

=back

=cut
sub               run
{
  #
  my $self = shift( @_ );
  my %__p = ( output_func => \&write_output, @_ );
  
  # Parsers, models and feature lists
  my $parsers = $self->{parsers} = {};    # for convenience
  my %models;
  my %features;
  
  # Globals important for mutation predictions
  my @mutations;                          # Requested mutations
  $self->{max_window} = 0;                # Largest occuring window size
  my $max_window = \($self->{max_window});# for convenience
  my $acc_ori;                            # Original acc prediction from fasta sequence
  my $sec_ori;                            # Original sec prediction from fasta sequence
  my $u_ori;                              # Original unbalanced 1st layer prediction
  my $b_ori;                              # Original balanced 1st layer prediction

  # Check if either blastPsiMat or fasta file is present
  if (defined $__p{input_file} && -e $__p{input_file}) {
      # Try to load blastPsiMat file, and create fasta parser from sequence
      my $tmp_blastPsiMat_parser = RG::Reprof::blastPsiMat->new($__p{input_file});
      my $tmp_fasta_parser = RG::Reprof::fasta->new($__p{input_file});
      if (defined $tmp_blastPsiMat_parser) {
          $parsers->{blastPsiMat} = $tmp_blastPsiMat_parser;
          my @res = $parsers->{blastPsiMat}->res();
          $parsers->{fasta} = RG::Reprof::fasta->new_sequence(join "", @res);
      }
      # Else try to use input as fasta file
      elsif (defined $tmp_fasta_parser) {
          $parsers->{fasta} = $tmp_fasta_parser;
      }
      else {
          # Print usage
          pod2usage(-verbose => 1);
      }
  }
  else { confess("no input file or input file '".( $__p{input_file} || '' )."' does not exist"); }

  my $chain_length = $self->{chain_length} = $parsers->{fasta}->length(); # lkajan: I've decided to make chain_length an instance property so that we do not have to include it in method parameter lists always. However if it ever /changes/ in a method, then that probably should have it in the parameter list, to make the changing code easier to find.
  my $sequence_string = join( "", @{$parsers->{fasta}->residue()} );
  
  # Load models and feature lists
  foreach my $model_name (@model_names, @fasta_model_names) {
      my $model_file;
      my $feature_file;
  
      if (defined $__p{specific_models}->{"${model_name}_model"}) {
          $model_file = $__p{specific_models}->{"${model_name}_model"};
      }
      else {
          $model_file = $self->{model_dir}."/$model_name.model";
      }
  
      if (defined $__p{specific_models}->{"${model_name}_features"}) {
          $feature_file = $__p{specific_models}->{"${model_name}_features"};
      }
      else {
          $feature_file = $self->{model_dir}."/$model_name.features";
      }
  
      if (! -e $model_file || ! -e $feature_file) {
          confess "*** Could not load model files\n";
      }
  
      $models{$model_name} = AI::FANN->new_from_file($model_file);
      $features{$model_name} = $self->parse_feature_file($feature_file);
  }
  
  # Create output filename
  my $out_file = $__p{out_file};
  if (! defined $out_file) {
      my ($vol, $dir);
      ($vol, $dir, $out_file) = File::Spec->splitpath($__p{input_file});
      $out_file =~ s/\.(fasta|blastPsiMat)$//;
      $out_file .= ".reprof";
  }
  elsif (-d $out_file) {
      my $out_dir = $out_file;
      my ($vol, $dir);
      ($vol, $dir, $out_file) = File::Spec->splitpath($__p{input_file});
      $out_file =~ s/\.(fasta|blastPsiMat)$//;
      $out_file .= ".reprof";
      $out_file = "$out_dir/$out_file";
  }
  
  # Do prediction for the inputfile
  if (exists $parsers->{blastPsiMat}) {
      my $a = run_model($models{a}, $self->create_inputs($features{a}->[0], 0, $chain_length - 1 ));
      my $u = run_model($models{u}, $self->create_inputs($features{u}->[0], 0, $chain_length - 1 ));
      my $b = run_model($models{b}, $self->create_inputs($features{b}->[0], 0, $chain_length - 1 ));
  
      my $uu = run_model($models{uu}, $self->create_inputs($features{uu}->[0], 0, $chain_length - 1, pre_output => $u ));
      my $ub = run_model($models{ub}, $self->create_inputs($features{ub}->[0], 0, $chain_length - 1, pre_output => $u ));
      my $bu = run_model($models{bu}, $self->create_inputs($features{bu}->[0], 0, $chain_length - 1, pre_output => $b ));
      my $bb = run_model($models{bb}, $self->create_inputs($features{bb}->[0], 0, $chain_length - 1, pre_output => $b ));
  
      my $sec = jury($uu, $ub, $bu, $bb);
  
      $__p{output_func}($out_file, $sec, $a, $parsers->{fasta}->residue() );
  }
  if (! exists $parsers->{blastPsiMat} || defined $__p{mutation_file}) {
      my $a = run_model($models{fa}, $self->create_inputs($features{fa}->[0], 0, $chain_length - 1));
      my $u = run_model($models{fu}, $self->create_inputs($features{fu}->[0], 0, $chain_length - 1));
      my $b = run_model($models{fb}, $self->create_inputs($features{fb}->[0], 0, $chain_length - 1));
  
      my $uu = run_model($models{fuu}, $self->create_inputs($features{fuu}->[0], 0, $chain_length - 1, pre_output => $u));
      my $ub = run_model($models{fub}, $self->create_inputs($features{fub}->[0], 0, $chain_length - 1, pre_output => $u));
      my $bu = run_model($models{fbu}, $self->create_inputs($features{fbu}->[0], 0, $chain_length - 1, pre_output => $b));
      my $bb = run_model($models{fbb}, $self->create_inputs($features{fbb}->[0], 0, $chain_length - 1, pre_output => $b));
  
      my $sec = jury($uu, $ub, $bu, $bb);
  
      if (! exists $parsers->{blastPsiMat}) {
          $__p{output_func}($out_file, $sec, $a, $parsers->{fasta}->residue() );
      }
      if (defined $__p{mutation_file}) {
          $acc_ori = $a;
          $u_ori = $u;
          $b_ori = $b;
  
          $sec_ori = $sec;
  
          $__p{output_func}("$out_file\_ORI", $sec, $a, $parsers->{fasta}->residue() );
      }
  }
  
  # Load mutations if any
  if (defined $__p{mutation_file}) {
      if (-e $__p{mutation_file}) {
          open MUTATIONS, '<', $__p{mutation_file} or confess "*** Could not open mutation file '$__p{mutation_file}': $!";
          while (my $mutation_string = <MUTATIONS>) {
              chomp $mutation_string;
              if ($mutation_string =~ m/(\w)(\d+)(\w)/) {
                  if (defined $1 && defined $2 && defined $3) {
                      push @mutations, [$1, $2, $3];
                  }
                  else {
                      confess "Error in mutation file: $mutation_string\n";
                  }
              }
          }
          close MUTATIONS;
      }
      elsif ($__p{mutation_file} eq "all") {
          my $i = 0;
          foreach my $aa_ori (@{$parsers->{fasta}->residue()}) {
              $i++;
              foreach my $aa_mut (@amino_acids) {
                  if ($aa_ori ne $aa_mut) {
                      push @mutations, [$aa_ori, $i, $aa_mut];
                  }
              }
          }
      }
      else {
          confess "*** Could not find the mutation file, or the keyword\"all\"";
      }
  }
  
  # Do predictions for the mutations
  my $pre_mut_fasta = $parsers->{fasta};
  foreach my $mutation (@mutations) {
      my ($aa_ori, $i, $aa_mut) = @$mutation;
  
      print "### $aa_ori $i $aa_mut ###\n";
  
      my @sequence_mut = @{$pre_mut_fasta->residue()};
      $sequence_mut[$i - 1] = $aa_mut;
      $parsers->{fasta} = RG::Reprof::fasta->new_sequence(join "", @sequence_mut);
  
      my $seq_from = max((($i - 1) - 1 * $$max_window + 1), 0);
      my $seq_to =   min((($i - 1) + 1 * $$max_window - 1), ($chain_length - 1));
  
      my $struc_from = max((($i - 1) - 2 * $$max_window + 2), 0);
      my $struc_to =   min((($i - 1) + 2 * $$max_window - 2), ($chain_length - 1));
  
      my $a_tmp = run_model($models{fa}, $self->create_inputs($features{fa}->[0], $seq_from, $seq_to));
  
      my $u_tmp = run_model($models{fu}, $self->create_inputs($features{fu}->[0], $seq_from, $seq_to));
      my $b_tmp = run_model($models{fb}, $self->create_inputs($features{fb}->[0], $seq_from, $seq_to));
  
      my $a = [];
      my $u = [];
      my $b = [];
      my $sec;
      foreach my $j (0 .. $chain_length - 1) {
          push @$a, $acc_ori->[$j];
          push @$u, $u_ori->[$j];
          push @$b, $b_ori->[$j];
          push @$sec, $sec_ori->[$j];
      }
  
      my $iter = 0;
      foreach my $i ($seq_from .. $seq_to) {
          $a->[$i] = $a_tmp->[$iter];
          $u->[$i] = $u_tmp->[$iter];
          $b->[$i] = $b_tmp->[$iter];
  
          $iter++;
      }
  
      my $uu = run_model($models{fuu}, $self->create_inputs($features{fuu}->[0], $struc_from, $struc_to, pre_output => $u));
      my $ub = run_model($models{fub}, $self->create_inputs($features{fub}->[0], $struc_from, $struc_to, pre_output => $u));
      my $bu = run_model($models{fbu}, $self->create_inputs($features{fbu}->[0], $struc_from, $struc_to, pre_output => $b));
      my $bb = run_model($models{fbb}, $self->create_inputs($features{fbb}->[0], $struc_from, $struc_to, pre_output => $b));
  
      my $sec_tmp = jury($uu, $ub, $bu, $bb);
  
  
      $iter = 0;
      foreach my $j ($struc_from ..  $struc_to) {
          $sec->[$j] = $sec_tmp->[$iter];
  
          $iter++;
      }
  
      $__p{output_func}("$out_file\_$aa_ori$i$aa_mut", $sec, $a, $parsers->{fasta}->residue() );
  }

  return 0; # 0 for success
}

sub write_output {
    my( $out_file, $sec_prediction, $acc_prediction, $residues ) = @_;
    open OUT, ">", $out_file or confess "*** Outputfile '$out_file' could not be created: $!.";

    print OUT 
"##General
# No\t: Residue number (beginning with 1)
# AA\t: Amino acid
##Secondary structure
# PHEL\t: Secondary structure (H = Helix, E = Extended/Sheet, L = Loop)
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
# Pbie\t: Three states (b = buried, i = intermediate, e = exposed)
# \n";

    print OUT join( "\t", qw(No AA PHEL RI_S pH pE pL PACC PREL P10 RI_A Pbe Pbie) ), "\n";
    my $chain_length = @$residues;
    foreach my $i (0 .. $chain_length - 1) {
        my $No = $i + 1;
        my $AA = $residues->[$i];

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

        print OUT join( "\t", $No, $AA, $PHEL, $RI_S, $pH, $pE, $pL, $PACC, $PREL, $P10, $RI_A, $Pbe, $Pbie ), "\n";
    }
    close OUT;
}

sub parse_feature_file {
    my( $self, $file ) = @_;   

    my $inputs = [];
    my $outputs = [];
    open FH, '<', $file or confess "could not read '$file': $!";
    while (my $line = <FH>) {
        chomp $line;
        if ($line =~ m/^input\s+(.+)\s+(.+)\s+(\d+)$/) {
            push @$inputs, [$1, $2, $3];
            if ($3 > $self->{max_window}) {
                $self->{max_window} = $3;
            }
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

sub create_inputs {
    my( $self, $__features, $from, $to, %__p ) = @_;

    my $inputs;
    foreach ($from .. $to) { push @$inputs, []; }

    foreach my $f (@$__features) {
        my ($source, $feature, $window) = @$f;
        my @current_data;
        if ($source eq "output") {
            @current_data = @{$__p{pre_output}};
        }
        else {
            @current_data = $self->{parsers}->{$source}->$feature;
        }

        foreach my $center ($from .. $to) {
            my $win_start = $center - ($window - 1) / 2;
            my $win_end = $center + ($window - 1) / 2;

            foreach my $iter ($win_start .. $win_end) {
                if ($iter < 0 || $iter >= $self->{chain_length}) {
                    if (ref $current_data[$center]) {
                        push @{$inputs->[$center - $from]}, (map {0} @{$current_data[$center]});
                    }
                    else {
                        push @{$inputs->[$center - $from]}, 0;
                    }
                }
                else {
                    if (ref $current_data[$iter]) {
                        push @{$inputs->[$center - $from]}, @{$current_data[$iter]};
                    }
                    else {
                        push @{$inputs->[$center - $from]}, $current_data[$iter];
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

1;

=pod

=back

=head1 AUTHOR

Original version by Peter Hoenigschmid <hoenigschmid@rostlab.org> and Burkhard Rost.

Some perl module work and documentation by Laszlo Kajan <lkajan@rostlab.org>.

=head1 SEE ALSO

L<http://rostlab.org/>

=cut

# vim:et:ai:ts=2:
