package Setbench::Parser::dssp;

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

    my $self = {
        chains => [],
        chain  => {}
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    my $res_started = 0;
    my $break = 0;
    open FH, $file or croak "Could not open $file\n";
    while (my $line = <FH>) {
        if (!$res_started && $line =~ m/^  #  RESIDUE AA STRUCTURE/) {
            $res_started = 1;
        }
        elsif ($res_started) {
            if ($line =~ /!\*/) { # chain break
                $break = 0;
            }
            elsif ($line =~ /!/) { # interrupted backbone 
                $break++;
            }
            else {
                my $chain = parsefield($line, 12, 12);# . $break;				
                my $res = parsefield($line, 14, 14);
                $res = "X" unless exists $as{$res};
                my $ss  = parsefield($line, 17, 17);
                my $acc = parsefield($line, 36, 38);

                push @{$self->{chain}{$chain}{acc_raw}}, $acc;
                push @{$self->{chain}{$chain}{ss}}, $ss_features->{$ss}{oneletter};
                push @{$self->{chain}{$chain}{res}}, (uc $res);
            }
        }
    }
    close FH;

    foreach my $chain (sort keys %{$self->{chain}}) {
        push @{$self->{chains}}, $chain;
    }
}


sub ss {
    my ($self, $chain) = @_;

    return @{$self->{chain}{$chain}{ss}};
}

sub ss_numeric {
    my ($self, $chain) = @_;

    my @ss = @{$self->{chain}{$chain}{ss}};
    my @result;
    foreach my $ss (@ss) {
        push @result, $ss_features->{$ss}{number};
    }

    return @result;
}

sub ss_numeric_normalized {
    my ($self, $chain) = @_;

    my @ss = @{$self->{chain}{$chain}{ss}};
    my @result;
    foreach my $ss (@ss) {
        push @result, ($ss_features->{$ss}{number} / 2);
    }

    return @result;
}

sub ss_3state {
    my ($self, $chain) = @_;

    my @ss = @{$self->{chain}{$chain}{ss}};
    my @result;
    foreach my $ss (@ss) {
        my @raw = map {0} (1 .. 3);
        $raw[$ss_features->{$ss}{number}] = 1;
        push @result, \@raw;
    }

    return @result;
}

sub acc_raw {
    my ($self, $chain) = @_;

    return @{$self->{chain}{$chain}{acc_raw}};
}

sub acc_normalized {
    my ($self, $chain) = @_;

    my @residues = @{$self->{chain}{$chain}{res}};
    my @accs =  @{$self->{chain}{$chain}{acc_raw}};

    my @result;
    foreach my $iter (0 .. scalar @residues - 1) {
        my $norm_div = $acc_norm{$residues[$iter]};
        if (! defined $norm_div) {
            say Dumper($self);
            say $residues[$iter];
        }
        my $norm = 100 * ($accs[$iter] / $norm_div);
        push @result, $norm;
    }

    return @result;
}

sub acc_10state {
    my ($self, $chain) = @_;
    
    my @accs = $self->acc_normalized($chain);
    my @result;

    foreach my $acc (@accs) {
        my $sqr = int sqrt $acc;
        my @array = map {0} (1 .. 10);
        if ($sqr >= 10) {
            $array[9] = 1;
        }
        else {
            $array[$sqr] = 1;
        }
        push @result, \@array;
    }

    return @result;
}

sub acc_3state {
    my ($self, $chain) = @_;
    
    my @accs = $self->acc_normalized($chain);
    my @result;

    foreach my $acc (@accs) {
        my @array = map {0} (1 .. 3);
        if ($acc >= 36) {
            $array[2] = 1;
        }
        elsif ($acc >= 9) {
            $array[1] = 1;
        }
        else {
            $array[0] = 1;
        }
        push @result, \@array;
    }

    return @result;
}

sub acc_2state {
    my ($self, $chain) = @_;
    
    my @accs = $self->acc_normalized($chain);
    my @result;

    foreach my $acc (@accs) {
        my @array = map {0} (1 .. 2);
        if ($acc >= 16) {
            $array[1] = 1;
        }
        else {
            $array[0] = 1;
        }
        push @result, \@array;
    }

    return @result;
}

sub length {
    my ($self, $chain) = @_;

    my $length = scalar @{$self->{chain}{$chain}{ss}};   
    return $length;
}

sub getchains {
    my $self = shift;

    return $self->{chains};
}

#--------------------------------------------------
# INTERN
#-------------------------------------------------- 

#--------------------------------------------------
# Function which returns a part of a record field
# (taking the numbers provided in the pdb doc)
#-------------------------------------------------- 
sub parsefield {
    my ($entry, $from, $to) = @_;
    my $val;
    if (defined $to) {
        $val = substr $entry, $from - 1, $to-($from - 1);
    }
    else {
        $val = substr $entry, $from - 1;
    }

    chomp $val;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    return $val;
}

1;
