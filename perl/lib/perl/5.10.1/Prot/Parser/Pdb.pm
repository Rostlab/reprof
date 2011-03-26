=head1 NAME

Prot::Parser::Pdb - Parser for PDB files

=head1 SYNOPSIS

	my $parser = Setms::Parser::Pdb->new;
	$parser->parse($file);

	# Get chain ids:
	$parser->chains;

	# Get whole seqres:
	$parser->seqres;

	# Get chain specific seqres:
	$parser->seqres('A');

	# Same for atom sequence:
	$parser->atomseq;
	$parser->atomseq('A');

	# Get expdata record(s)
	$parser->expdata;

=head1 DESCRIPTION

Self explanatory.

=head1 AUTHOR

hoenigschmid AT rostlab.org

=head1 SUBROUTINES/METHODS

=over 12

=cut


package Prot::Parser::Pdb;

use strict;

use feature qw(say);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Prot::Tools::Translator qw(three2one id2pdb);

=item C<new()>

Creates a new parser object.

=cut

sub new {
	my $self = {
		_id			=> undef,
		_expdta		=> [],
		_seqres		=> {},
		_atomseq	=> {},
		_atoms		=> {},
		_res		=> undef
	};

	bless $self;
}

=item C<parse(FILE)>

Takes the pdb file as an argument, and parses it.

=cut

sub parse {
	my ($self, $file, $fast) = @_;

	$self->{_id} = id2pdb($file);
	
	my @fcont;
	if ($file =~ m/\.gz$/) {
		my $tmp;
		gunzip($file => \$tmp) or die "gunzip failed: $GunzipError\n";
		@fcont = split /\n/, $tmp; 
	}
	else {
		open FH, $file;
		@fcont = <FH>;
		close FH;
	}

	foreach (@fcont) {
		my $record = substr $_, 0, 6;		

		if (!$fast && $record eq 'ATOM  ') {
			$self->_parseATOM($_);
		}
		#--------------------------------------------------
		# elsif ($record eq 'SEQRES')	{ 
		# 	$self->_parseSEQRES($_);
		# }
		#-------------------------------------------------- 
		elsif ($record eq 'REMARK') {
			$self->_parseREMARK($_);
		}
		elsif ($record eq 'EXPDTA') {
			$self->_parseEXPDTA($_);
		}
	}
	
	$self->_postprocess;
}

=item C<id()>

Returns the id (parsed from filename).

=cut

sub id {
	my $self = shift;
	$self->{_id};
}

=item C<chains()>

Returns an array containing the chain identifiers

=cut

sub chains {
	my $self = shift;

	return keys %{$self->{_atomseq}};
}

=item C<atomseq([CHAIN])>

Returns the atomseq for the chain provided as argument.
If no argument is given, all chains are concatenated.

=cut

sub atomseq {
	my ($self, $chain) = @_;

    unless (defined $chain) {
		my $temp;
		foreach (sort {$a cmp $b} (keys %{$self->{_atomseq}})) {
			$temp .= $self->{_atomseq}->{$_};
		}
		return $temp;
	}

	return $self->{_atomseq}->{$chain};
}

=item C<seqres([CHAIN])>

Returns the seqres for the chain provided as argument.
If no argument is given, all chains are concatenated.

=cut

sub seqres {
	my ($self, $chain) = @_;

    unless (defined $chain) {
		my $temp;
		foreach (sort {$a cmp $b} (keys %{$self->{_seqres}})) {
			$temp .= $self->{_seqres}->{$_};
		}
		return $temp;
	}

	return $self->{_seqres}->{$chain};
}

=item C<expdata()>

Returns the methods used to solve the structure as an array

=cut

sub expdata { my $self = shift;
	@{$self->{_expdta}};
}

=item C<resolution()>

Returns the resolution if found in the pdb file, undef otherwise

=cut

sub resolution {
	my $self = shift;
	$self->{_res};
}

=back

=cut

#--------------------------------------------------
# INTERN
#-------------------------------------------------- 

