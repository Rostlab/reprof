#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

use Reprof::Tools::Set;
use Reprof::Parser::Set;
use Reprof::Tools::Converter qw(convert_ss);


my ($infile, $win) = @ARGV;

my $set_parser = Reprof::Parser::Set->new($infile);
my $set = $set_parser->get_set;
$set->win($win);

while (my $dp = $set->next_dp) {
#print $dp->[2][0];
print convert_ss($dp->[2], "num") / 2;

    my $num = 1;
    foreach my $p (@{$dp->[1]}) {
        print "\t";
        print "$num:$p";

        ++$num;
    }
    print "\n";
}
