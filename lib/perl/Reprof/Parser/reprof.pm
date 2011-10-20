package Reprof::Parser::reprof;

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


sub PHEL_3state {
    my ($self) = @_;

    my @result;
    foreach my $val (@{$self->{PHEL}}) {
        my $nr = sec_features($val, "number");
        my @raw = (0, 0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

sub RI_S {
    my ($self) = @_;

    return @{$self->{RI_S}};
}

sub PREL_10state {
    my ($self) = @_;

    my @result;
    foreach my $val (@{$self->{PREL}}) {
        my $nr = int(sqrt $val);
        my @raw = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

sub Pbie_3state {
    my ($self) = @_;

    my @result;
    foreach my $val (@{$self->{Pbie}}) {
        my $nr = acc_features($val, "three");
        my @raw = (0, 0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

sub Pbe_2state {
    my ($self) = @_;

    my @result;
    foreach my $val (@{$self->{Pbe}}) {
        my $nr = acc_features($val, "two");
        my @raw = (0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

1;
