package Reprof::Writer::libsvm;

use strict;
use feature qw(say);
use Carp;

sub write {
    my ($self, $fh, $inputs, $outputs) = @_;

    my $count = 1;
    print $fh join ",", @$outputs;
    foreach my $input(@$inputs) {
        if ($input != 0) {
            print $fh " $count:$input";
        }
        $count++;
    }
    print $fh "\n";
}

1;
