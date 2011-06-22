package NNtrain::Measure;
use strict;
use feature qw(say);
use List::Util qw(sum);
use Data::Dumper;

sub new {
    my ($class, $size) = @_;

    my $self = [[], $size];
    foreach (0 .. $size) {
        push @{$self->[0]}, [map {0} (0 .. $size)];
    }

    bless $self, $class;
    return $self;
}

sub add {
    my ($self, $observed, $predicted) = @_;

    $self->[0][$self->max_pos($observed)][$self->max_pos($predicted)]++;
}

sub update_sums {
    my ($self) = @_;

    my $size = $self->[1];
    foreach my $i (0 .. $size - 1) {
        $self->[0][$i][$size] = 0;
        $self->[0][$size][$i] = 0;
    }
    $self->[0][$size][$size] = 0;

    foreach my $i (0 .. $size - 1) {
        foreach my $j (0 .. $size - 1) {
            $self->[0][$i][$size] += $self->[0][$i][$j];
            $self->[0][$size][$j] += $self->[0][$i][$j];
            $self->[0][$size][$size] += $self->[0][$i][$j];
        }
    }
}

sub size {
    my ($self) = @_;
    return $self->[1];
}

sub Qn {
    # observed, predicted
    my ($self) = @_;

    $self->update_sums;
    my $size = $self->[1];

    my $tp_sum = 0;
    foreach my $i (0 .. $size - 1) {
        $tp_sum += $self->[0][$i][$i];
    }

    my $div = $self->[0][$size][$size];
    if ($div == 0) {
        return 0;
    }
    else {
        return $tp_sum / $div;
    }
}

sub precisions {
    # observed, predicted
    my ($self) = @_;

    $self->update_sums;
    my $size = $self->[1];

    my @results;
    foreach my $i (0 .. $size - 1) {
        my $div = $self->[0][$i][$size];
        if ($div == 0) {
            push @results, 0;
        }
        else {
            my $prec = $self->[0][$i][$i] / $div;
            push @results, $prec;
        }
    }

    return @results;
}

sub recalls {
    # observed, predicted
    my ($self) = @_;

    $self->update_sums;
    my $size = $self->[1];

    my @results;
    foreach my $i (0 .. $size - 1) {
        my $div = $self->[0][$size][$i];
        if ($div == 0) {
            push @results, 0;
        }
        else {
            my $rec = $self->[0][$i][$i] / $div;
            push @results, $rec;
        }
    }

    return @results;
}


sub fmeasures {
    # observed, predicted
    my ($self) = @_;

    my @results;

    my @precisions = $self->precisions;
    my @recalls = $self->recalls;

    foreach my $iter (0 .. scalar @precisions - 1) {
        my $p = $precisions[$iter];
        my $r = $recalls[$iter];

        my $div = $p + $r;
        if ($div == 0) {
            push @results, 0;
        }
        else {
            my $fm = 2 * (($p * $r) / ($p + $r));
            push @results, $fm;
        }
    }

    return @results;
}

sub max_pos {
    my ($self, $array) = @_;

    my $mpos = 0;
    foreach my $pos (1 .. scalar @$array - 1) {
        if ($array->[$pos] > $array->[$mpos]) {
            $mpos = $pos;
        }
    }

    return $mpos;
}

1;
