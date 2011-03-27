#!/usr/bin/perl -w

use strict;
use feature qw(say);

open GP, "| gnuplot -persist" or die "Could not find gnuplot binary...\n";
select GP;
$|++;

my @files;
my @cols;

my @col_tmp;
my $params = "w lines";

foreach my $arg (@ARGV) {
	if (-e $arg) {
		push @files, $arg;
	}
	else {
		push @col_tmp, $arg;
		if (scalar @col_tmp == 2) {
			push @cols, [@col_tmp];
			@col_tmp = ();
		}
	}
}

my $script = "set term x11; plot ";
foreach my $file (@files) {
	foreach my $col (@cols) {
		$script .= "\"$file\" using " . (join ':', @$col) . " $params, ";
	}
}

$script =~ s/, $/;/;

say $script;

close GP;
