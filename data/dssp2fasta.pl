#!/usr/bin/perl -w

use strict;
use File::Spec::Functions qw (catfile);
use Prot::Parser::Dssp;
use Getopt::Long;
use feature qw(say);

my $min_chain_length = 60;
my $dssp = '/mnt/project/rost_db/data/dssp/';
my $idfile;
my $outfile;
GetOptions(	"ids=s"	    => \$idfile,
                "min=s"	    => \$min_chain_length,
                "out=s"	    => \$outfile,
                "dssp=s"    => \$dssp );

open IDS, $idfile;
my @ids = <IDS>;
chomp @ids;
close IDS;

my $not_found_count = 0;
my $count = 0;

open OUT, '>', $outfile;
foreach (@ids) {
    say "Parsed $count files so far..." if ++$count % 100 == 0;

    my ($id) = split /\s+/, $_, 2;

    my $dsspfile = catfile $dssp .'/'. (substr $id, 1, 2), "pdb$id.dssp";
    my $parser = Prot::Parser::Dssp->new;
    if ($parser->parse($dsspfile)) {
        foreach my $chain ($parser->chains) {
            my $seq = $parser->seq($chain);
            if (length $seq >= $min_chain_length) {
                    printf OUT ">%s:%s\n%s\n", $parser->id, $chain, $seq;
            }
        }
    }
    else {
        warn "Could not find file $dsspfile\n";
        $not_found_count++;
    }
}
close OUT;

say "$not_found_count files could not be found...";
