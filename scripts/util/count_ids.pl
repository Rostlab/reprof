#!/usr/bin/perl -w
use strict;
use feature qw(say);

my $in = shift;
open IN, $in;
my @in = <IN>;
close IN;

my %ids;
foreach my $line (@in) {
	if ($line =~ /^>/) {
		my $id = substr $line, 1, 4;
		$ids{$id}++;
	}
}

say "Number of distinct ids (not chains): " . (scalar(keys %ids));
