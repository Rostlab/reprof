use warnings;
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name     => 'RG::Reprof',
    license         => 'gpl',                                                                                                                              
    dist_name       => 'reprof',
    dist_version    => '1.0',
    dist_author     => ['Peter Hoenigschmid <hoenigschmid@rostlab.org>', 'Burkhard Rost'],
    dist_abstract   => 'secondary structure and solvent accessibility prediction',
);
$build->create_build_script;
