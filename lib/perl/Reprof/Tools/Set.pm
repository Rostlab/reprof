package Reprof::Tools::Set;

use strict;
use feature qw(say);
use Data::Dumper;
use List::Util qw(shuffle);

sub new {
    my ($class, $win, $data) = @_;

    my $self = {  
        _data           => $data || [],
        _iter_original  => [],
        _iter_current   => [],
        _new_flag       => 1,
        _dps            => 0,
        _prots          => 0,
        _win            => $win,
    };

    return bless $self, $class;
}

sub subset {
    my ($self, $num_bins, @parts) = @_;

    my $pos = 0;

    #--------------------------------------------------
    # TODO 
    #-------------------------------------------------- 

    my @subdata = (@{$self->{_data}})[@parts];
    my $sset = Reprof::Tools::Set->new($self->win, \@subdata);

    return $sset;
}

sub win {
    my ($self, $win) = @_;
    if (defined $win) {
        $self->{_win} = $win;
    }
    return $self->{_win};
}

sub add {
    my ($self, $descs_opt, $feats_opt, $outs_opt) = @_;
    
    my @descs;
    my @feats;
    my @outs;

    my $tmp;

    my $index = scalar @{$self->{_data}};
    foreach my $pos (0 .. scalar @{$feats_opt->[0]} - 1) {
        my @descs_tmp;
        foreach my $desc (@$descs_opt) {
            push @descs_tmp, @{$desc->[$pos]};
        }
        my @feats_tmp;
        foreach my $feat (@$feats_opt) {
            push @feats_tmp, @{$feat->[$pos]};
        }
        my @outs_tmp;
        foreach my $out (@$outs_opt) {
            push @outs_tmp, @{$out->[$pos]};
        }

        push @$tmp, [\@descs_tmp, \@feats_tmp, \@outs_tmp];
        push @{$self->{_iter_original}}, [$index, $pos];
    }

    push @{$self->{_data}}, $tmp;
}

sub reset_iter_random {
    my $self = shift;

    if ($self->{_new_flag}) {
        $self->{_new_flag}--;
    }

    $self->{_iter_current} = [];
    push @{$self->{_iter_current}}, (shuffle @{$self->{_iter_original}});
}

sub reset_iter_original {
    my $self = shift;

    if ($self->{_new_flag}) {
        $self->{_new_flag}--;
    }

    $self->{_iter_current} = [];
    push @{$self->{_iter_current}}, @{$self->{_iter_original}};
}

sub next_dp {
    my ($self) = @_;

    if ($self->{_new_flag}) {
        $self->{_new_flag}--;
        $self->reset_iter_original;
    }

    my $current = shift @{$self->{_iter_current}};
    unless (defined $current) {
        $self->reset_iter_original;
        return undef;
    }

#--------------------------------------------------
#     say Dumper($self->{_data});
#-------------------------------------------------- 

    my ($prot, $center) = @$current;

    my $win_start = $center - ($self->{_win} - 1) / 2;
    my $win_end = $center + ($self->{_win} - 1) / 2;
    my $seq_length = scalar @{$self->{_data}->[$prot]};

    my @tmp_desc;
    my @tmp_in;
    my @tmp_out;

    push @tmp_out, @{$self->{_data}->[$prot][$center][2]};
    push @tmp_desc, @{$self->{_data}->[$prot][$center][0]};

    foreach my $pointer ($win_start .. $win_end) {
        if ($pointer < 0 || $pointer >= $seq_length) {
            # add zero filled array with 1 for out of sequence bit
            push @tmp_in, (map 0, @{$self->{_data}->[$prot][$center][1]}), 1;
        }
        else {
            push @tmp_in, @{$self->{_data}->[$prot][$pointer][1]}, 0;
        }
    }

    return [\@tmp_desc, \@tmp_in, \@tmp_out];
}

1;
