package Reprof::Tools::Converter;

use strict;
use feature qw(say);
use Data::Dumper;
use Reprof::Tools::Utils qw(get_max_array_pos);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(convert_id convert_ss convert_res);


#--------------------------------------------------
# ID dictionary 
#-------------------------------------------------- 
my $id_dict = {
    pdb         => '(\d[\d\w]{3})',
    pdbchain    => '(\d[\d\w]{3}:\w\d*)'
};


#--------------------------------------------------
# SS dictionary 
#-------------------------------------------------- 
my $ss_dict = {
    0 => 'L',
    1 => 'H',
    2 => 'E',
    L => 0,
    H => 1,
    E => 2,
    G => 1,
    I => 1,
    B => 2
};

#--------------------------------------------------
# Res dictionary 
#-------------------------------------------------- 
my $res_dict;

my @res_num = (0 .. 19);
my @res_oneletter = qw(A R N D C Q E G H I L K M F P S T W Y V);
my @res_threeletter = qw(ALA ARG ASN ASP CYS GLU GLN GLY HIS ILE LEU LYS MET PHE PRO SER THR TRP TYR VAL);

foreach my $num (@res_num) {
    foreach my $oneletter (@res_oneletter) {
        foreach my $threeletter (@res_threeletter) {
            $res_dict->{$num}->{oneletter} = $oneletter;
            $res_dict->{$num}->{threeletter} = $threeletter;
            $res_dict->{$oneletter}->{num} = $num;
            $res_dict->{$oneletter}->{threeletter} = $threeletter;
            $res_dict->{$threeletter}->{oneletter} = $oneletter;
            $res_dict->{$threeletter}->{num} = $num;
        }
    }
}

#--------------------------------------------------
# Subs 
#-------------------------------------------------- 
sub convert_id {
	my ($in, $format) = @_;;

        my $result;
	while ($in =~ m/$id_dict->{$format}/g) {
		$result = $1;
	}
	return lc $result;
}

sub convert_res {
    my ($value, $format) = @_;

    if (ref $value) {
        return convert_res(get_max_array_pos($value), 'oneletter');
    }
    if ($format eq 'profile') {
        my @array = map 0, (1 .. 20);
        $array[convert_res($value, 'num')] = 1;
        return \@array;
    }

    return $res_dict->{uc $value}{$format};
}

sub convert_ss {
    my ($value, $format) = @_;

    if (ref $value) {
        return convert_ss(get_max_array_pos($value), 'oneletter');
    }
    if (defined $format && $format eq 'profile') {
        my @array = map 0, (1 .. 3);
        $array[convert_ss($value, 'num')] = 1;
        return \@array;
    }

    return $ss_dict->{uc $value};
}

1;
