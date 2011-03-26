#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use File::Spec;
use Prot::Tools::Translator qw(id2pdb);
use Prot::Parser::Pdb;
use Prot::Tools::FileDb;

my $fastafile;	# file containing the interesting proteins
my $pdbdir;		# directory containing the pdb files used in the fasta file
my $outfile;	# output file for the file db
GetOptions(	'fasta=s'	=> \$fastafile,
			'pdb=s'		=> \$pdbdir,
			'out=s'		=> \$outfile);

#--------------------------------------------------
# Get pdb ids and link them to the correspoding files
#-------------------------------------------------- 
my %pdbs;
opendir PDB, $pdbdir;
while (my $file = readdir PDB) {
	next if -d $file;

	my $id = id2pdb $file;
	$pdbs{$id} = File::Spec->catfile($pdbdir, $file);
	say "$id -> $pdbs{$id}";
}
close PDB;

#--------------------------------------------------
# Read fasta file and get ids
#-------------------------------------------------- 
open FASTA, $fastafile or die "Could not open $fastafile\n";
my %ids;
foreach (<FASTA>) {
	if (/^>/) {
		$ids{id2pdb $_}++; 
		say id2pdb($_);
	}
}
close FASTA;

#--------------------------------------------------
# Extract relevant information from the pdb files
#-------------------------------------------------- 
my $db = Prot::Tools::FileDb->new;
$db->fields('id', 'chains', 'res', 'exp', 'hssp');

foreach my $id (keys %ids) {
	my $parser = Prot::Parser::Pdb->new;
	$parser->parse($pdbs{$id});
	$db->add(	$parser->id,
				scalar($parser->chains),
				$parser->resolution,
				$parser->expdata,
				0);
}

$db->save($outfile);
