package Reprof::Parser::horiz;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Reprof::Converter qw(sec_features);

sub new {
    my ($class, $file) = @_;

    my $self = {Conf => [], Pred => [], AA => []};

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open FH, $file or croak "Could not open $file\n";
    while (my $line = <FH>) {
        chomp $line;
        if ($line !~ m/^(Conf|Pred|  AA): (.+)/) {
            my @split = split //, $2;
            my $type = $1;
            $type =~ s/\w//g;

            push @{$self->{$type}}, @split;
        }
    }
    close FH;
}


sub sec_3state {
    my ($self) = @_;

    my @result;
    foreach my $val (@{$self->{Pred}}) {
        my $nr = sec_features($val, "number");
        my @raw = (0, 0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

1;
