#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;

my $fasta_file = shift;

open FH, $fasta_file or croak "fh error\n";
my @content = <FH>;
chomp @content;
close FH;

my $current_header;
my %head2seq;
foreach my $line (@content) {
    if ($line =~ m/^>/) {
        $current_header = substr $line, 1;
        if (exists $head2seq{$current_header}) {
            warn "double header $current_header";
        }
        $head2seq{$current_header} = "";
    }
    else {
        $head2seq{$current_header} .= $line;
    }
}

my @needed_files = qw(profRdb profbval mdisorder coils coils_raw isis);

foreach my $file (@needed_files) {
    $file = ".$file\$";
}
my $files = join "|", @needed_files;
my $num_files = scalar @needed_files;

my $found = 0;
my $not_found = 0;
foreach my $id (keys %head2seq) {
    my $seq = $head2seq{$id};
    my @out = grep /$files/, `ppc_fetch --seq=$seq`;
    chomp @out;
    if (scalar @out < $num_files) {
        say "found ".(scalar @out).", but needs $num_files";
        say $seq;
        foreach my $o (@out) {
            say $o;
        }
        
        open FH, "> job.sh" or croak "File error\n";
        say FH join "\n", 
            "#!/bin/sh",
            "predictprotein --target=all --seq=$seq";
        close FH;
        say `qsub job.sh`;
        $not_found++;
    }
    else {
        $found++;
    }

}

say "found: $found, not found: $not_found";
