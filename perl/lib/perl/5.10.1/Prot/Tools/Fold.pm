package Prot::Tools::Fold;

use strict;
use feature qw(say);
use Data::Dumper;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(data2train parse_fold_file);

use Prot::Tools::Translator qw(id2pdb);

sub data2train {
	my ($data, $win, $num_ins, $num_outs) = @_;
	my $win_half = ($win - 1) / 2;

	#--------------------------------------------------
	# say Data::Dumper->Dump($data);
	# say "XXXX";
	#-------------------------------------------------- 

	my @result;
	my $seq_length = scalar @$data;
	
	foreach my $center (0 .. $seq_length-1) {
		my $win_start = $center - $win_half;
		my $win_end = $center + $win_half;

		my @tmp_in;
		my @tmp_out;
		push @tmp_out, @{$data->[$center]->[1]};

		foreach my $pointer ($win_start .. $win_end) {
			if ($pointer < 0 || $pointer >= $seq_length) {
				push @tmp_in, empty_array($num_ins);
				push @tmp_in, 1;
			}
			else {
				push @tmp_in, @{$data->[$pointer]->[0]};
				push @tmp_in, 0;
			}
		}

		push @result, [\@tmp_in, \@tmp_out];
	}

	return \@result;
}

sub parse_fold_file {
	my $file = shift;
	
	open IN, $file or die "Could not open $file\n";
	my @in = <IN>;
	chomp @in;
	close IN;

	my $hd = shift @in;
	warn "No header specified int $file\n" if !defined $hd;
	my @header = split /\t/, $hd;
	my ($dump, $num_skip, $num_in, $num_out) = @header;

	my @result;

	my $pointer = -1;
	my $in_start = 1 + $num_skip;
	my $out_start = $in_start + $num_in;
	my $in_end = $out_start - 1;
	my $out_end = $out_start + $num_out - 1;

	foreach my $dp (@in) {
		unless ($dp =~ /^#/) {
			if ($dp =~ /^ID/) {
				push @result, [];
				$pointer++;
			}
			elsif ($dp =~ /^DP/) {
				my @split = split /\t/, $dp;
				
				my @ins;
				my @outs;

				foreach ($in_start .. $in_end) {
					push @ins, int($split[$_]);
				}
				foreach ($out_start .. $out_end) {
					push @outs, int($split[$_]);
				}

				push @{$result[$pointer]}, [\@ins, \@outs];		
			}
		}
	}

	return \@result;
}

sub empty_array {
	my $size = shift;

	my @array;
	foreach (1..$size) {
		push @array, 0;
	}

	return @array;
}

1;
