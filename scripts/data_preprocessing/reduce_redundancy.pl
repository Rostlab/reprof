#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use File::Path qw(make_path remove_tree);
use File::Copy;

my $retain_file;
my $reduce_file;
my $out_file = "./out.fasta";
my $blast_bin = "blast2";
my $threshold = 0.0;

GetOptions(
    'retain=s'    =>  \$retain_file,
    'reduce=s'    =>  \$reduce_file,
    'out=s'       =>  \$out_file,
);

my $pid = $$;
say $pid;
my $tmp_dir = "/tmp/$pid/";
my $tmp_fasta = "$tmp_dir/tmp.fasta";
my $tmp_reduce_file = "$tmp_dir/reduce.fasta";

make_path $tmp_dir;
copy $reduce_file, $tmp_reduce_file;
say `formatdb -i $tmp_reduce_file`;

my @hvals;
open FASTA, $retain_file or confess "fh error\n";
while (my $header = <FASTA>) {
    my $sequence = <FASTA>;
    chomp $header;
    chomp $sequence;

    say $header;
    
    open FASTA_TMP, "> $tmp_fasta" or confess "fh error\n";
    say FASTA_TMP $header;
    say FASTA_TMP $sequence;
    close FASTA_TMP;

    my @blast = `$blast_bin -p blastp -d $tmp_reduce_file -i $tmp_fasta -e 1e7`;
    chomp @blast;

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

            push @hvals, [$query, $target, $hval];
        }
    }
}
close FASTA;

open FH, $reduce_file or confess "fh error\n";
my %sequences;
while (my $header = <FH>) {
    my $sequence = <FH>;
    chomp $header;
    chomp $sequence;
    my $id = substr $header, 1;

    $sequences{$id} = $sequence;
}
close FH;

foreach my $line (@hvals) {
    my ($query, $target, $hval) = @$line;
    if ($hval > $threshold) {
        if (exists $sequences{$target}) {
            delete $sequences{$target};
            warn "$target deleted $hval\n";
        }
        else {
            warn "$target deleted again $hval\n";
        }
    }
}

open OUT, "> $out_file" or confess "fh error\n";
foreach my $id (keys %sequences) {
    say OUT ">$id";
    say OUT $sequences{$id};
}
close OUT;

remove_tree $tmp_dir;
