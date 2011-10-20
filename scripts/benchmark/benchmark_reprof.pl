#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Carp;
use Getopt::Long;
use POSIX qw(floor);

use List::Util qw(sum);

use Reprof::Source::reprof;
use Reprof::Parser::reprof;
use Reprof::Source::dssp;
use Reprof::Parser::dssp;
use Reprof::Measure;

use Reprof::Source::profRdb;

use Reprof::Source::blastPsiMat;
use Reprof::Source::psic;
use Reprof::Source::fasta;

my $fasta_file;
my $out_dir;
my $db_file;
my $max_blast_hits = 5;

GetOptions(
    'db|d=s'    =>  \$db_file,
    'fasta|f=s' =>  \$fasta_file,
    'out|o=s'   =>  \$out_dir,
);

my $sec_avg_per_res = Reprof::Measure->new(3);
my $sec_dist;
my $sec_length;
my $sec_HvsE;
my $sec_ri_cum;
my $sec_avg_sums = [0, 0, 0, 0, 0, 0, 0];
my $sec_blast_prot = {};
my $seq_blast_res = {};

foreach my $i (0 .. 100) {
    $sec_dist->{q3}->{$i} = 0;
    $sec_dist->{pH}->{$i} = 0;
    $sec_dist->{pE}->{$i} = 0;
    $sec_dist->{pL}->{$i} = 0;
    $sec_dist->{rH}->{$i} = 0;
    $sec_dist->{rE}->{$i} = 0;
    $sec_dist->{rL}->{$i} = 0;

    $sec_blast_prot->{$i}{blast} = 0;
    $seq_blast_res->{$i}{blast} = Reprof::Measure->new(3);
    $sec_blast_prot->{$i}{reprof} = 0;
    $seq_blast_res->{$i}{reprof} = Reprof::Measure->new(3);
}
foreach (0 .. 9) {
    push @$sec_ri_cum, Reprof::Measure->new(3);
}

