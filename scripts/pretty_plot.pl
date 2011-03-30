#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Uses gnuplot to draw a lineplot of
#           one or more input files using several 
#           columns.
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);

#--------------------------------------------------
# Open gnuplot 
#-------------------------------------------------- 
open GP, "| gnuplot -persist" or die "Could not find gnuplot binary...\n";
select GP;
$|++;

my @files;
my @cols;

my @col_tmp;
my $params = "w lines";

my %opts = (xlabel => "epoch",
            ylabel => "Q3",
            title   => "Q3 on train-, valid-, testsets" );

#--------------------------------------------------
# Gather files, columns and opts
#-------------------------------------------------- 
foreach my $arg (@ARGV) {
	if (-e $arg) {
		push @files, $arg;
	}
    elsif ($arg =~ /^-/) {
        my $sstr = substr $arg, 1;
        my ($k, $v) = split /=/, $sstr;
        
        $opts{$k} = $v;
    }
	else {
		push @col_tmp, $arg;
		if (scalar @col_tmp == 2) {
			push @cols, [@col_tmp];
			@col_tmp = ();
		}
	}
}

my $script = "set term x11;";

while (my ($k, $v) = each %opts) {
    $script .= "set $k \"$v\";";
}

$script .= "plot ";
foreach my $file (@files) {
	foreach my $col (@cols) {
		$script .= "\"$file\" using " . (join ':', @$col) . " $params, ";
	}
}

$script =~ s/, $/;/;

say $script;

close GP;
