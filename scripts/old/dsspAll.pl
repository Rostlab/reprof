#!/usr/bin/perl -w

#--------------------------------------------------
# AUTHOR: hoenigschmid AT rostlab.org
#-------------------------------------------------- 

use strict;
use Config::General;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Spec::Functions qw (catfile catdir);
use Prot::Tools::Translator qw(id2pdb);
use Prot::Tools::Dssp qw(run_dssp);
use Parallel::ForkManager;

# take configfile as inputparameter
my $configfile = shift;

# parse config
my $configparser = Config::General->new($configfile);
my %config = $configparser->getall;

# extract relevant config entries
my $pdbdir = $config{pdb}->{local_dir};
my $dsspdir = $config{dssp}->{local_dir};
my $tmpdir = $config{tmp_dir};
my $cores = $config{cores};

# create forkmanager
my $forkman = Parallel::ForkManager->new($cores);

# read pdb dir
opendir PDBDIR, $pdbdir;
my @pdbfiles = readdir PDBDIR;
close PDBDIR;

my $count = 0;

# loop through the pdb files
foreach my $pdbfile_rel (@pdbfiles) {
	# print some progress info
	if (++$count % 100 == 0) {
		print $count . "/" . @pdbfiles . "\n";
	}

	# skip . and ..
	next if -d $pdbfile_rel;

	# fork
	$forkman->start and next;

	my $pdbfile = catfile $pdbdir, $pdbfile_rel;

	my $id = id2pdb($pdbfile);
	my $dsspfile = catfile $dsspdir, $id . '.dssp';

	# skip if dssp is already present
	if (!-e $dsspfile) {
		my $pdbtmp = catfile $tmpdir, $id . '.pdb.tmp';

		gunzip($pdbfile => $pdbtmp) or die "gunzip error $GunzipError\n";
		run_dssp($pdbtmp, $dsspfile, $config{'dssp'});

		unlink $pdbtmp;
	}

	# kill child
	$forkman->finish; 
}

# wait for all children
$forkman->wait_all_children;
