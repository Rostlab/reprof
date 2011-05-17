package Reprof::Methods::Fann;

use strict;
use feature qw(say);
use Data::Dumper;
use Reprof::Tools::Measure;
use Reprof::Tools::Set;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(train_nn run_nn run_nn_return_set);

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
    my ($nn, $set, $measure, $win) = @_;

    $set->win($win) if defined $win;

    my @results;

    while (my $dp = $set->next_dp) {
        $nn->reset_MSE;
        my $result = $nn->run($dp->[1]);
        push @results, $result;
        if (defined $measure && defined $dp->[2]) {
            $measure->add($dp->[2], $result);
        }
    }

    return \@results;
}

sub run_nn_return_set {
    my ($nn, $set, $measure, $win) = @_;

    $set->win($win) if defined $win;

    my $resultset = Reprof::Tools::Set->new;

    while (my $dp = $set->next_dp) {
        $nn->reset_MSE;
        my $result = $nn->run($dp->[1]);
        $resultset->add($dp->[4], [], $result, $dp->[2]);
        if (defined $measure && defined $dp->[2]) {
            $measure->add($dp->[2], $result);
        }
    }

    return $resultset;
}

1;
