package Reprof::Methods::Jury;
use strict;
use feature qw(say);

use Reprof::Tools::Utils qw(get_max_array_pos);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(jury_sum jury_avg jury_majority);

sub jury_sum {
    my $results_all = shift;

    foreach my $result (@$results) {
        foreach my $dp (
    }
}

sub jury_avg {

}

sub jury_majority {

}

1;
