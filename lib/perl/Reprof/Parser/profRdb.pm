package Setbench::Parser::profRdb;

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

my %acc_norm = (
    A => 106,  
    B => 160,         # D or N
    C => 135,  
    D => 163, 
    E => 194,
    F => 197, 
    G => 84, 
    H => 184,
    I => 169, 
    K => 205, 
    L => 164,
    M => 188, 
    N => 157, 
    P => 136,
    Q => 198, 
    R => 248, 
    S => 130,
    T => 142, 
    V => 142, 
    W => 227,
    X => 180,         # undetermined (deliberate)
    Y => 222, 
    Z => 196,         # E or Q
    max=>248
);

my $acc_features = {
    b => { two => 0, three   => 0 },
    i => { two => 0, three   => 1 },
    e => { two => 1, three   => 2 },
};

my %as = (
    A => 1,  
    C => 1,  
    D => 1, 
    E => 1,
    F => 1, 
    G => 1, 
    H => 1,
    I => 1, 
    K => 1, 
    L => 1,
    M => 1, 
    N => 1, 
    P => 1,
    Q => 1, 
    R => 1, 
    S => 1,
    T => 1, 
    V => 1, 
    W => 1,
    Y => 1 
);

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
        my $nr = $ss_features->{$val}{number};
        my @raw = (0, 0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
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
        my $nr = $acc_features->{$val}{three};
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
        my $nr = $acc_features->{$val}{two};
        my @raw = (0, 0);
        $raw[$nr] = 1;
        push @result, \@raw;
    }

    return @result;
}

1;
