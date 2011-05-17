package Reprof::Tools::Measure;

use strict;
use feature qw(say);
use Data::Dumper;
use List::Util qw(sum);

my $debug = 0;

#--------------------------------------------------
# matrix[observed][predicted]
#-------------------------------------------------- 
sub new {
	my ($class, $size) = @_;
	my $self = [$size, []];

    
    if ($size == 1) {
        $self->[1] = [0, 0];
    }
    else {
        foreach my $i (0 .. $size-1) {
            push @{$self->[1]}, [];
            foreach (0 .. $size-1) {
                push @{$self->[1][$i]}, 0;
            }
        }
    }

	
	return bless $self, $class;
}

sub size {
    my $self = shift;
    return $self->[0];
}

# residues predicted to be in structure i
sub a_i {
    my ($self, $i) = @_;

    my $sum = 0;
    foreach (0 .. $self->[0]-1) {
        $sum += $self->[1][$_][$i];
    }
    return $sum;
}

# residues observed to be in structure i
sub b_i {
    my ($self, $i) = @_;

    my $sum = 0;
    foreach (0 .. $self->[0]-1) {
        $sum += $self->[1][$i][$_];
    }
    return $sum;
}

# all residues
sub b {
    my $self = shift;

    my $sum = 0;
    foreach my $i (0 .. $self->[0]-1) {
        foreach my $j (0 .. $self->[0]-1) {
            $sum += $self->[1][$i][$j];
        }
    }
    return $sum;
}

# Q_i
sub Q_i {
    my ($self, $i) = @_;
    return ($self->[1][$i][$i] / $self->b_i($i));
}

# three state accuracy
sub Q3 {
    my $self = shift;
    my $sum = 0;
    foreach my $i (0 .. $self->[0]-1) {
        $sum += $self->[1][$i][$i];
    }
    return $sum / $self->b;
}

sub add {
	my ($self, $observed, $predicted) = @_;

    if ($self->[0] == 1) {
        my $res = ($predicted->[0] - $observed->[0]);
        if ($res < 0) {
            $res *= -1;
        }
        $self->[1][0] += $res;
        $self->[1][1]++;
    }
    else {
        my $obs = $self->_list_max_position($observed);
        my $pred = $self->_list_max_position($predicted);
        $self->[1][$obs][$pred]++;
    }
}

sub mse {
    my $self = shift;
    return ($self->[1][0] / $self->[1][1]);
}

sub _list_max_position {
	my ($self, $list) = @_;
	my $max_pos = -1;
	my $max_val = -100;

	foreach (0 .. (scalar @$list)-1) {
		if ($list->[$_] >= $max_val) {
			$max_val = $list->[$_];
			$max_pos = $_;
		}
	}
        return $max_pos;
}

1;
