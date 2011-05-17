package Reprof::Tools::Featurefactory;

my %polarity_dict = (   
    A => 0,
    R => 0,
    N => 1,
    D => 1,
    C => 0,
    E => 1,
    Q => 1,
    G => 0,
    H => 1,
    I => 0,
    L => 0,
    K => 1,
    M => 0,
    F => 0,
    P => 0,
    S => 1,
    T => 1,
    W => 0,
    Y => 1,
    V => 0,
    X => 0);

my %charge_dict = (   
    A => 0.5,
    R => 1,
    N => 0.5,
    D => 0,
    C => 0.5,
    E => 0,
    Q => 0.5,
    G => 0.5,
    H => 0.5,
    I => 0.5,
    L => 0.5,
    K => 1,
    M => 0.5,
    F => 0.5,
    P => 0.5,
    S => 0.5,
    T => 0.5,
    W => 0.5,
    Y => 0.5,
    V => 0.5,
    X => 0);

sub new {
    my ($class, $res) = @_;

    my $self = {    _res        => $res,
                    _loc        => [],
                    _polarity   => [],
                    _charge     => []};

    bless $self, $class;

    $self->_calculate_loc;
    $self->_calculate_charge;
    $self->_calculate_polarity;

    return $self;
}

sub get_loc {
    my $self = shift;
    return $self->{_loc};
}

sub get_polarity {
    my $self = shift;
    return $self->{_polarity};
}

sub get_charge {
    my $self = shift;
    return $self->{_charge};
}

sub _calculate_loc {
    my $self = shift;

    my $pos = 0;
    my $length = scalar @{$self->{_res}};
    
    foreach my $res (@{$self->{_res}}) {
        push @{$self->{_loc}}, ($pos / $length);
        
        ++$pos;
    }
}

sub _calculate_polarity {
    my $self = shift;
    foreach my $res (@{$self->{_res}}) {
        push @{$self->{_polarity}}, ($polarity_dict{$res});
    }
}

sub _calculate_charge {
    my $self = shift;
    foreach my $res (@{$self->{_res}}) {
        push @{$self->{_charge}}, ($charge_dict{$res});
    }
}

1;
