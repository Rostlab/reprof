#!/usr/bin/perl -w
use strict;

use Getopt::Std;
use feature qw(say);
use File::Copy;
use File::Spec;

my %opts;
getopts('i:o:n:', \%opts);

my $idir = $opts{i};
my $odir = $opts{o};
my $n = $opts{n};

my %chosen;

opendir IDIR, $idir;
my @idir = readdir IDIR;
close IDIR;

while (keys %chosen != $n) {
	my $ifile = File::Spec->catfile($idir, $idir[rand(@idir)]);
	say $ifile;
	$chosen{$ifile} = 1 unless -d $ifile;
}

foreach (keys %chosen) {
	say "moving $_ to $odir";
	move $_, $odir;
}
