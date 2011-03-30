#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Produces sets for the reprof neural
#           network structure layer using several 
#           data resources 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

use AI::FANN qw(:all);
use Getopt::Long;
use Reprof::Tools::Translator qw(id2pdb aa2number ss2number);
use Reprof::Parser::Dssp;
use File::Spec;
use List::Util qw(shuffle);

my $sets_in; 
my $out_dir;
my $num_sets;
my $prefix = "set_";

my $num_desc = 3; # DP number as ss 
my $num_as = 21;
my $num_ss = 3;

my $debug = 0;

GetOptions(     'out=s' 	=> \$out_dir,
                'fasta=s'	=> \$fasta_file,
                'pssm=s'	=> \$pssm_dir,
                'dssp=s'	=> \$dssp_dir,
                'sets=i'	=> \$num_sets,
                'prefix=s'	=> \$prefix,
                'debug'		=> \$debug);

unless ($out_dir && $fasta_file && $pssm_dir && $dssp_dir && $num_sets) {
    say "\nDESC:\nproduces sets for the reprof neural network using several data resources";
    say "\nUSAGE:\n$0 -out <outputdir> -fasta <fastafile> -pssm <pssmdir> -dssp <dsspdir> -sets <numsets> -prefix <setprefix>";
    say "\nOPTS:\nfastafile:\n\tids which are used to create the sets\nsets:\n\tnumber of sets which are created\nprefix:\n\tthe prefix which should be in front of the set files (default: set_)\n";
    die "Invalid options";
}

#--------------------------------------------------
# Load fasta and store ids in hash
#-------------------------------------------------- 
say "Getting ids/chains from fasta...";
my %proteins;
open FASTA, $fasta_file or die "Could not open $fasta_file\n";
while (<FASTA>) {
	if (/^>/) {
		my $id = substr $_, 1;
                chomp $id;
		$proteins{$id}++;
	}
}
close FASTA;
say "".(scalar keys %proteins)." ids found in fasta file...";

#--------------------------------------------------
# Shuffle proteins/chains
#-------------------------------------------------- 
say "Shuffling proteins...";
my @shuffled_protein_ids = shuffle(keys %proteins);

#--------------------------------------------------
# Open outputfiles and write headers
#-------------------------------------------------- 
my @out_fhs;
foreach (1 .. $num_sets) {
    my $fh;
    open $fh, '>', (File::Spec->catfile($out_dir, "$prefix.$_.set"));
    say $fh "HD\t$num_desc\t$num_as\t$num_ss";
    push @out_fhs, $fh;
}


#--------------------------------------------------
# Iterate through proteins, gather data from DSSP
# and PSSM files, write output
#-------------------------------------------------- 
my $filecount = 0;
my $faulty = 0;
my $current_fh;

for my $chainid (@shuffled_protein_ids) {
    #--------------------------------------------------
    # shift the filehandle out of the array and 
    # put it back in at the end to circulate
    #-------------------------------------------------- 
    $current_fh = shift @out_fhs;
    push @out_fhs, $current_fh;
    
    my ($id, $chain) = split /:/, $chainid;
    say $current_fh "ID $id:$chain";

    my $dssp_file = File::Spec->catfile($dssp_dir.'/'.(substr $id, 1, 2), "pdb$id.dssp");
    my $pssm_file = File::Spec->catfile($pssm_dir.'/'. "$id:$chain.pssm");

    unless (-e $dssp_file) {
        warn "$dssp_file does not exist\n" unless -e $dssp_file;
        $faulty++;
        next;
    }
    unless (-e $pssm_file) {
        warn "$pssm_file does not exist\n" unless -e $pssm_file;
        $faulty++;
        next;
    }

    say sprintf("Parsing %s %s (%d/%d)", $dssp_file, $pssm_file, ++$filecount, scalar(@shuffled_protein_ids));

    #--------------------------------------------------
    # DSSP
    #-------------------------------------------------- 

    my $parser = Reprof::Parser::Dssp->new;
    $parser->parse($dssp_file);

    unless ( defined $parser->ss($chain)) {
        $faulty++;
        warn "Something is wrong with $id:$chain (dssp)\n";
        next;
    }

    my @ss_seq = split //, ($parser->ss($chain));

    #--------------------------------------------------
    # PSSM and output
    #-------------------------------------------------- 
    open PSSM, $pssm_file or die "Could not open $pssm_file ...\n";
    my @pssm_cont = grep /^\s+\d+/, (<PSSM>);
    chomp @pssm_cont;
    close PSSM;

    if (scalar @pssm_cont <= 1) {
        $faulty++;
        warn "Something is wrong with $id:$chain (pssm)\n";
        next;
    }

    
    my $pos = 0;
    foreach my $line (@pssm_cont) {
        my @split = split /\s+/, $line;
        
        #--------------------------------------------------
        # Input 
        #-------------------------------------------------- 
        # print DP, the position, the residue name and the ss  
        print $current_fh "DP\t$pos\t" . "$split[2]\t" . $ss_seq[$pos] . "\t";

        # print the pssm normalized pssm values
        foreach my $iter (3 .. 2+$num_as) {
            print $current_fh "".(sprintf "%.4f", normalize_pssm($split[$iter])) . "\t";
        }

        # add position in protein
        print $current_fh sprintf "%.4f\t", ($pos / scalar @pssm_cont);

        #--------------------------------------------------
        # Output 
        #-------------------------------------------------- 
        # print the output (ss) values as triple
        my @tmp_ss = empty_array(3);
        $tmp_ss[ss2number($ss_seq[$pos])] = 1;
        say $current_fh (join "\t", @tmp_ss);

        $pos++;
    }
}

#--------------------------------------------------
# Closing filehandles
#-------------------------------------------------- 
foreach my $fh (@out_fhs) {
    close $fh;
}
say "$faulty faulty ids...";

#--------------------------------------------------
# Little helpers
#-------------------------------------------------- 



#--------------------------------------------------
# name:        normalize_pssm
# args:        pssm value
# return:      normalized pssm value
#-------------------------------------------------- 
sub normalize_pssm {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

#--------------------------------------------------
# name:        empty_array
# args:        size of the resulting array
# return:      an array of given length filled with
#              zeroes 
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
