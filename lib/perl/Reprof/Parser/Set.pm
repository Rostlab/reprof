package Reprof::Parser::Set;

use strict;
use feature qw(say);
use Data::Dumper;

use Reprof::Tools::Set;

sub new {
    my ($class, $file) = @_;
    my $self = {  
        _file   => $file,
        _set    => undef
    };

    bless $self, $class;

    $self->_parse;

    return $self;
}

sub get_set {
    my $self = shift;

    return $self->{_set};
}

sub _parse {
    my $self = shift;

    my $file = $self->{_file};

    my @result;

    open IN, $file or die "Could not open $file\n";
    my @in = <IN>;
    chomp @in;
    close IN;

    my $hd = shift @in;
    warn "No header specified in $file\n" if !defined $hd;
    my @header = split /\t/, $hd;
    my ($dump, $num_desc, $num_feat, $num_out) = @header;

    my $set = Reprof::Tools::Set->new;
    my $id;
    foreach my $line (@in) {
        if ($line =~ m/^ID/) {
            $id = substr $line, 3;
        }
        elsif ($line =~ m/^DP/) {
            my @split = split /\t/, $line;
            shift @split;
            
            my @desc = @split[0 .. $num_desc - 1];
            my @feat = @split[$num_desc .. $num_desc + $num_feat - 1];
            my @out = @split[$num_desc + $num_feat .. $num_desc + $num_feat + $num_out - 1];

            $set->add($id, \@desc, \@feat, \@out);
        }
    }

    $self->{_set} = $set;
}

1;
