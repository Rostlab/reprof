#--------------------------------------------------
# desc:     parser for (multiple) fasta files 
#
# author:   hoenigschmid@rostlab.org
#-------------------------------------------------- 
package Setbench::Parser::fasta;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;

my $aa_features = {    
    'A'  =>  {'number' => 0, 'mass' => 0.109,    'volume' => 0.170,    'hydrophobicity' => 0.700,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'R'  =>  {'number' => 1, 'mass' => 0.767,    'volume' => 0.676,    'hydrophobicity' => 0.000,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 1,      'polarity' => 0},    
    'N'  =>  {'number' => 2, 'mass' => 0.442,    'volume' => 0.322,    'hydrophobicity' => 0.111,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 1},
    'D'  =>  {'number' => 3, 'mass' => 0.450,    'volume' => 0.304,    'hydrophobicity' => 0.111,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0,      'polarity' => 1},
    'C'  =>  {'number' => 4, 'mass' => 0.357,    'volume' => 0.289,    'hydrophobicity' => 0.778,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'Q'  =>  {'number' => 5, 'mass' => 0.550,    'volume' => 0.499,    'hydrophobicity' => 0.111,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 1},
    'E'  =>  {'number' => 6, 'mass' => 0.558,    'volume' => 0.467,    'hydrophobicity' => 0.111,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0,      'polarity' => 1},
    'G'  =>  {'number' => 7, 'mass' => 0.000,    'volume' => 0.000,    'hydrophobicity' => 0.456,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'H'  =>  {'number' => 8, 'mass' => 0.620,    'volume' => 0.555,    'hydrophobicity' => 0.144,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 1,      'polarity' => 1},
    'I'  =>  {'number' => 9, 'mass' => 0.434,    'volume' => 0.636,    'hydrophobicity' => 1.000,    'cbeta' => 1,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'L'  =>  {'number' => 10, 'mass' => 0.434,    'volume' => 0.636,    'hydrophobicity' => 0.922,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'K'  =>  {'number' => 11, 'mass' => 0.550,    'volume' => 0.647,    'hydrophobicity' => 0.067,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 1,      'polarity' => 1},
    'M'  =>  {'number' => 12, 'mass' => 0.574,    'volume' => 0.613,    'hydrophobicity' => 0.711,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'F'  =>  {'number' => 13, 'mass' => 0.698,    'volume' => 0.774,    'hydrophobicity' => 0.811,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'P'  =>  {'number' => 14, 'mass' => 0.310,    'volume' => 0.314,    'hydrophobicity' => 0.322,    'cbeta' => 0,  'hbreaker' => 1,   'charge' => 0.5,    'polarity' => 0},
    'S'  =>  {'number' => 15, 'mass' => 0.233,    'volume' => 0.172,    'hydrophobicity' => 0.411,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 1},
    'T'  =>  {'number' => 16, 'mass' => 0.341,    'volume' => 0.334,    'hydrophobicity' => 0.422,    'cbeta' => 1,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 1},
    'W'  =>  {'number' => 17, 'mass' => 1.000,    'volume' => 1.000,    'hydrophobicity' => 0.400,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'Y'  =>  {'number' => 18, 'mass' => 0.822,    'volume' => 0.796,    'hydrophobicity' => 0.356,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 1},
    'V'  =>  {'number' => 19, 'mass' => 0.326,    'volume' => 0.476,    'hydrophobicity' => 0.967,    'cbeta' => 1,  'hbreaker' => 0,   'charge' => 0.5,    'polarity' => 0},
    'X'  =>  {'number' => 20, 'mass' => 0,    'volume' => 0,    'hydrophobicity' => 0,    'cbeta' => 0,  'hbreaker' => 0,   'charge' => 0,    'polarity' => 0},
};

sub new {
    my ($class, $file) = @_;

    my $self = {
        data => [],
        header => undef,
        length => undef
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open FASTA, $file or croak "Could not open $file\n";
    while (my $line = <FASTA>) {
        chomp $line;
        if ($line =~ m/^>/) {
            $self->{header} = substr $line, 1;
        }
        else {
            $line =~ s/\s+//g;
            push @{$self->{data}}, (split //, $line);
        }
    }
    close FASTA;

    $self->{length} = scalar @{$self->{data}};
}

sub residue {
    my ($self, $id) = @_;

    my @residues = @{$self->{data}};
    return @residues;
}

sub position {
    my ($self, $id) = @_;

    my @positions = (1 .. $self->{length});

    return @positions;
}

sub relative_position {
    my ($self, $id) = @_;

    my @positions = (1 .. $self->{length});
    my $length = $self->{length};
    my @relative_positions = map {$_ / $length} @positions;

    return @relative_positions;
}

sub relative_position_reverse {
    my ($self, $id) = @_;

    my @positions = (1 .. scalar @{$self->{data}});
    my $length = $self->{length};
    my @relative_positions = map {1 - $_ / $length} @positions;

    return @relative_positions;
}

sub in_sequence_bit {
    my ($self, $id) = @_;

    my $length = $self->{length};
    my @result = map {1} (1 .. $length);

    return @result;
}

sub length {
    my ($self, $id) = @_;

    my $length = $self->{length};

    return map {$length} (1 .. $length);
}

sub length_5state {
    my ($self, $id) = @_;

    my $length = $self->{length};
    my @result;

    if ($length >= 241) {
        @result =  (1, 1, 1, 1);
    }
    elsif ($length >= 181) {
        @result =  (1, 1, 1, 0.5);
    }
    elsif ($length >= 121) {
        @result =  (1, 1, 0.5, 0);
    }
    elsif ($length >= 61) {
        @result =  (1, 0.5, 0, 0);
    }
    elsif ($length >= 1) {
        @result =  (0.5, 0, 0, 0);
    }
    else {
        @result =  (0, 0, 0, 0);
    }

    return map {\@result} (1 .. $length);
}


sub profile {
    my ($self, $id) = @_;

    my @residues = @{$self->{data}};
    my @profiles;

    foreach my $residue (@residues) {
        carp "Invalid residue $residue\n" unless exists $aa_features->{$residue};

        my @tmp_profile = map {0} (0 .. 20);
        my $array_pos = $aa_features->{$residue}{number};
        $tmp_profile[$array_pos] = 1;

        push @profiles, \@tmp_profile;
    }

    return @profiles;
}

sub aa_composition {
    my ($self, $id) = @_;

    my @residues = @{$self->{data}};
    my @composition = map {0} (0 .. 20);

    foreach my $residue (@residues) {
        carp "Invalid residue $residue\n" unless exists $aa_features->{$residue};

        $composition[$aa_features->{$residue}{number}]++;
    }

    my $length = $self->{length};
    foreach my $item (@composition) {
        $item /= $length;
    }

    return map {\@composition} (1 .. $length);
}

sub feature {
    my ($self, $id, $feature) = @_;

    my @residues = @{$self->{data}};
    my @result;

    foreach my $residue (@residues) {
        carp "Invalid residue $residue\n" unless exists $aa_features->{$residue};

        push @result, $aa_features->{$residue}{$feature};
    }

    return @result;
}

sub mass {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "mass");

    return @result;
}

sub volume {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "volume");

    return @result;
}
sub hydrophobicity {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "hydrophobicity");

    return @result;
}
sub cbeta {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "cbeta");

    return @result;
}
sub hbreaker {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "hbreaker");

    return @result;
}
sub charge {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "charge");

    return @result;
}
sub polarity {
    my ($self, $id) = @_;
    
    my @result = $self->feature($id, "polarity");

    return @result;
}

1;