my $count = 0;
open FASTA, $fasta_file or croak "Could not open $fasta_file\n";
while (my $header = <FASTA>) {

    chomp $header;
    my $id = substr $header, 1;
    my $sequence = <FASTA>;
    chomp $sequence;


    #my $reprof_file = Reprof::Source::reprof->reprof($id, $sequence);
    my $reprof_file = Reprof::Source::profRdb->predictprotein($id, $sequence);
    if (!-e $reprof_file) {
        warn "$reprof_file not found, predicting...\n";

        my $blastPsiMat_file = Reprof::Source::blastPsiMat->predictprotein($id, $sequence);
        my $psic_file = Reprof::Source::psic->predictprotein($id, $sequence);
        my $fasta_file2 = Reprof::Source::fasta->predictprotein($id, $sequence);

        my $cmd = "/mnt/project/reprof/scripts/reprof.pl -fasta $fasta_file2 -blastPsiMat $blastPsiMat_file -psic $psic_file -out $reprof_file";
        #say $cmd;
        say `$cmd`;
    }
    $count++;
    my $reprof_parser = Reprof::Parser::reprof->new($reprof_file);

    my @PHEL_3state = $reprof_parser->PHEL_3state;
    my @RI_S = $reprof_parser->RI_S;
    my $length = scalar @PHEL_3state;
    
    my ($dssp_file, $chain) = Reprof::Source::dssp->rost_db($id, $sequence);
    my $dssp_parser = Reprof::Parser::dssp->new($dssp_file);
    my @sec_3state = $dssp_parser->sec_3state($chain);

    my $prot_measure = Reprof::Measure->new(3);

    #--------------------------------------------------
    # BLAST 
    #-------------------------------------------------- 
    my $fasta_tmp = "./fasta_tmp.fasta";
    open FASTA_TMP, ">", $fasta_tmp or croak "Could not open $fasta_tmp\n";
    say FASTA_TMP $header;
    say FASTA_TMP $sequence;
    close FASTA_TMP;

    my @blast_out = `blastall -p blastp -d $db_file -i $fasta_tmp`;
    chomp @blast_out;
    my $target_id;
    my $query_align;
    my $sbjct_align;
    my $align_length;
    my $identities;
    my $gaps;
    my $query_start = -1;
    my $sbjct_start = -1;
    my $hits = 0;
    foreach my $line (@blast_out) {
        #say $line;
        if ($line =~ /^>|Matrix:/) {
            if ($query_start != -1) {
                if ($hits < $max_blast_hits) {
                    my ($dssp_blast_file, $dssp_blast_chain) = Reprof::Source::dssp->rost_db($target_id);
                    my $dssp_blast_parser = Reprof::Parser::dssp->new($dssp_blast_file);
                    my @sec_blast_3state = $dssp_parser->sec_3state($chain);
                    

                    my $l = $align_length - $gaps;
                    my $pid = floor(($identities * 100) / $l);

                    #say "### ti: ".$target_id;
                    #say "### qs: ".$query_start;
                    #say "### qa: ".$query_align;
                    #say "### ss: ".$sbjct_start;
                    #say "### sa: ".$sbjct_align;
                    #say "### al: ".$align_length;
                    say "### id: ".$pid;

                    foreach my $i (0 .. length $query_align - 1) {

                    }

                    $hits++;
                }
            }

            $target_id = substr $line, 1, 6;
            $query_align = "";
            $sbjct_align = "";
            $query_start = -1;
            $sbjct_start = -1;
        }
        elsif ($line =~ m/Identities = (\d+)\/(\d+).*Gaps = (\d+)\/\d+/) {
            $identities = $1;
            $align_length = $2;
            $gaps = $3;
        }
        elsif ($line =~ m/Identities = (\d+)\/(\d+)/) {
            $identities = $1;
            $align_length = $2;
            $gaps = 0;
        }
        elsif ($line =~ m/^Query:\s+(\d+)\s+(.+)\s+(\d+)/) {
            $query_start = $1 if $query_start == -1;
            $query_align .= $2;
        }
        elsif ($line =~ m/^Sbjct:\s+(\d+)\s+(.+)\s+(\d+)/) {
            $sbjct_start = $1 if $sbjct_start == -1;
            $sbjct_align .= $2;
        }
        elsif ($line =~ m/Matrix:/) {

        }
    }
    exit;

    #--------------------------------------------------
    # plots 
    #-------------------------------------------------- 
    my $observed_H = 0;
    my $predicted_H = 0;
    my $observed_E = 0;
    my $predicted_E = 0;
    foreach my $i (0 .. $length - 1) {
        $prot_measure->add($sec_3state[$i], $PHEL_3state[$i]);
        $sec_avg_per_res->add($sec_3state[$i], $PHEL_3state[$i]);

        #--------------------------------------------------
        # RI 
        #-------------------------------------------------- 
        my $ri_s = $RI_S[$i];
        foreach my $ri (0 .. $ri_s) {
            $sec_ri_cum->[$ri]->add($sec_3state[$i], $PHEL_3state[$i]);
        }


        #--------------------------------------------------
        # HvsE 
        #-------------------------------------------------- 
        if ($sec_3state[$i]->[0] == 1) {
            $observed_H++;
        }
        elsif ($sec_3state[$i]->[1] == 1) {
            $observed_E++;
        }

        if ($PHEL_3state[$i]->[0] == 1) {
            $predicted_H++;
        }
        elsif ($PHEL_3state[$i]->[1] == 1) {
            $predicted_E++;
        }
    }
    my $q3 = $prot_measure->Qn;
    my @precisions = $prot_measure->precisions;
    my @recalls = $prot_measure->recalls;

    $sec_avg_sums->[0] += $q3;
    $sec_avg_sums->[1] += $precisions[0];
    $sec_avg_sums->[2] += $precisions[1];
    $sec_avg_sums->[3] += $precisions[2];
    $sec_avg_sums->[4] += $recalls[0];
    $sec_avg_sums->[5] += $recalls[1];
    $sec_avg_sums->[6] += $recalls[2];

    #--------------------------------------------------
    # HvsE 
    #-------------------------------------------------- 
    my $observed_HvsE = ($observed_H / ($observed_H + $observed_E)) - ($observed_E / ($observed_H + $observed_E));
    my $predicted_HvsE = ($predicted_H / ($predicted_H + $predicted_E)) - ($predicted_E / ($predicted_H + $predicted_E));
    push @$sec_HvsE, [$observed_HvsE, $predicted_HvsE];

    #--------------------------------------------------
    # length plots 
    #-------------------------------------------------- 
    foreach my $i (0 .. $length) {
        $sec_length->{$i} = [] if ! exists $sec_length->{$length};
    }
    push @{$sec_length->{$length}}, $prot_measure;

    #--------------------------------------------------
    # dist plots 
    #-------------------------------------------------- 
    my $q3_bin = int($q3 * 100);
    $sec_dist->{q3}->{$q3_bin} = 0 if ! exists $sec_dist->{q3}->{$q3_bin};
    $sec_dist->{q3}->{$q3_bin}++;
    
    my $pH_bin = int($precisions[0] * 100);
    $sec_dist->{pH}->{$pH_bin} = 0 if ! exists $sec_dist->{pH}->{$pH_bin};
    $sec_dist->{pH}->{$pH_bin}++;
    
    my $pE_bin = int($precisions[1] * 100);
    $sec_dist->{pE}->{$pE_bin} = 0 if ! exists $sec_dist->{pE}->{$pE_bin};
    $sec_dist->{pE}->{$pE_bin}++;
    
    my $pL_bin = int($precisions[2] * 100);
    $sec_dist->{pL}->{$pL_bin} = 0 if ! exists $sec_dist->{pL}->{$pL_bin};
    $sec_dist->{pL}->{$pL_bin}++;
    
    my $rH_bin = int($recalls[0] * 100);
    $sec_dist->{rH}->{$rH_bin} = 0 if ! exists $sec_dist->{rH}->{$rH_bin};
    $sec_dist->{rH}->{$rH_bin}++;
    
    my $rE_bin = int($recalls[1] * 100);
    $sec_dist->{rE}->{$rE_bin} = 0 if ! exists $sec_dist->{rE}->{$rE_bin};
    $sec_dist->{rE}->{$rE_bin}++;
    
    my $rL_bin = int($recalls[2] * 100);
    $sec_dist->{rL}->{$rL_bin} = 0 if ! exists $sec_dist->{rL}->{$rL_bin};
    $sec_dist->{rL}->{$rL_bin}++;
    
}

