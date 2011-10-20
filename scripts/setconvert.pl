#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     covert setfiles into trainingfiles
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Getopt::Long;

#--------------------------------------------------
# options
#-------------------------------------------------- 
my $config_file;
my $list_file;
my $set_file;
my $out_file;
my $out_format;
my $writer;

GetOptions(
        'config|c=s'    =>  \$config_file
        );

#--------------------------------------------------
# handle config 
#-------------------------------------------------- 
sub require_module {
    my $module = shift;
    
    my $module_mod = $module;
    $module_mod =~ s/::/\//g;
    eval {
        require "$module_mod.pm";
    };
    if ($@) {
        croak "Could not load $module\n$@";
    }
}

my @inputs;
my @outputs;

open CONFIG, $config_file or croak "Could not open $config_file\n";
while (my $line = <CONFIG>) {
    my ($type, $format, $value, $window) = split /\s+/, $line;

    if ($type eq "input") {
        push @inputs, [$format, $value, $window];
    }
    elsif ($type eq "output") {
        push @outputs, [$format, $value, $window];
    }
    elsif ($type eq "option") {
        if ($format eq "list") {
            $list_file = $value;
        }
        elsif ($format eq "set") {
            $set_file = $value;
        }
        elsif ($format eq "out") {
            $out_file = $value;
        }
        elsif ($format eq "format") {
            $out_format = $value;
            $writer = "Reprof::Writer::$out_format";
            require_module($writer);
        } }
}
close CONFIG;


#--------------------------------------------------
# list
#-------------------------------------------------- 
open LIST, $list_file or croak "Could not open $list_file\n";
my %list;
while (my $header = <LIST>) {
    my $seq = <LIST>;
    chomp $header;
    my $id = substr $header, 1;
    $list{$id} = 1;
}
close LIST;

say scalar keys %list;
#--------------------------------------------------
# slurp outputs of other methods (if any) 
#-------------------------------------------------- 
my %output_features;
foreach my $feat (@inputs, @outputs) {
    if ($feat->[0] eq "output") {
        my $file = $feat->[1];
        open FEAT, "$file" or croak "Could not open $file\n";
        my @data = <FEAT>;
        chomp @data;
        close FEAT;

        $output_features{$file} = \@data;
    }
}

#--------------------------------------------------
# parse set-db
#-------------------------------------------------- 
my $header_read = 0;
my $inside_entry = 0;
my $current_entry;
my %index;
my @raw_data;
my $size = 0;
my $num_inputs;
my $num_outputs;
my $header_written = 0;
my $entry_count = 0;
my $count = 0;
my $max_to = 0;

open my $fh, ">", $out_file or croak "Could not open $out_file\n";
open SET, $set_file or croak "Could not open $set_file\n";
while (my $line = <SET>) {
    chomp $line;
    my @split = split /\s+/, $line;
    unless ($header_read) {
        if ($split[0] eq "feature") {
            my ($dump, $type, $feature, $from, $to) = @split;
            if (defined $to) {
                $index{$type}{$feature}{from} = $from;
                $index{$type}{$feature}{to} = $to;
                $index{$type}{$feature}{size} = $to - $from + 1;

                if ($to > $max_to) {
                    $max_to = $to;
                }
            }
        }
    }

    if ($split[0] eq "entry") {
        $header_read = 1;
        $current_entry = $split[1];
        if (exists $list{$current_entry}) {
            $inside_entry = 1;
            $entry_count++;
            say $entry_count if $entry_count % 100 == 0;;
        }
    }
    elsif ($inside_entry && $split[0] eq "pos") {
        foreach my $feat (@inputs, @outputs) {
            if ($feat->[0] eq "output") {
                my @more_raw_data = split " ", $output_features{$feat->[1]}->[$count];
                
                my $from = scalar @split;
                push @split, @more_raw_data;
                my $to = scalar @split - 1;

                unless (exists $index{"output"}{$feat->[1]}) {
                    $index{"output"}{$feat->[1]}{from} = $from;
                    $index{"output"}{$feat->[1]}{to} = $to;
                    $index{"output"}{$feat->[1]}{size} = $to - $from + 1;
                }
            }
        }
        push @raw_data, \@split;
        $count++;
    }
    elsif ($split[0] eq "pos") {
        $count++;
    }
    elsif ($split[0] eq "end") {
        #--------------------------------------------------
        # write 
        #-------------------------------------------------- 
        my $length = scalar @raw_data;
        foreach my $center (0 .. $length - 1) {
            my @tmp_inputs;
            foreach my $input (@inputs) {
                my ($format, $feature, $window) = @$input;

                my $from = $index{$format}{$feature}{from};
                my $to = $index{$format}{$feature}{to};

                my $win_start = $center - ($window - 1) / 2;
                my $win_end = $center + ($window - 1) / 2;

                foreach my $iter ($win_start .. $win_end) {
                    if ($iter < 0 || $iter >= $length) {
                        foreach my $feature_pos ($from .. $to) {
                            push @tmp_inputs, 0;
                        }
                    }
                    else {
                        foreach my $feature_pos ($from .. $to) {
                            push @tmp_inputs, $raw_data[$iter][$feature_pos];
                        }
                    }
                }

            }

            my @tmp_outputs;
            foreach my $output (@outputs) {
                my ($format, $feature, $window) = @$output;

                my $from = $index{$format}{$feature}{from};
                my $to = $index{$format}{$feature}{to};

                my $win_start = $center - ($window - 1) / 2;
                my $win_end = $center + ($window - 1) / 2;

                foreach my $iter ($win_start .. $win_end) {
                    if ($iter < 0 || $iter >= $length) {
                        foreach my $feature_pos ($from .. $to) {
                            push @tmp_outputs, 0;
                        }
                    }
                    else {
                        foreach my $feature_pos ($from .. $to) {
                            push @tmp_outputs, $raw_data[$iter][$feature_pos];
                        }
                    }
                }

            }

            $num_inputs = scalar @tmp_inputs;
            $num_outputs = scalar @tmp_outputs;
            $writer->write($fh, \@tmp_inputs, \@tmp_outputs);
            $size++;
        }

        $inside_entry = 0;
        undef @raw_data;
    }

}
close SET;
close $fh;

say "size: $size num_inputs: $num_inputs num_outputs: $num_outputs";
