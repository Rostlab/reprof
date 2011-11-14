package Reprof::Parser::redisis;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Reprof::Converter qw(sec_features acc_norm acc_features);

sub new {
    my ($class, $file) = @_;

    my $self = {};

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    my @header;
    my $header_read = 0;
    open FH, $file or croak "Could not open $file\n";
    while (my $line = <FH>) {
        if ($line !~ m/^#/) {
            chomp $line;
            my @split = split /\s+/, $line;
            if ($header_read) {
                my $iter = 0;
                foreach my $val (@split) {
                    push @{$self->{$header[$iter]}}, $val;

                    $iter++;
                }
            }
            else {
                push @header, @split;
                $header_read = 1;
            }
        }
    }
    close FH;
}

sub p_binding {
    my $self = shift;
    return @{$self->{p_binding}};
}

sub o_binding {
    my $self = shift;
    return @{$self->{o_binding}};
}

sub p_binding_2state {
    my $self = shift;

    my @result;
    my $data = $self->{p_binding};
    foreach my $d (@$data) {
        if ($d == 1) {
            push @result, [1, 0];
        }
        else {
            push @result, [0, 1];
        }
    }

    return @result;
}

sub o_binding_2state {
    my $self = shift;

    my @result;
    my $data = $self->{o_binding};
    foreach my $d (@$data) {
        if ($d == 1) {
            push @result, [1, 0];
        }
        else {
            push @result, [0, 1];
        }
    }

    return @result;
}

sub nn_binding {
    my $self = shift;
    return @{$self->{nn_binding}};
}

sub nn_non_binding {
    my $self = shift;
    return @{$self->{nn_non_binding}};
}

1;
