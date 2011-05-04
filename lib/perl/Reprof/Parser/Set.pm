package Reprof::Tools::Set;

use strict;
use feature qw(say);
use Data::Dumper;
use List::Util qw(shuffle);

sub new {
    my ($class, $dir, $win) = @_;
    my $self = bless {  _dir            => $dir,
        _data           => [],
        _iter_original  => [],
        _iter_current   => [],
        _num_desc       => undef,
        _num_features   => undef,
        _num_out        => undef,
        _size           => undef,
        _win            => $win,
        _win_half       => ($win - 1) / 2 
    }, $class;

    $self->_parse_sets_from_dir;

    return $self;
}

sub new_from_matrix {
    my ($class, $matrix, $num_inputs, $win) = @_;
}

sub num_features {
    my $self = shift;
    return $self->{_num_features};
}

sub num_outputs {
    my $self = shift;
    return $self->{_num_out};
}

sub size {
    my $self = shift;
    return $self->{_size};
}

sub reset_iter {
    my $self = shift;

    $self->{_iter_current} = [];
    push @{$self->{_iter_current}}, (shuffle @{$self->{_iter_original}});
}

sub reset_iter_original {
    my $self = shift;

    $self->{_iter_current} = [];
    push @{$self->{_iter_current}}, @{$self->{_iter_original}};
}


sub next_dp {
    my ($self) = @_;

    my $current = shift @{$self->{_iter_current}};
    unless (defined $current) {
        $self->reset_iter;
        return undef;
    }

    my ($prot, $center) = @$current;

    my $win_start = $center - $self->{_win_half};
    my $win_end = $center + $self->{_win_half};
    my $seq_length = scalar @{$self->{_data}->[$prot]};

    my @tmp_desc;
    my @tmp_in;
    my @tmp_out;

    push @tmp_out, @{$self->{_data}->[$prot][$center][2]};
    push @tmp_desc, @{$self->{_data}->[$prot][$center][0]};

    foreach my $pointer ($win_start .. $win_end) {
        if ($pointer < 0 || $pointer >= $seq_length) {
            push @tmp_in, $self->_empty_array($self->{_num_features} - 1), 1;
        }
        else {
            push @tmp_in, @{$self->{_data}->[$prot][$pointer][1]}, 0;
        }
    }

    return [\@tmp_desc, \@tmp_in, \@tmp_out];
}

sub _parse_sets_from_dir {
    my $self = shift;

    my $dir = $self->{_dir};
    opendir DIR, $dir or die "Could not open $dir ...\n";
    my @set_files = grep !/^\./, (readdir DIR);
    close DIR;

    foreach my $set_file (@set_files) {
        my $file = "$dir/$set_file";
        my @result;

        open IN, $file or die "Could not open $file\n";
        my @in = <IN>;
        chomp @in;
        close IN;

        my $hd = shift @in;
        warn "No header specified in $file\n" if !defined $hd;
        my @header = split /\t/, $hd;
        my ($dump, $num_desc, $num_in, $num_out) = @header;

        $self->{_num_features} = $num_in + 1;
        $self->{_num_out} = $num_out;

        my $pointer = -1;

        my $desc_start = 1;
        my $desc_end = $desc_start + $num_desc - 1;

        my $in_start = $desc_end + 1;
        my $in_end = $in_start + $num_in - 1;

        my $out_start = $in_end + 1;
        my $out_end = $out_start + $num_out - 1;

        foreach my $dp (@in) {
            unless ($dp =~ /^#/) {
                if ($dp =~ /^ID/) {
                    push @result, [];
                    $pointer++;
                }
                elsif ($dp =~ /^DP/) {
                    my @split = split /\t/, $dp;

                    my @descs;
                    my @ins;
                    my @outs;

                    foreach ($desc_start .. $desc_end) {
                        push @descs, $split[$_];
                    }
                    foreach ($in_start .. $in_end) {
                        push @ins, $split[$_];
                    }
                    foreach ($out_start .. $out_end) {
                        push @outs, $split[$_];
                    }

                    push @{$result[$pointer]}, [\@descs, \@ins, \@outs];		
                }
            }
        }

        push @{$self->{_data}}, @result;
    }

    my $count = 0;
    foreach my $prot (0 .. scalar @{$self->{_data}} - 1) {
        foreach my $pos (0 .. scalar @{$self->{_data}->[$prot]} - 1) {
            push @{$self->{_iter_original}}, [$prot, $pos];
            $count++;
        }
    }
    $self->{_size} = $count;
    $self->reset_iter;
}

sub _empty_array {
    my ($self, $size) = @_;

    my @array;
    foreach (1..$size) {
        push @array, 0;
    }

    return @array;
}

1;
