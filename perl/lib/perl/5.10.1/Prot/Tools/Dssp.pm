package Prot::Tools::Dssp;

use strict;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(run_dssp);

use Prot::Tools::Translator qw(id2pdb);
use File::Spec::Functions qw(splitpath catfile);

sub run_dssp {
	my ($in, $out, $opts) = @_;

	my $dsspbin = $opts->{'bin'};

	if (-d $out) {
		$out = catfile($out, id2pdb($in).'.dssp');
	}

	qx($dsspbin $in $out 2>/dev/null);
}

