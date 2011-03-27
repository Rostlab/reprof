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
my $pssm_dir;
my $include_file;
my $include_col;
my $exclude_file;
my $exclude_col;
my $fasta_file;
my $out_file;

my $num_desc = 3; # identifier number as ss
my $num_as = 20;
my $num_ss = 3;

my $debug = 0;

GetOptions(	'include=s'     => \$include_file,
                'includecol=s'	=> \$include_col,
                'exlude=s'	=> \$exclude_file,
                'excludecol=s'	=> \$exclude_col,
                'out=s'		=> \$out_file,
                'fasta=s'	=> \$fasta_file,
                'pssm=s'	=> \$pssm_dir,
                'dssp=s'	=> \$dssp_dir,
                'debug'		=> \$debug);

#--------------------------------------------------
# Load fasta
#-------------------------------------------------- 
say "Getting ids/chains from fasta...";
my %proteins;
open FASTA, $fasta_file or die "Could not open $fasta_file\n";
while (<FASTA>) {
	if (/^>/) {
		my $id = substr $_, 1, 7;
		$proteins{$id}++;
	}
}
close FASTA;

#--------------------------------------------------
# Shuffling proteins
#-------------------------------------------------- 
say "Shuffling proteins...";
my @shuffled_protein_ids = shuffle(keys %proteins);

#--------------------------------------------------
# Open outputfile and write description
#-------------------------------------------------- 
open OUT , ">", $out_file;
say OUT "HD\t$num_desc\t$num_as\t$num_ss";

#--------------------------------------------------
# Iterate through proteins and parse the dssp file
#-------------------------------------------------- 
my $filecount = 0;
my $chain_count = 0;

for my $chainid (@shuffled_protein_ids) {
    my ($id, $chain) = split /:/, $chainid;
    say "ID $id:$chain";

    my $dssp_file = File::Spec->catfile($dssp_dir.'/'.(substr $id, 1, 2), "pdb$id.dssp");
    my $pssm_file = File::Spec->catfile($pssm_dir.'/'. "$id:$chain.pssm");

#--------------------------------------------------
#     say sprintf("Parsing %s (%d/%d)", $dssp_file, ++$filecount, scalar(@shuffled_protein_ids));
#-------------------------------------------------- 


    #--------------------------------------------------
    # DSSP
    #-------------------------------------------------- 
    my $parser = Prot::Parser::Dssp->new;
    $parser->parse($dssp_file);

    my @ss_seq = split //, ($parser->ss($chain));

    #--------------------------------------------------
    # PSSM
    #-------------------------------------------------- 
    open PSSM, $pssm_file or die "Could not open $pssm_file ...\n";
    my @pssm_cont = grep /^\s+\d+/, (<PSSM>);
    chomp @pssm_cont;
    close PSSM;
    
    my $pos = 0;
    foreach my $line (@pssm_cont) {
        my @split = split /\s+/, $line;
        print "$pos\t" . "$split[2]\t" . $ss_seq[$pos] . "\t";
        foreach my $iter (3 .. 2+$num_as) {
            print "".(sprintf "%.3f", normalize_pssm($split[$iter])) . "\t";
        }

        print "\n";
        $pos++;
    }
    print "\n";
}

#--------------------------------------------------
# Closing filehandles
#-------------------------------------------------- 
close OUT;

#--------------------------------------------------
# Little helpers
#-------------------------------------------------- 
sub normalize_pssm {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

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
