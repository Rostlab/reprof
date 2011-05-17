package Reprof::Tools::Set;

use strict;
use feature qw(say);
use Data::Dumper;
use List::Util qw(shuffle);

sub new {
    my ($class, $win, $data) = @_;

    my $self = {  
        _data           => $data // {},
        _iter_original  => [],
        _iter_current   => [],
        _new_flag       => 1,
        _dps            => 0,
        _prots          => 0,
        _win            => $win,
        _num_features   => undef,
        _num_outputs    => undef,
        _iter           => 'original'
    };

    return bless $self, $class;
}

sub num_features {
    my $self = shift;
    return $self->{_num_features};
}

sub num_outputs {
    my $self = shift;
    return $self->{_num_outputs};
}

sub iter {
    my ($self, $iter) = @_;
    if (defined $iter) {
        $self->{_iter} = $iter;
    }
    return $self->{_iter};
}

sub win {
    my ($self, $win) = @_;
    if (defined $win) {
        $self->{_win} = $win;
    }
    return $self->{_win};
}

sub add {
    my ($self, $id, $desc, $feat, $out) = @_;

    $self->{_num_features} = scalar @{$feat} + 1;
    $self->{_num_outputs} = scalar @{$out};
    
    push @{$self->{_data}{$id}}, [$desc, $feat, $out];

    my $pos = scalar @{$self->{_data}{$id}} - 1;

    push @{$self->{_iter_original}}, [$id, $pos];
}

sub reset_iter {
    my $self = shift;

    if ($self->{_new_flag}) {
        $self->{_new_flag} = 0;
    }

    $self->{_iter_current} = [];

    if ($self->{_iter} eq 'random') {
        push @{$self->{_iter_current}}, (shuffle @{$self->{_iter_original}});
    }
    elsif ($self->{_iter} eq 'original') {
        push @{$self->{_iter_current}}, @{$self->{_iter_original}};
    }
}

sub next_dp {
    my ($self) = @_;

    if ($self->{_new_flag}) {
        $self->{_new_flag} = 0;
        $self->reset_iter;
    }

    my $current = shift @{$self->{_iter_current}};
    unless (defined $current) {
        $self->reset_iter;
        return undef;
    }

    my ($prot, $center) = @$current;

    my $win_start = $center - ($self->{_win} - 1) / 2;
    my $win_end = $center + ($self->{_win} - 1) / 2;
    my $seq_length = scalar @{$self->{_data}{$prot}};

    my @tmp_desc;
    my @tmp_in;
    my @tmp_out;
    my @tmp_center;

    push @tmp_out, @{$self->{_data}{$prot}->[$center][2]};
    push @tmp_desc, @{$self->{_data}{$prot}->[$center][0]};
    push @tmp_center, @{$self->{_data}{$prot}->[$center][1]};

    foreach my $pointer ($win_start .. $win_end) {
        if ($pointer < 0 || $pointer >= $seq_length) {
            # add zero filled array with 1 for out of sequence bit
            push @tmp_in, (map 0, @{$self->{_data}{$prot}->[$center][1]}), 1;
        }
        else {
            push @tmp_in, @{$self->{_data}{$prot}->[$pointer][1]}, 0;
        }
    }

    return [\@tmp_desc, \@tmp_in, \@tmp_out, \@tmp_center, $prot];
}

1;
