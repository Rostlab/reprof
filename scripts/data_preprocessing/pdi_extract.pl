#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;

my $pdidb_file;
my $fasta_out;
my $bind_out;
my $min_length = 45;

GetOptions(
    'pdidb|p=s'    =>  \$pdidb_file,
    'fasta|f=s'    =>  \$fasta_out,
    'bind|b=s'    =>  \$bind_out,);

sub clean {
    my $string = shift;
    $string =~ s/^\s+//g;
    $string =~ s/\s+$//g;
    return $string;
}

open PDIDB, "$pdidb_file" or croak "fh error\n";
open FASTA, ">", "$fasta_out" or croak "fh error\n";
while (my $line = <PDIDB>) {
    next if $line =~ m/^#/;
    chomp $line;
    my @split = split /\t/, $line;

    my $id_string = clean $split[0];
    my $chain_string = clean $split[29];
    my $seq_string = clean $split[30];



    my $id = lc $id_string;
    my @chains = split /;/, $chain_string;
    my @sequences = split /;/, $seq_string;

    if (scalar @chains != scalar @sequences) {
        warn "warning: sequence and chain count are different\n";
    }

    my $chain_count = scalar @chains;
    foreach my $i (0 .. $chain_count - 1) {
        my $current_chain = $chains[$i];
        my $current_seq = $sequences[$i];

        if (length $current_seq >= $min_length) {
            say FASTA ">$id:$current_chain";
            say FASTA uc $current_seq;
        }

        open BIND, ">", "$bind_out/$id:$current_chain.bind";
        say BIND "#RES BINDING NOT_BINDING";
        my @split_seq = split //, $current_seq;
        foreach my $res (@split_seq) {
            my $lc_res = lc $res;
            my $uc_res = uc $res;

            if ($res eq $lc_res) {
                say BIND "$res 1 0";
            }
            elsif ($res eq $uc_res) {
                say BIND "$res 0 1";
            }
            else {
                warn "something weird happened";
            }
        }
        close BIND;
    }
}
close PDIDB;
close FASTA;
