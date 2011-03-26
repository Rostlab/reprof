#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;
use File::Spec;
use Prot::Tools::Translator qw(id2pdb);
use Prot::Parser::Pdb;


my $pdbdir = '/mnt/project/rost_db/data/pdb/';
my $infile = '/mnt/project/rost_db/data/pdb/pdb_entry_type.txt';
my $outfile = './pdb_entry_type_extended.txt';
my $regexp = '\sprot\s(diffraction|NMR)';
GetOptions(
            'in=s'	=> \$infile,
            'out=s'	=> \$outfile,
            'regex=s'	=> \$regexp,
            'pdb=s'	=> \$pdbdir );

open IN, $infile;
my @input = grep /$regexp/, (<IN>);
chomp @input;
close IN;

open OUT, ">", $outfile;
foreach my $in (@input) {
        my ($id) = split /\s+/, $in, 2;
	my $parser = Prot::Parser::Pdb->new;
	my $file = File::Spec->catfile($pdbdir, (substr $id, 1, 2) . "/pdb$id.ent");

        say "Parsing $file...";

	$parser->parse($file, 1);

	my $resolution = $parser->resolution || '-1';

        say OUT "$in\t$resolution";
}
close OUT;

