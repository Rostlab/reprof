package Reprof::Parser::ent;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
#use Reprof::Converter qw();

my %aa = (
    'A' => 'A',
    'R' => 'R', 
    'N' => 'N', 
    'D' => 'D', 
    'C' => 'C', 
    'Q' => 'Q', 
    'E' => 'E', 
    'G' => 'G', 
    'H' => 'H', 
    'I' => 'I', 
    'L' => 'L', 
    'K' => 'K', 
    'M' => 'M', 
    'F' => 'F', 
    'P' => 'P', 
    'S' => 'S', 
    'T' => 'T', 
    'W' => 'W', 
    'Y' => 'Y', 
    'V' => 'V', 
    'X' => 'X', 
    'ALA' => 'A',  
    'ARG' => 'R',  
    'ASN' => 'N',  
    'ASP' => 'D',  
    'CYS' => 'C',  
    'GLU' => 'E',  
    'GLN' => 'Q',  
    'GLY' => 'G',  
    'HIS' => 'H',  
    'ILE' => 'I',  
    'LEU' => 'L',  
    'LYS' => 'K',  
    'MET' => 'M',  
    'PHE' => 'F',  
    'PRO' => 'P',  
    'SER' => 'S',  
    'THR' => 'T',  
    'TRP' => 'W',  
    'TYR' => 'Y',  
    'VAL' => 'V',  
);

my %not_aa = (
    'DA'    => 1,
    'DC'    => 1,
    'DG'    => 1,
    'DT'    => 1,
    'DU'    => 1,
    'RA'    => 1,
    'RC'    => 1,
    'RG'    => 1,
    'RT'    => 1,
    'RU'    => 1,
);

sub new {
    my ($class, $file) = @_;

    my $self = {
        resolution  => undef,
        chain => {},
        chains => [],
        has_model => 0,
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    my $has_model = 0;
    open FH, $file or croak "Could not open $file\n";
    while (my $line = <FH>) {
        #if ($line =~ m/^REMARK   2 RESOLUTION\./) {
        #my $res_string = parsefield $line, 24, 30;
        #if ($res_string =~ m/\s*(\d+\.\d\d) ANGSTROMS/) {
        #
        #}
        #}
        if ($line =~ m/^ATOM/) {
            my $res_name = parsefield($line, 18, 20);
            my $chain = parsefield($line, 22, 22);
            my $res_nr = parsefield($line, 23, 26);

            if (exists $not_aa{$res_name}) {
                next;
            }
            my $res = $aa{uc $res_name};
            if (! exists $aa{uc $res_name}) {
                warn "converting $res_name to X\n";
                $res = 'X';
            }

            $self->{chain}{$chain}{res}{$res_nr} = $res;
        }
        elsif ($line =~ m/^ENDMDL/) {
            #warn "model found: $file\n";
            $self->{has_model} = 1;
            last;
        }
    }
    close FH;

    my $c_count = 0;
    foreach my $c (sort keys %{$self->{chain}}) {
        push @{$self->{chains}}, $c;
        $c_count++;

        #if ($has_model) {
        #warn "".(scalar keys %{$self->{chain}{$c}{res}})."\n";
        #}
    }

}

sub has_model {
    my $self = shift;
    return $self->{has_model};
}

sub get_chains {
    my $self = shift;

    return $self->{chains};
}

sub res {
    my ($self, $chain) = @_;

    my %seq = %{$self->{chain}{$chain}{res}};
    my @result;
    foreach my $i (sort {$a <=> $b} keys %seq) {
        push @result, $seq{$i};
    }
    return @result;
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
