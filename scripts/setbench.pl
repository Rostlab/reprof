#!/usr/bin/perl -w
#--------------------------------------------------
# desc:     parse files supported by the Reprof 
#           library to create sets for machine
#           learning
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
my $out_file;

GetOptions(
        'config|c=s'    =>  \$config_file,
        'out|o=s'    =>  \$out_file
        );

#--------------------------------------------------
# handle config 
#-------------------------------------------------- 
my $features;
my %formats;
my %source_actions;

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

open CONFIG, $config_file or croak "Could not open $config_file\n";
while (my $line = <CONFIG>) {
    my ($type, $format, $value) = split /\s+/, $line;

    
    if ($type eq "feature") {
        my $source_module = "Reprof::Source::$format";
        require_module($source_module);
        my $parser_module = "Reprof::Parser::$format";
        require_module($parser_module);

        $formats{$format} = 1;
        push @$features, [$format, $value];
    }
    elsif ($type eq "source") {
        $source_actions{$format} = $value;
    }
    elsif ($type eq "option") {
        if ($format eq "fasta") {
            $list_file = $value;
        }
        elsif ($format eq "out") {
            $out_file = $value;
        }
    }
}
close CONFIG;


#--------------------------------------------------
# list
#-------------------------------------------------- 
open LIST, $list_file or croak "Could not open $list_file\n";
my @list;
my %id2sequence;
while (my $header = <LIST>) {
    chomp $header;
    my $id = substr $header, 1;
    my $sequence = <LIST>;
    chomp $sequence;
    push @list, $id;
    $id2sequence{$id} = $sequence;
}
close LIST;

#--------------------------------------------------
# output 
#-------------------------------------------------- 
open OUT, ">", $out_file or croak "Could not open $out_file\n";

#--------------------------------------------------
# here we go
#-------------------------------------------------- 
my %parsers;
my %parser_args;

my $count = 0;
my $header_written = 0;
foreach my $entry (@list) {
    my $sequence = $id2sequence{$entry};
    #say $sequence;
    say "$count of ".(scalar @list) if scalar ++$count % 10 == 0;
    #--------------------------------------------------
    # parse needed files
    #-------------------------------------------------- 
    foreach my $format (keys %formats) {
        my $source_module = "Reprof::Source::$format";
        my $action = $source_actions{$format};
        my @source_results = $source_module->$action($entry, $sequence);

        my $parser_module = "Reprof::Parser::$format";
        my $file = shift @source_results;
        $parsers{$format} = $parser_module->new($file);

        $parser_args{$format} = \@source_results;
    }

    #--------------------------------------------------
    # extract 
    #-------------------------------------------------- 
    my $tmp_features = [];
    foreach my $feats (@$features) {
        my ($format, $feature) = @$feats;

        my @args = @{$parser_args{$format}};
        my @values = $parsers{$format}->$feature(@args);

            push @$tmp_features, \@values;
    }
    croak "No features found\n" if (scalar @$tmp_features == 0);
    my $seq_length = scalar @{$tmp_features->[0]};

    unless ($header_written) {
        # write header
        my $tmp_feature = $tmp_features->[0];
        my $col = 1;
        foreach my $iter (0 .. scalar @$features - 1) {
            my ($format, $feature) = @{$features->[$iter]};
            my $feature_length = scalar (ref $tmp_features->[$iter][0]?@{$tmp_features->[$iter][0]}:1);
            print OUT "feature $format $feature $col ";
            $col += $feature_length - 1;
            say OUT $col;
            $col++;
        }

        $header_written = 1;
    }

    say OUT "entry $entry";
    foreach my $pos (0 .. $seq_length - 1) {
        print OUT "pos";
        foreach my $tmp_out (@$tmp_features) {
            print OUT " ", join " ", (ref $tmp_out->[$pos]?@{$tmp_out->[$pos]}:$tmp_out->[$pos]);
        }
        print OUT "\n";
    }
    say OUT "end";
}
close OUT;

    #--------------------------------------------------
    # extract relevant outputs/inputs from parsers
    #-------------------------------------------------- 
    #my $length = $parsers{fasta}->length(@{$parser_args{fasta}});

    #foreach my $center (0 .. $length - 1) {
    #my @tmp_inputs;
    #foreach my $ip (@$inputs) {
    #my ($format, $input, $window) = @$ip;
    #
    #my @args = @{$parser_args{$format}};
    #my @values = $parsers{$format}->$input(@args);
    #
    #if ($window) {
    #my $first = $center - (($window - 1) / 2);
    #my $last = $center + (($window - 1) / 2);
    #
    #foreach my $iter ($first .. $last) {
    #if ($iter < 0 || $iter >= $length) {
    #push @tmp_inputs, (map {0} (ref $values[$center]?@{$values[$center]}:$values[$center]));
    #}
    #else {
    #push @tmp_inputs, (ref $values[$iter]?@{$values[$iter]}:$values[$iter]);
    #}
    #}
    #}
    #else {
    #push @tmp_inputs, @values;
    #}
    #}
    #
    #my @tmp_outputs;
    #foreach my $output (@$outputs) {
    #my ($format, $input, $window) = @$output;
    #
    #my @args = @{$parser_args{$format}};
    #my @values = $parsers{$format}->$input(@args);
    #
    #if ($window) {
    #my $first = $center - (($window - 1) / 2);
    #my $last = $center + (($window - 1) / 2);
    #
    #foreach my $iter ($first .. $last) {
    #if ($iter < 0 || $iter >= $length) {
    #push @tmp_outputs, (map {0} (ref $values[$center]?@{$values[$center]}:$values[$center]));
    #}
    #else {
    #push @tmp_outputs, (ref $values[$iter]?@{$values[$iter]}:$values[$iter]);
    #}
    #}
    #}
    #else {
    #push @tmp_outputs, @values;
    #}
    #}
    #
    #
    #}
#}
    ###
