package Reprof::Parser::mdisorder;

use strict;
use feature qw(say);
use Carp;
use Data::Dumper;
use Reprof::Converter qw(sec_features acc_norm acc_features);


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
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            my @split = split /\s+/, $line;
            if ($header_read) {
                if (scalar @split == scalar @header && $split[0] =~ m/^\d+$/) {
                    my $iter = 0;

                    foreach my $val (@split) {
                        push @{$self->{$header[$iter]}}, $val;

                        $iter++;
                    }
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

sub MD_raw {
    my $self = shift;

    return @{$self->{MD_raw}};
}

sub MD_rel {
    my $self = shift;

    my @result = map {$_ / 10} @{$self->{MD_rel}};
    return @result;
}

sub MD2st_2state {
    my $self = shift;

    my @result;
    foreach my $md (@{$self->{MD2st}}) {
        if ($md eq "D") {
            push @result, [1, 0];
        }
        else {
            push @result, [0, 1];
        }
    }

    return @result;
}

1;
