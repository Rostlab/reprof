#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Data::Dumper;

use Reprof::Parser::Dssp;

my $dssp = shift;

if (!-e $dssp) {
    warn "Could not find $dssp\n";
    $dssp = "/mnt/project/rost_db/data/dssp/".(substr $dssp, 1, 2)."/pdb$dssp.dssp";
    warn "Trying $dssp\n";
}

my $parser = Reprof::Parser::Dssp->new($dssp);

foreach my $chain ($parser->get_chains) {
    my $data = $parser->get_fields($chain, qw(id pos res ss acc));
    say Dumper($data);
}

say "---";
foreach my $chain ($parser->get_chains) {
    say $chain;
}