#--------------------------------------------------
# totals 
#-------------------------------------------------- 
say join " ", "Averages per residue:", $sec_avg_per_res->Qn, $sec_avg_per_res->precisions, $sec_avg_per_res->recalls;

foreach my $val (@$sec_avg_sums) {
    $val /= $count;
}

say join " ", "Averages per chain:", @$sec_avg_sums;

#--------------------------------------------------
# data files output 
#-------------------------------------------------- 
open Q3_DIST, "> ./q3_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{q3}}) {
    say Q3_DIST "$bin\t$sec_dist->{q3}{$bin}";
}
close Q3_DIST;

open PH_DIST, "> ./pH_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{pH}}) {
    say PH_DIST "$bin\t$sec_dist->{pH}{$bin}";
}
close PH_DIST;

open PE_DIST, "> ./pE_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{pE}}) {
    say PE_DIST "$bin\t$sec_dist->{pE}{$bin}";
}
close PE_DIST;

open PL_DIST, "> ./pL_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{pL}}) {
    say PL_DIST "$bin\t$sec_dist->{pL}{$bin}";
}
close PL_DIST;

open RH_DIST, "> ./rH_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{rH}}) {
    say RH_DIST "$bin\t$sec_dist->{rH}{$bin}";
}
close RH_DIST;

open RE_DIST, "> ./rE_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{rE}}) {
    say RE_DIST "$bin\t$sec_dist->{rE}{$bin}";
}
close RE_DIST;

open RL_DIST, "> ./rL_dist.data" or croak "Could not open file \n";
foreach my $bin (sort {$a <=> $b} keys %{$sec_dist->{rL}}) {
    say RL_DIST "$bin\t$sec_dist->{rL}{$bin}";
}
close RL_DIST;

open LENGTH, "> length.data" or croak "Could not open file\n";
my $iter = 0;
foreach my $l (sort {$a <=> $b} keys %$sec_length) {
    my $avg_q3 = 0;
    my $avg_pH = 0;
    my $avg_pE = 0;
    my $avg_pL = 0;
    my $avg_rH = 0;
    my $avg_rE = 0;
    my $avg_rL = 0;
    my $m_length = 0;
    foreach my $i (0 .. $l) {
        my $measures = $sec_length->{$i};
        $m_length += scalar @$measures;
        foreach my $m (@$measures) {
            my $q3 = $m->Qn;
            my @precisions = $m->precisions;
            my @recalls = $m->recalls;

            $avg_q3 += $q3;
            $avg_pH += $precisions[0];
            $avg_pE += $precisions[1];
            $avg_pL += $precisions[2];
            $avg_rH += $recalls[0];
            $avg_rE += $recalls[1];
            $avg_rL += $recalls[2];
        }
    }
    if ($m_length > 0) {
        $avg_q3 /= $m_length;
        $avg_pH /= $m_length;
        $avg_pE /= $m_length;
        $avg_pL /= $m_length;
        $avg_rH /= $m_length;
        $avg_rE /= $m_length;
        $avg_rL /= $m_length;
    }

    say LENGTH join "\t", $l, $avg_q3, $avg_pH, $avg_pE, $avg_pL, $avg_rH, $avg_rE, $avg_rL;
    $iter++;
}
close LENGTH;

open RI_DIST_CUM, "> ri_dist_cum.data" or croak "Could not open file\n";
foreach my $i (0 .. scalar @$sec_ri_cum - 1) {
    my $size = $sec_ri_cum->[$i]->num_points;
    say RI_DIST_CUM join "\t", $i, $size, $sec_ri_cum->[$i]->Qn, $sec_ri_cum->[$i]->precisions, $sec_ri_cum->[$i]->recalls; 
}
close RI_DIST_CUM;

open HvsE, "> hvse.data" or croak "Could not open file\n";
foreach my $pair (@$sec_HvsE) {
    say HvsE join "\t", @$pair;
}
close HvsE;

sub plot {
    my $script_file = shift;

    open SCRIPT, $script_file or croak "Coult not open $script_file\n";
    my @script = <SCRIPT>;
    close SCRIPT;

    open GP, "| gnuplot" or croak "Could not open gnuplot\n";
    print GP @script;
    close GP;

}
