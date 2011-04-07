=head1 NAME

Reprof::Parser::Dssp - Parser for Dssp files

=head1 SYNOPSIS

	my $parser->new;
	$parser->parse($file);

	# Get array with chains:
	$parser->chains;

	# Get SS sequence:
	$parser->ss;

	# Get SS sequence for specific chain:
	$parser->ss('A');

	# Get amino acid sequence:
	$parser->seq;

	# Get amino acid sequence for specific chain:
	$parser->seq('A');

	# Get solvent acc. for specific residue (if unique chain)
	$parser->acc(55);

	# Get solvent acc. for specific res. and chain
	$parser->acc(55, 'A');

=head1 DESCRIPTION

Self explanatory.

=head1 AUTHOR

hoenigschmid AT rostlab.org

=head1 SUBROUTINES/METHODS

=over 12

=cut

package Reprof::Parser::Dssp;

use strict;

use Reprof::Tools::Translator qw(structreduce id2pdb);

=item C<new()>

Create a new parser object.

=cut

sub new {
	my $self = {
		_id		=> undef,
		_acc	=> {},
		_ss		=> {},
		_seq	=> {}
	};

	bless $self;
}

=item C<parse(FILE)>

Parse a dssp file.

=cut

sub parse {
	my ($self, $file) = @_;

	$self->{_id} = id2pdb($file);
	
	my $res_started = 0;
	my $break = 0;
	open FH, $file or return 0;# "Could not open $file\n";
	while (<FH>) {
		if (!$res_started && m/^  #  RESIDUE AA STRUCTURE/) {
			$res_started = 1;
		}
		elsif ($res_started) {
			if (/!/) {
				$break++;
			}
			else {
				my $resnr = _parsefield($_, 3, 5);
				my $chain = _parsefield($_, 12, 12) . $break;				
				my $res = _parsefield($_, 14, 14);
				my $ss  = structreduce( _parsefield($_, 17, 17) );
				my $acc = _parsefield($_, 36, 38);

				$self->{_acc}->{$chain}->{$resnr} = $acc;
				$self->{_ss}->{$chain} .= $ss;
				$self->{_seq}->{$chain} .= $res;
			}
		}
	}
	close FH;
}

=item C<id()>

Returns the id (parsed from filename).

=cut

sub id {
	my $self = shift;
	return $self->{_id};
}

=item C<acc(RESNR, [CHAIN])>

Returns the solvent acc. for the given redidue number an chain. Residue number is mandatory, if you omit the chain id, the first chain is used.

=cut

sub acc {
	my ($self, $resnr, $chain) = @_;

	$chain = ($self->chains)[0] unless defined $chain;

	return $self->{_acc}->{$chain}->{$resnr};
}

=item C<chains()>

Returns an array containing the chain identifiers

=cut

sub chains {
	my $self = shift;

	return keys %{$self->{_seq}};
}

=item C<seq([CHAIN])>

Returns the sequence for the chain provided as argument.
If no argument is given, all chains are concatenated.

=cut

sub seq {
	my ($self, $chain) = @_;

    unless (defined $chain) {
		my $temp;
		foreach (sort {$a cmp $b} (keys %{$self->{_seq}})) {
			$temp .= $self->{_seq}->{$_};
		}
		return $temp;
	}

	return $self->{_seq}->{$chain};
}

=item C<ss([CHAIN])>

Returns the SS sequence for the chain provided as argument.
If no argument is given, all chains are concatenated.

=cut

sub ss {
	my ($self, $chain) = @_;

    unless (defined $chain) {
		my $temp;
		foreach (sort {$a cmp $b} (keys %{$self->{_ss}})) {
			$temp .= $self->{_ss}->{$_};
		}
		return $temp;
	}

	return $self->{_ss}->{$chain};
}

=back

=cut

#--------------------------------------------------
# INTERN
#-------------------------------------------------- 

#--------------------------------------------------
# Function which returns a part of a record field
# (taking the numbers provided in the pdb doc)
#-------------------------------------------------- 
sub _parsefield {
	my ($entry, $from, $to) = @_;
	my $val;
	if (defined $to) {
		$val = substr $entry, $from - 1, $to-($from - 1);
	}
	else {
		$val = substr $entry, $from - 1;
	}

	chomp $val;
	$val =~ s/^\s+//;
	$val =~ s/\s+$//;
	return $val;
}

1;
