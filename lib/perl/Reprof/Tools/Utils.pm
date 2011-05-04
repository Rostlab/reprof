package Reprof::Tools::Utils;

use strict;
use feature qw(say);
use Data::Dumper;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_max_array_pos);

sub get_max_array_pos {
    my $array = shift;

    my $max_val = $array->[0];
    my $max_pos = 0;
    my $iter = 0;
    foreach my $val (@$array) {
        if ($val > $max_val) {
            $max_val = $val;
            $max_pos = $iter;
        }
        ++$iter;
    }
    return $max_pos;
}

1;
