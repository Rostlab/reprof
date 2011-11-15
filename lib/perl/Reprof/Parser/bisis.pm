package Reprof::Parser::bisis;

use strict;
use warnings;
use feature qw(say);
use Carp;

sub new {
    my ($class, $file) = @_;

    my $self = {
    };

    bless $self, $class;
    $self->parse($file);
    return $self;
}

sub parse {
    my ($self, $file) = @_;

    open FH, $file or croak "fh error\n";
    while (my $line = <FH>) {
        next if ($line =~ m/^#/);
        chomp $line;
        $line =~ s/^\s+//;

        my ($Idx, $AA, $B, $NB, $Score, $Bool, $Rel) = split /\s+/, $line;
        push @{$self->{Idx}}, $Idx;
        push @{$self->{AA}}, $AA;
        push @{$self->{B}}, $B;
        push @{$self->{NB}}, $NB;
        push @{$self->{Score}}, $Score;
        push @{$self->{Bool}}, $Bool;
        push @{$self->{Rel}}, $Rel;
    }
}

sub res {
    my $self = shift;
    return @{$self->{res}};
}

sub B {
    my $self = shift;
    return @{$self->{B}};
}

sub NB {
    my $self = shift;
    return @{$self->{NB}};
}

1;
