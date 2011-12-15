package RG::Reprof::Reprof;
use strict;
use feature qw(say);
use Carp;

use base qw(ParentClass);

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = {};
    return bless $self, $class;
}

1;
