#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     Given a merged and the two original 
#           fasta files, splits the merged file
#           according to the original files. 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
use strict;
use feature qw(say);
use Getopt::Long;
use Data::Dumper;

my $fasta1;
my $fasta2;
my $fastamerged;
my $out1;
my $out2;

GetOptions( 'fasta1=s'    =>  \$fasta1,
            'fasta2=s'    =>  \$fasta2,
            'out1=s'      =>  \$out1,
            'out2=s'      =>  \$out2,
            'merged=s'    =>  \$fastamerged );

unless ($fasta1 && $fasta2 && $out1 && $out2 && $fastamerged) {
    say "desc:\nsplit a fasta file according to the ids in 2 original files";
    say "usage:\n$0 -fasta1 <original1> -fasta2 <original2> -merged <mergedfile> -out1 <outfile1> -out2 <outfile2>";
    die "Invalid call\n;" 
}

#--------------------------------------------------
# Extract the ids from the original fata files 
#-------------------------------------------------- 
my $fasta1ids = extract_ids($fasta1);
my $fasta2ids = extract_ids($fasta2);

open FASTA, $fastamerged or die "Could not open $fastamerged ...\n";
open OUT1, '>', $out1 or die "Could not open $out1 ...\n";
open OUT2, '>', $out2 or die "Could not open $out2 ...\n";

while (my $line = <FASTA>) {
    if ($line =~ /^>/) {
        chomp $line;
        my $id = substr $line, 1, 7;

        #--------------------------------------------------
        # Print the header and the sequence to the 
        # desired file according to the id hashes 
        #-------------------------------------------------- 
        if (exists $fasta1ids->{$id}) {
            say OUT1 $line;
            my $nextline = <FASTA>;
            print OUT1 $nextline;
        }
        elsif (exists $fasta2ids->{$id}) {
            say OUT2 $line;
            my $nextline = <FASTA>;
            print OUT2 $nextline;
        }
        else {
            die "Something weird happened...";
        }
    }
}

close FASTA;
close OUT1;
close OUT2;

#--------------------------------------------------
# name:        extract_ids
# args:        filename of fastafile
# return:      hashref with ids as keys
#-------------------------------------------------- 
sub extract_ids {
    my $file = shift;
    open IN, $file or die "Could not open $file ...\n";
    my %ids;
    while (my $line = <IN>) {
        if ($line =~ /^>/) {
            chomp $line;
            my $id = substr $line, 1, 7;
            $ids{$id} = 1;
        }
    }
    close IN;

    return \%ids;
}
