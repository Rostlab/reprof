#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use Pod::Usage;

my $data_file = "./data.file";
my $script_file = "./script.file.R";
my $pdf_file = "./result.pdf";

my $length = -1;
my $min = -1;
my $sec = -1;
open DATA, "> $data_file" or confess "fh error\n";
say DATA "length time res";
while (my $line = <>) {
    chomp $line;
    if ($line =~ m/^length (\d+)/) {
        $length = $1;
    }
    elsif ($line =~ m/^real\s+(\d+)m(\d+(\.\d+)?)s.*/) {
        $min = $1;
        $sec = $2;
        if ($length >= 0 && $min >= 0 && $sec >= 0) {
            say DATA "$length " . ($min + $sec / 60) . " " . (($min+$sec)/$length);
        }
        $length = -1;
        $min = -1;
        $sec = -1;
    }
}
close DATA;

open SCRIPT, "> $script_file" or confess "fh error\n";
say SCRIPT "data <- read.table(\"$data_file\", header=T, sep=\" \")";
say SCRIPT "pdf(\"$pdf_file\")";
say SCRIPT 'plot(data$length, data$time, type="s", xlab="length", ylab="time [min]")';
say SCRIPT 'loessfit1 <- loess(data$time ~ data$length)';
say SCRIPT 'lines(predict(loessfit1), col="red")';
say SCRIPT 'plot(data$length, data$res, type="s", xlab="length", ylab="time [min]")';
say SCRIPT 'loessfit2 <- loess(data$res ~ data$length)';
say SCRIPT 'lines(predict(loessfit2), col="red")';
say SCRIPT "dev.off()";
close SCRIPT;

say `Rscript $script_file`;
