package Reprof::Parser::Pssm;

use strict;
use warnings;
use feature qw(say);
use Data::Dumper;

#--------------------------------------------------
# name:        new
# desc:        creates a new pssm parser object
# args:        filename/path
# return:       parser object ref 
#-------------------------------------------------- 
sub new {
    my ($class, $file) = @_;

    my $self = {
        _file       => $file || warn "No file given to parser\n",
        _pos        => [],
        _res        => [],
        _raw_score  => [],
        _norm_score => [],
        _pc_score   => [],
        _info       => [],
        _weight     => [],
        _loc        => [],
        _gc         => undef,
        _length     => 0
    };

    bless $self, $class;
    $self->_parse;
    return $self;
}

sub _parse {
    my ($self) = @_;

    open PSSM, $self->{_file} or die "Could not open $self->{_file} ...\n";
    my @pssm_cont = grep /^\s*\d+/, (<PSSM>);
    chomp @pssm_cont;
    close PSSM;
    
    my $length = $self->{_length} = scalar @pssm_cont;

    foreach my $line (@pssm_cont) {
        $line =~ s/^\s+//;
        my @split = split /\s+/, $line;

        push @{$self->{_pos}}, $split[0];
        push @{$self->{_res}}, $split[1];
        my @raws = @split[2..21];
        my @norms = map {_normalize_pssm($_)} @raws;
        push @{$self->{_raw_score}}, \@raws;
        push @{$self->{_norm_score}}, \@norms;
        my @pcs = @split[22 .. 41];
        my @pc_norms = map {$_ / 100} @pcs;
        push @{$self->{_pc_score}}, \@pc_norms;
        push @{$self->{_info}}, $split[42];
        push @{$self->{_weight}}, $split[43];
        push @{$self->{_loc}}, ($split[0] / $length);
    }
}

sub get_pos {
    my $self = shift;
    return $self->{_pos};
}

sub get_res {
    my $self = shift;
    return $self->{_res};
}

sub get_raw {
    my $self = shift;
    return $self->{_raw_score};
}

sub get_normalized {
    my $self = shift;
    return $self->{_norm_score};
}

sub get_pc {
    my $self = shift;
    return $self->{_pc_score};
}

sub get_info {
    my $self = shift;
    return $self->{_info};
}

sub get_weight {
    my $self = shift;
    return $self->{_weight};
}

#--------------------------------------------------
# name:        normalize_pssm
# args:        pssm value
# return:      normalized pssm value
#-------------------------------------------------- 
sub _normalize_pssm {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

1;
