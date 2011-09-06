package Setbench::Parser::horiz;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;

my $ss_features = {
    H => { number => 0, oneletter   => 'H' },
    G => { number => 0, oneletter   => 'H' },
    I => { number => 0, oneletter   => 'H' },
    E => { number => 1, oneletter   => 'E' },
    B => { number => 1, oneletter   => 'E' },
    L => { number => 2, oneletter   => 'L' },
    S => { number => 2, oneletter   => 'L' },
    T => { number => 2, oneletter   => 'L' },
    '' => { number => 2, oneletter   => 'L' },
    ' ' => { number => 2, oneletter   => 'L' }
};

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


sub ss_3state {
    my ($self) = @_;

    my @result;
    foreach my $val (@{$self->{Pred}}) {
        my $nr = $ss_features->{$val}{number};
        my @raw = (0, 0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

1;
