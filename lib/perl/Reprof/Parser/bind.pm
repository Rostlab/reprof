package Reprof::Parser::bind;

use strict;
use feature qw(say);
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {bind => []};

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open FH, $file or croak "Could not open $file\n";
    while (my $line = <FH>) {
        if ($line !~ m/^#/) {
            chomp $line;
            my @split = split /\s+/, $line;
            push @{$self->{bind}}, [@split[1, 2]];
        }
    }
    close FH;
}

sub bind_2state {
    my $self = shift;
    return @{$self->{bind}};
}

sub bind {
    my $self = shift;
    
    my @result;
    foreach my $val (@{$self->{bind}}) {
        if ($val->[0] == 1) {
            push @result, 1;
        }
        else {
            push @result, 0;
        }
    }

    return @result;
}

1;
