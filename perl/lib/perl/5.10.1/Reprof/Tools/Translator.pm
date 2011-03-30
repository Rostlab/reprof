=head1 NAME

Reprof::Tools::Translator - Several methods for letter conversion

=head1 SYNOPSIS

	use Reprof::Tools::Translator qw(lettercode structreduce);

	my $onelettercode = lettercode('MET');	# returns 'M'
	my $threelettercode = lettercode('M');	# returns 'MET'

	my $reducedstruc = structreduce('G');	# returns 'H'

=head1 AUTHOR

hoenigschmid AT rostlab.org

=head1 SUBROUTINES/METHODS

=over 12

=cut

package Reprof::Tools::Translator;

use strict;
use feature qw(say);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(hval three2one one2three lettercode structreduce id2pdb id2pdbchain aa2number ss2number);

sub hval {
    my ($length, $pid) = @_;

    if ($length <= 11) {
        return $pid - 100.0;
    }
    elsif ($length <= 450) {
        my $ex = -0.32 * (1 + exp(- $length / 1000));
        return $pid - (480 * ($length ** $ex));
    }
    else {
        return $pid - 19.5;
    }
}

sub id2pdb {
	my $id = shift;

	my $result;
	while ($id =~ m/(\d[\d\w]{3})/g) {
		$result = $1;
	}
	lc($result);
}

sub id2pdbchain {
	my $id = shift;

	my $result;
	while ($id =~ m/(\d[\d\w]{3}:\w\d*)/g) {
		$result = $1;
	}
	return $result;
}

my %ss2number_dict = (	'L' => 0,
						'H' => 1,
						'E' => 2,
						0 => 'L',
						1 => 'H',
                        2 => 'E');
sub ss2number {
	my $ss = shift;
	my $result = $ss2number_dict{uc $ss};
	return $result if defined $result;
	return 0;
}

# amino acid 2 numberdictionary
my %aa2number_dict = (
	'X' => 0,
	'A' => 1,
	'R' => 2,
	'N' => 3,
	'D' => 4,
	'C' => 5,
	'E' => 6,
	'Q' => 7,
	'G' => 8,
	'H' => 9,
	'I' => 10,
	'L' => 11,
	'K' => 12,
	'M' => 13,
	'F' => 14,
	'P' => 15,
	'S' => 16,
	'T' => 17,
	'W' => 18,
	'Y' => 19,
	'V' => 20,
	0 => 'X',
	1 => 'A',
	2 => 'R',
	3 => 'N',
	4 => 'D',
	5 => 'C',
	6 => 'E',
	7 => 'Q',
	8 => 'G',
	9 => 'H',
	10 => 'I',
	11 => 'L',
	12 => 'K',
	13 => 'M',
	14 => 'F',
	15 => 'P',
	16 => 'S',
	17 => 'T',
	18 => 'W',
	19 => 'Y',
	20 => 'V'
	);

sub aa2number {
	my $q = shift;
	my $result;

	$result = $aa2number_dict{uc($q)};
	return $result if defined $result;
	return 0;
}

# one 2 three conversion dictionary
my %one2three_dict = (
	'A' => 'ALA',
	'R' => 'ARG',
	'N' => 'ASN',
	'D' => 'ASP',
	'C' => 'CYS',
	'E' => 'GLU',
	'Q' => 'GLN',
	'G' => 'GLY',
	'H' => 'HIS',
	'I' => 'ILE',
	'L' => 'LEU',
	'K' => 'LYS',
	'M' => 'MET',
	'F' => 'PHE',
	'P' => 'PRO',
	'S' => 'SER',
	'T' => 'THR',
	'W' => 'TRP',
	'Y' => 'TYR',
	'V' => 'VAL',
	'ALA' => 'A',
	'ARG' => 'R',
	'ASN' => 'N',
	'ASP' => 'D',
	'CYS' => 'C',
	'GLU' => 'E',
	'GLN' => 'Q',
	'GLY' => 'G',
	'HIS' => 'H',
	'ILE' => 'I',
	'LEU' => 'L',
	'LYS' => 'K',
	'MET' => 'M',
	'PHE' => 'F',
	'PRO' => 'P',
	'SER' => 'S',
	'THR' => 'T',
	'TRP' => 'W',
	'TYR' => 'Y',
	'VAL' => 'V'
	);


=item C<lettercode(LETTERs)>

Takes a string (one or three lettercode) and converts it to the other format.
If a non lettercode is provided, the sub tries to guess the conversion
by taking the last three/one letters. (Prefers three letter code).

=cut

sub lettercode {
	my $q = shift;

	if (length($q) > 3) {
		return three2one($q);
	}
	return one2three($q);
}

=item C<one2three(LETTERs)>

Takes an amino acid one letter code and returns the 3 lc.
If a string of length more than one is given, the last character is used.

=cut

sub one2three {
	my $q = shift;

	$q = substr $q, -1 if length($q) > 1;

	return $one2three_dict{uc($q)};
}

=item C<three2one(LETTERs)>

Takes an amino acid three letter code and returns the 1 lc.
If a string of length more than three is given, the last three characters are used.
If a string of length less than three is given, the sub returns the last character.

=cut

sub three2one {
	my $q = shift;

	if (length($q) >= 3) {
		return $one2three_dict{uc(substr $q, -3)};
	}
	return substr $q, -1;
}

my %struct = (
	'G'	=> 'H',
	'H'	=> 'H',
	'I'	=> 'H',
	'E'	=> 'E',
	'B'	=> 'E'
	);

=item C<structreduce(LETTER)>

Reduces DSSP lettercode to H, E, L

=cut

sub structreduce {
	my $q = uc( shift(@_) );

	return $struct{$q} if exists $struct{$q};
	return 'L';

}

=back

=cut

1;
