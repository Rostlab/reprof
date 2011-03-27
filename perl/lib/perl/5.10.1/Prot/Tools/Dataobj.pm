package Prot::Tools::Dataobj;

use strict;
use feature qw(say);

sub new {
	my ($class, %opts) = @_;


	my $self = {
		_file			=> undef,
		_window			=> 9,
		_bin_size		=> 100,
		_num_inputs		=> undef,
		_num_outputs	=> undef,
		_prots			=> [],
		_current		=> {
			_prot			=> 0,
			_dp				=> 0,
			_first			=> 0,
			_last			=> 0
			}
		};

	foreach my $opt (keys %opts) {
		if (exists $opts{'_'.$opt}) {
			$self->{'_'.$opt} = $opts{$opt};
		}
	}

	return bless $self, $class;
}

#--------------------------------------------------
# Parse the datafile
#-------------------------------------------------- 
sub parse {
	my $self = shift;

	open IN, $self->{_file} or die "Could not open\n";
	my @in = <IN>;
	chomp @in;
	close IN;

	my $hd = shift @in;
	warn "No header specified\n" if !defined $hd;
	my @header = split /\t/, $hd;
	my ($dump, $num_skip, $num_in, $num_out) = @header;

	my $pointer = -1;
	my $in_start = 1 + $num_skip;
	my $out_start = $in_start + $num_in;
	my $in_end = $out_start - 1;
	my $out_end = $out_start + $num_out - 1;

	foreach my $dp (@in) {
		unless ($dp =~ /^#/) {
			if ($dp =~ /^ID/) {
				push @{$self->{_prots}}, [];
				$pointer++;
			}
			elsif ($dp =~ /^DP/) {
				my @split = split /\t/, $dp;
				
				my @ins;
				my @outs;

				foreach ($in_start .. $in_end) {
					push @ins, int($split[$_]);
				}
				foreach ($out_start .. $out_end) {
					push @outs, int($split[$_]);
				}

				push @{$self->{_prots}->[$pointer]}, [\@ins, \@outs];		
			}
		}
	}
}

#--------------------------------------------------
# Set the desired bins (start, amount)
#-------------------------------------------------- 
sub bins {
	my ($self, $start, $amount) = @_;

	$self->{_current}{_first} = $self->_check_prot_index( $start * $self->{_bin_size});
	$self->{_current}{_prot} = $self->_check_prot_index( $start * $self->{_bin_size});
	$self->{_current}{_last} = $self->_check_prot_index( $self->{_current}{_first} + $self->{_bin_size} * $amount - 1);
}

sub _check_prot_index {
	my ($self, $i) = @_;	

	while ( $i >= scalar(@{$self->{_prots}}) ) {
		$i -= scalar @{$self->{_prots}};
	}
	
	return $i;
}

#--------------------------------------------------
# Get the next datapoints, return undef if 
# end is reached
#-------------------------------------------------- 
sub next_prot {
	my $self = shift;

	if ($self->{_current}{_prot} == $self->{_current}{_last}) {
		return undef;
	}
	$self->{_current}{_prot} = $self->_check_prot_index($self->{_current}{_prot}++);
	
	return $self->{_prots}->[$self->{_current}{_prot}];
}

sub next_dp {
	my $self = shift;

	if ($self->{_current}{_dp} >= $self->{_prots}{_}) {
		return undef;
	}
	$self->{_current}{_prot} = $self->_check_prot_index($self->{_current}{_prot}++);
	
	return $self->{_prots}->[$self->{_current}{_prot}];
}

sub _current_prot {
	my $self = shift;
	return $self->{_current}{_prot};
}

sub _current_dp {
	my $self = shift;
	return $self->{_current}{_dp};
}

sub _current_prot_length {
	my $self = shift;
	return scalar(@{$self->{_prots}->[_current_prot()]});
}

sub _prots_length {
	my $self = shift;
	return scalar(@{$self->{_prots}});
}

1;
