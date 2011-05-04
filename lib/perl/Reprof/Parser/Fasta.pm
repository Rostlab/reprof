package Reprof::Parser::Fasta;

use strict;
use warnings;
use feature qw(say);
use Data::Dumper;
use Reprof::Tools::Translator qw(res2profile);

#--------------------------------------------------
# name:        new
# desc:        creates a new fasta parser object
# args:        filename/path
# return:       parser object ref 
#-------------------------------------------------- 
sub new {
    my ($class, $file) = @_;

    my $self = {
        _file       => $file || warn "No file given to parser\n",
        _pos        => [],
        _res        => [],
        _raw_score  => [],
        _loc        => [],
        _gc         => undef,
        _length     => 0
    };

    bless $self, $class;
    $self->_parse;
    return $self;
}

sub _parse {
    my ($self) = @_;

    open FASTA, $self->{_file} or die "Could not open $self->{_file} ...\n";
    my $header = <FASTA>; chomp $header;
    my $sequence = <FASTA>; chomp $sequence;
    close FASTA;
    
    my $length = $self->{_length} = length $sequence;

    my $pos = 0;
    foreach my $res (split //, $sequence) {
        push @{$self->{_pos}}, [$pos];
        push @{$self->{_res}}, [$res];
        push @{$self->{_score}}, res2profile($res);
        push @{$self->{_loc}}, [ $pos++ / $length ];
    }
}

sub get_field {
    my ($self, $field) = @_;

    return $self->{"_$field"};
}

sub get_fields {
    my ($self, @fields) = @_;

    my @result;
    foreach my $field (@fields) {
        push @result, $self->{"_$field"};
    }

    return \@result;
}

#--------------------------------------------------
# name:        normalize_pssm
# args:        pssm value
# return:      normalized pssm value
#-------------------------------------------------- 
sub _normalize_pssm {
    my $x = shift;
    return 1.0 / (1.0 + exp(-$x));
}

1;
