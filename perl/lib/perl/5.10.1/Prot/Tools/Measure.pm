package Prot::Tools::Measure;

use strict;
use feature qw(say);
use Prot::Tools::Translator qw(ss2number);
use Data::Dumper;
use List::Util qw(sum);

my $debug = 0;

sub new {
	my $class = shift;
	my $self = {
		_tp	=> 0,
		_fp => 0,
		_fn => 0,
		_tn => 0 };
	
	return bless $self, $class;
}

sub tp {
	my ($self, $i) = @_;
	if (defined $i) {
		$self->{_tp} += $i;
	}
	return $self->{_tp};
}

sub fp {
	my ($self, $i) = @_;
	if (defined $i) {
		$self->{_fp} += $i;
	}
	return $self->{_tp};
}

sub tn {
	my ($self, $i) = @_;
	if (defined $i) {
		$self->{_tn} += $i;
	}
	return $self->{_tp};
}

sub fn {
	my ($self, $i) = @_;
	if (defined $i) {
		$self->{_fn} += $i;
	}
	return $self->{_tp};
}

sub q3 {
	my $self = shift;
	my $sum = $self->{_tp} + $self->{_fp} + $self->{_tn} + $self->{_fn}; 
	return 0 if $sum == 0;
	return ($self->{_tp} + $self->{_tn}) / $sum;
}

sub precision {
	my $self = shift;
	my $sum = $self->{_tp} + $self->{_fp};
	return 0 if $sum == 0;
	return $self->{_tp} / $sum;
}

sub recall {
	my $self = shift;
	my $sum = $self->{_tp} + $self->{_fn}; 
	return 0 if $sum == 0;
	return $self->{_tp} / $sum;
}

sub add {
	my ($self, $observed, $predicted) = @_;


	my $obs = $self->_clarify_list($observed);
	my $pred = $self->_clarify_list($predicted);

	if ($debug) {
		say "#######";
		say 'obs:';
		say Data::Dumper->Dump($obs);
		say 'pred:';
		say Data::Dumper->Dump($pred);
	}

	foreach my $pos (0 .. (scalar @$obs)-1) {
		my $o = $obs->[$pos];
		my $p = $pred->[$pos];

		if ($o && $p) {
			$self->{_tp}++;
			say 'adding tp' if $debug;
		}
		elsif (!$o && !$p) {
			$self->{_tn}++;
			say 'adding tn' if $debug;
		}
		elsif (!$o && $p) {
			$self->{_fp}++;
			say 'adding fp' if $debug;
		}
		elsif ($o && !$p) {
			$self->{_fn}++;
			say 'adding fn' if $debug;
		}
		else {
			warn "Observed/Predicted values seem to contain error(s)\n";
		}
	}
}

sub _clarify_list {
	my ($self, $list) = @_;
	my $max_pos = -1;
	my $max_val = -1;

	my @result = ();


	foreach (0 .. (scalar @$list)-1) {
		push @result, 0;
		if ($list->[$_] >= $max_val) {
			$max_val = $list->[$_];
			$max_pos = $_;
		}
	}

	$result[$max_pos] = 1;	

	return \@result;
}

1;
