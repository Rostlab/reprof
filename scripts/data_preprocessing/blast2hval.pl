#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $blast_file;

GetOptions(
    'blast|b=s'    =>  \$blast_file,
);

open BLAST, $blast_file or croak "Could not open $blast_file\n";
my @blast = <BLAST>;
chomp @blast;
close BLAST;

my $query;
my $target;
my $length;
my $identities;
my $gaps;

my $head_started = 0;
foreach my $line (@blast) {
    if ($line =~ m/^Query= (.*)/) {
        $query = $1;
    }
    elsif ($line =~ m/^>(.*)/) {
        $target = $1;
        $head_started = 1;
    }
    elsif ($line =~ m/Length = /) {
        $head_started = 0;
    }
    elsif ($head_started) {
        $line =~ s/^\s+//g;
        $target .= " $line";
    }
    elsif ($line =~ m/Identities = (\d+)\/(\d+).*/) {
        $identities = $1;
        $length = $2;

        if ($line =~ m/Gaps = (\d+)\/\d+/) {
            $gaps = $1;
        }
        else {
            $gaps = 0;
        }

        if (! defined $gaps) {
            warn "Error while parsing\n";
        }

        my $L = $length - $gaps;
        my $PID = ($identities * 100) / $L;

        my $hval;
        if ($L <= 11) {
            $hval = $PID - 100;
        }
        elsif ($L <= 450) {
            my $exp = -0.32 * (1 + exp(-1 * (1 / 1000)));
            $hval = $PID - 480 * ($L ** $exp);
        }
        else {
            $hval = $PID - 19.5;
        }

        say "$query||||||||||$target||||||||||$hval";
    }
}
