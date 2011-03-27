#!/usr/bin/perl -w
use strict;
use feature qw(say);

use AI::FANN qw(:all);
use Getopt::Long;
use Prot::Tools::Translator qw(id2pdb aa2number ss2number);
use Prot::Parser::Dssp;
use File::Spec;
use List::Util qw(shuffle);

#--------------------------------------------------
# Data
#-------------------------------------------------- 
my $dssp_dir; 
my $fasta;

#--------------------------------------------------
# Helper variables
#-------------------------------------------------- 
my $num_folds = 10;
my $num_desc = 3;
my $num_as = 21;
my $num_ss = 3;

#--------------------------------------------------
# Output
#-------------------------------------------------- 
my $debug = 0;
my $outfile;

GetOptions(	'dssp=s'	=> \$dssp_dir,
                'out=s'		=> \$outfile,
                'fasta=s'	=> \$fasta,
                'debug'		=> \$debug);

#--------------------------------------------------
# Load fasta
#-------------------------------------------------- 
say "Getting ids/chains from fasta...";
my %proteins;
open FASTA, $fasta or die "Could not open $fasta\n";
while (<FASTA>) {
	if (/^>/) {
		my $id = substr $_, 1, 4;
		my $chain = substr $_, 6;
		chomp $chain;
		push @{$proteins{$id}}, $chain;
	}
}
close FASTA;

#--------------------------------------------------
# Shuffling proteins
#-------------------------------------------------- 
say "Shuffling proteins...";
my @shuffled_protein_ids = shuffle(keys %proteins);

#--------------------------------------------------
# Creating header comment
#-------------------------------------------------- 
my $header = "###\tNUM\tRES\tSS\t";
foreach (0 .. $num_as-1) {
	$header .= aa2number($_) . "\t";
}
foreach (0 .. $num_ss-1) {
	$header .= ss2number($_) . "\t";
}

#--------------------------------------------------
# Open outputfile and write description
#-------------------------------------------------- 
open OUT , ">", $outfile;
say OUT "HD\t$num_desc\t$num_as\t$num_ss";

#--------------------------------------------------
# Iterate through proteins and parse the dssp file
#-------------------------------------------------- 
my $filecount = 0;
my $chain_count = 0;

for my $id (@shuffled_protein_ids) {
	my $dssp_file = File::Spec->catfile($dssp_dir.'/'.(substr $id, 1, 2), "pdb$id.dssp");
	say sprintf("Parsing %s (%d/%d)", $dssp_file, ++$filecount, scalar(@shuffled_protein_ids));

	my $parser = Prot::Parser::Dssp->new;
	$parser->parse($dssp_file);
	
	#--------------------------------------------------
	# Iterate through chains
	#-------------------------------------------------- 
	foreach my $chain (@{$proteins{$id}}) {
		$chain_count++;

		say OUT "ID $id:$chain";
		say OUT $header;

		my $res_string = $parser->seq($chain);
		my @res_seq = split //, $res_string;
		my @ss_seq = split //, ($parser->ss($chain));

		my $pos = -1;
		while (++$pos < scalar(@res_seq)) {
			my @profile = empty_array($num_as);
			$profile[aa2number($res_seq[$pos])] = 1;

			my @outputs = empty_array($num_ss);
			$outputs[ss2number($ss_seq[$pos])] = 1;

			say OUT "DP\t$pos\t$res_seq[$pos]\t$ss_seq[$pos]\t".(join "\t", @profile)."\t".(join "\t", @outputs);
		}
	}
}

#--------------------------------------------------
# Closing filehandles
#-------------------------------------------------- 
close OUT;

#--------------------------------------------------
# Little helpers
#-------------------------------------------------- 
sub empty_array {
	my $size = shift;

	my @array;
	foreach (1..$size) {
		push @array, 0;
	}

	return @array;
}

sub output_to_ss {
	my ($h, $e, $l) = @_;
	
	my $maxpos = -1;
	if ($h >= $e && $h >= $l) {
		$maxpos = 0;
	}
	elsif ($e >= $h && $e >= $l) {
		$maxpos = 1;
	}
	elsif ($l >= $h && $l >= $e) {
		$maxpos = 2;
	}

	return ss2number($maxpos);
}
