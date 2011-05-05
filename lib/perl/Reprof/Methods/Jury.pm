package Reprof::Methods::Jury;
use strict;
use feature qw(say);

use Data::Dumper;

use Reprof::Tools::Utils qw(get_max_array_pos);
use Reprof::Tools::Converter qw(convert_ss);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(jury_sum jury_avg jury_majority);

sub jury_sum {
    my $predictions = shift;

    my $result;

    my $pred_iter = 0;
    foreach my $prediction (@$predictions) {
        my $res_iter = 0;
        foreach my $res (@$prediction) {
            my $out_iter = 0;
            foreach my $out (@$res) { 
                $result->[$res_iter][$out_iter] += $out;

                $out_iter++;
            }

            $res_iter++;
        }

        $pred_iter++;
    }

    return $result;
}

sub jury_avg {
    my $predictions = shift;

    my $result;

    my $pred_iter = 0;
    foreach my $prediction (@$predictions) {
        my $res_iter = 0;
        foreach my $res (@$prediction) {
            my $out_iter = 0;
            foreach my $out (@$res) { 
                $result->[$res_iter][$out_iter] += $out;

                $out_iter++;
            }

            $res_iter++;
        }

        $pred_iter++;
    }

    foreach my $res_iter (0 .. scalar @$result - 1) {
        foreach my $out_iter (0 .. scalar @{$result->[$res_iter]} - 1) {
            $result->[$res_iter][$out_iter] /= $pred_iter;
        }
    }

    return $result;
}

sub jury_majority {
    my $predictions = shift;

    my $result;

    my $pred_iter = 0;
    foreach my $prediction (@$predictions) {
        my $res_iter = 0;
        foreach my $res (@$prediction) {
            my $out_iter = 0;

            my $max_pos = get_max_array_pos($res);
            my @res_maximized = map 0, (1 .. scalar @$res);
            $res_maximized[$max_pos] = 1;

            foreach my $out (@res_maximized) { 
                $result->[$res_iter][$out_iter] += $out;

                $out_iter++;
            }

            $res_iter++;
        }

        $pred_iter++;
    }

    return $result;
}

1;
