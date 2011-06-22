#!/usr/bin/perl -w
use strict;
use feature qw(say);
use Getopt::Long;

#GetOptions( ''    =>  \,
#''    =>  \,
#''    =>  \ );

my $dir = shift;

my @sub_dirs = glob "$dir/*";

foreach my $sub_dir (@sub_dirs) {
   my $result_file = "$sub_dir/nntrain.result";

   if (-e $result_file) {
       open RESULT, $result_file;
       my ($qn_line) = grep /Qn/, <RESULT>;
       close RESULT;

       if ($qn_line) {
            chomp $qn_line;
            $qn_line =~ m/(\d+\.\d+)/;

            open NNTRAIN, "$sub_dir/config.nntrain";
            my @nntrain = <NNTRAIN>;
            chomp @nntrain;
            my $nnt = join ",", @nntrain;
            close NNTRAIN;

            open SETBENCH, "$sub_dir/config.setbench";
            my @setbench = <SETBENCH>;
            chomp @setbench;
            my $sb = join ",", @setbench;
            close SETBENCH;

            say "$1\t$sub_dir $nnt,$sb";
       }
   }
}


