#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use Reprof::Parser::ent;
use Reprof::Source::ent;

my $list_file = shift;
my $min_length = 45;

#my %list_hash;
my @list;
open LIST, $list_file or croak "fh error\n";
while (my $line = <LIST>) {
    chomp $line;
    push @list, lc $line;
    #$list_hash{lc $line} = 1;
}
close LIST;
#my @list = keys %list_hash;

my $modeled = 0;
foreach my $entry (@list) {
    my ($file, $chain) = Reprof::Source::ent->rost_db($entry);
    if (! -e $file) {
        warn "$file not found\n";
        next;
    }
    #warn "file: $file";
    my $parser = Reprof::Parser::ent->new($file);


    foreach my $chain (@{$parser->get_chains()}) {
        my $id = "$entry:$chain";
        my @res = $parser->res($chain);

        if ($parser->has_model()) {
            $modeled++;
            next;
        }
        elsif (scalar @res < $min_length) {
            next;
        }

        say ">$id";
        say join "", @res;
    }

}

warn "modeled: $modeled\n";