#--------------------------------------------------
# Builds the atomseq from the atomrecords
#-------------------------------------------------- 
sub _postprocess {
	my $self = shift;

	foreach my $chain (sort {$a cmp $b} (keys %{$self->{_atoms}})) {
		foreach my $resnr (sort {$a <=> $b} (keys %{$self->{_atoms}->{$chain}})) {
			$self->{_atomseq}->{$chain} .= $self->{_atoms}->{$chain}->{$resnr};
		}
	}
}

#--------------------------------------------------
# 12345678901234567890123456789012345678901234567890123456789012345678901234567890
# REMARK   2                                                            
# REMARK   2 RESOLUTION.    1.74 ANGSTROMS.
# REMARK   2                                                            
# REMARK   2 RESOLUTION.    NOT APPLICABLE.                                
# REMARK   2                                                                      
# REMARK   2 RESOLUTION.    7.50  ANGSTROMS.
#-------------------------------------------------- 
#--------------------------------------------------
# Parse resolution etc.
#-------------------------------------------------- 
sub _parseREMARK {
	my ($self, $entry) = @_; 

	if (_parsefield($entry, 10, 10) eq '2') {
		if (_parsefield($entry, 12, 22) eq 'RESOLUTION.') {
			my $resolution = _parsefield($entry, 24, 30);
			if ($resolution =~ /(\d+(\.\d+){0,1})/) {
				$self->{_res} = $1;
			}
		}
	}
}

#--------------------------------------------------
# COLUMNS       DATA TYPE      FIELD         DEFINITION    
# ------------------------------------------------------------------------------------
#  1 -  6       Record name    "EXPDTA"   
#  9 - 10       Continuation   continuation  Allows concatenation of multiple records.
#  11 - 79      SList          technique     The experimental technique(s) with  
#                                              optional comment describing the 
# 											                                            sample or experiment. 
#-------------------------------------------------- 
#--------------------------------------------------
# Parse the experiment record
#-------------------------------------------------- 
sub _parseEXPDTA {
	my ($self, $entry) = @_;

	my @vals = split /;/, substr($entry, 8);
	foreach (@vals) {
		push @{$self->{_expdta}}, _parsefield($_, 1);
	}
}

#--------------------------------------------------
# COLUMNS        DATA  TYPE    FIELD        DEFINITION
# -------------------------------------------------------------------------------------
#   1 -  6         Record name   "ATOM  "
#   7 - 11         Integer       serial       Atom  serial number.
#   13 - 16        Atom          name         Atom name.
#   17             Character     altLoc       Alternate location indicator.
#   18 - 20        Residue name  resName      Residue name.
#   22             Character     chainID      Chain identifier.
#   23 - 26        Integer       resSeq       Residue sequence number.
#   27             AChar         iCode        Code for insertion of residues.
#   31 - 38        Real(8.3)     x            Orthogonal coordinates for X in Angstroms.
#   39 - 46        Real(8.3)     y            Orthogonal coordinates for Y in Angstroms.
#   47 - 54        Real(8.3)     z            Orthogonal coordinates for Z in Angstroms.
#   55 - 60        Real(6.2)     occupancy    Occupancy.
#   61 - 66        Real(6.2)     tempFactor   Temperature  factor.
#   77 - 78        LString(2)    element      Element symbol, right-justified.
#   79 - 80        LString(2)    charge       Charge  on the atom.
#-------------------------------------------------- 
#--------------------------------------------------
# Parse atom records
#-------------------------------------------------- 
sub _parseATOM {
	my ($self, $e) = @_;

	my $chain = _parsefield($e, 22, 22);
	my $resnr = _parsefield($e, 23, 26);
	my $resname = three2one( _parsefield($e, 18, 20) );

	$self->{_atoms}->{$chain}->{$resnr} = $resname;
}

#--------------------------------------------------
# Parse seqres record
#-------------------------------------------------- 
sub _parseSEQRES {
	my ($self, $e) = @_;
	
	my $chain = _parsefield($e, 12, 12);
	my @seq = split( /\s/, _parsefield($e, 20));

	foreach (@seq) {
		$self->{_seqres}->{$chain} .= three2one($_);
	}
}

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
