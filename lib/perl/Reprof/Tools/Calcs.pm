package Reprof::Tools::Calcs;

use strict;
use feature qw(say);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(hval);

sub hval {
    my ($length, $pid) = @_;
    if ($length <= 11) {
        return $pid - 100.0;
    }
    elsif ($length <= 450) {
        my $ex = -0.32 * (1 + exp(- $length / 1000));
        return $pid - (480 * ($length ** $ex));
    }
    else {
        return $pid - 19.5;
    }
}

