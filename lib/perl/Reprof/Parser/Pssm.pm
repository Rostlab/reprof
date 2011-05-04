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

        push @{$self->{_pos}}, [$split[0]];
        push @{$self->{_res}}, [$split[1]];
        my @raws = @split[2..21];
        my @norms = map _normalize_pssm($_), @raws;
        push @{$self->{_raw_score}}, \@raws;
        push @{$self->{_norm_score}}, \@norms;
        push @{$self->{_pc_score}}, [(@split)[22 .. 41]];
        push @{$self->{_info}}, [$split[42]];
        push @{$self->{_weight}}, [$split[43]];
        push @{$self->{_loc}}, [ $split[0] / $length ];
    }
}

sub get_field {
    my ($self, $field) = @_;

    return $self->{"_$field"};
}

sub get_fields {
    my ($self, @fields) = @_;

    my @result;
    foreach my $field (@fields) {
        push @result, $self->{"_$field"};
    }

    return \@result;
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
