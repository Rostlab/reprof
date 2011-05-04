package Reprof::Methods::Fann;

use strict;
use feature qw(say);
use Data::Dumper;
use Reprof::Tools::Measure;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(train_nn run_nn);

#--------------------------------------------------
# name:        train_nn
# desc:        trains the network with the data
# args:        fann object, ref to sets
# return:
#-------------------------------------------------- 
sub train_nn {
    my ($nn, $set) = @_;

    while (my $dp = $set->next_dp) {
        $nn->reset_MSE;
        $nn->train($dp->[1], $dp->[2]);
    }
}

#--------------------------------------------------
# name:        run_nn
# desc:        tests the network with data
# args:        fann object, ref to sets, [ref to Measure]
# return:      ref to array containing the results
#-------------------------------------------------- 
sub run_nn {
    my ($nn, $set, $measure) = @_;

    my @results;

    while (my $dp = $set->next_dp) {
        $nn->reset_MSE;
        my $result = $nn->run($dp->[1]);
        push @results, $result;
        if (defined $measure) {
            $measure->add($dp->[2], $result);
        }
    }

    return \@results;
}

1;
