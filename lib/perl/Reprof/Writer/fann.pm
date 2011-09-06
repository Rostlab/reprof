package Setbench::Writer::fann;

use strict;
use feature qw(say);
use Carp;

sub write {
    my ($self, $fh, $inputs, $outputs) = @_;

    say $fh join " ", @$inputs;
    say $fh join " ", @$outputs;
}

#sub new {
#my ($class, $file) = @_;
#
#$class = ref $class if ref $class;
#my $self = {
#file => $file,
#size => undef,
#num_inputs => undef,
#num_outputs => undef,
#tmp_fh => undef,
#data => []
#};
#bless $self, $class;
#
#my $tmp_file = "$file.tmp";
#open my $tmp_fh, ">", $tmp_file or croak "Could not open file $tmp_file\n";
#$self->{tmp_fh} = $tmp_fh;
#$self->{tmp_file} = $tmp_file;
#
#return $self;
#}
#
#sub post {
#my ($self, $size, $num_inputs, $num_outputs) = @_;
#
#my $tmp_fh = $self->{tmp_fh};
#close $tmp_fh;
#
#open OUT, ">", $self->{file};
#say OUT "$size $num_inputs $num_outputs";
#open TMP, $self->{tmp_file} or croak "Coult not open ".$self->{tmp_file}."\n";
#while (my $line = <TMP>) {
#print OUT $line;
#}
#close TMP;
#close OUT;
#unlink $self->{tmp_file} or croak "Could not delete tmp file ".$self->{tmp_file}."\n";
#}

1;
