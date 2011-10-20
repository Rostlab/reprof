package Reprof::Parser::dssp;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Reprof::Converter qw(aa sec_features acc_norm acc_features);

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
                $res = "X" unless defined aa($res);
                my $sec  = parsefield($line, 17, 17);
                my $acc = parsefield($line, 36, 38);

                push @{$self->{chain}{$chain}{acc_raw}}, $acc;
                push @{$self->{chain}{$chain}{sec}}, sec_features($sec, "oneletter");
                push @{$self->{chain}{$chain}{res}}, (uc $res);
            }
        }
    }
    close FH;

    foreach my $chain (sort keys %{$self->{chain}}) {
        push @{$self->{chains}}, $chain;
    }
}

sub res {
    my ($self, $chain) = @_;

    return @{$self->{chain}{$chain}{res}};
}

sub sec {
    my ($self, $chain) = @_;

    return @{$self->{chain}{$chain}{sec}};
}

sub sec_numeric {
    my ($self, $chain) = @_;

    my @sec = @{$self->{chain}{$chain}{sec}};
    my @result;
    foreach my $sec (@sec) {
        push @result, sec_features($sec, "number");
    }

    return @result;
}

sub sec_numeric_normalized {
    my ($self, $chain) = @_;

    my @sec = @{$self->{chain}{$chain}{sec}};
    my @result;
    foreach my $sec (@sec) {
        push @result, (sec_features($sec, "number") / 2);
    }

    return @result;
}

sub sec_3state {
    my ($self, $chain) = @_;
    
    #say Dumper($self);

    #say $chain;
    #say Dumper($self->{chain});
    my @sec = @{$self->{chain}{$chain}{sec}};
    my @result;
    foreach my $sec (@sec) {
        my @raw = map {0} (1 .. 3);
        $raw[sec_features($sec, "number")] = 1;
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
        my $norm_div = acc_norm($residues[$iter]);
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

    my $length = scalar @{$self->{chain}{$chain}{sec}};   
    return $length;
}

sub get_chains {
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
