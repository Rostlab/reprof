package Reprof::Tools::Converter;

use strict;
use feature qw(say);
use Data::Dumper;
use Reprof::Tools::Utils qw(get_max_array_pos);

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(convert_id convert_ss convert_res convert_acc);


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
    0 => {
        num         => 0, 
        oneletter   => 'L'
    },
    1 => {
        num         => 1, 
        oneletter   => 'H'
    },
    2 => {
        num         => 2, 
        oneletter   => 'E'
    },
    L => {
        num         => 0, 
        oneletter   => 'L'
    },
    S => {
        num         => 0, 
        oneletter   => 'L'
    },
    T => {
        num         => 0, 
        oneletter   => 'L'
    },
    ' ' => {
        num         => 0, 
        oneletter   => 'L'
    },
    '' => {
        num         => 0, 
        oneletter   => 'L'
    },
    H => {
        num         => 1, 
        oneletter   => 'H'
    },
    E => {
        num         => 2, 
        oneletter   => 'E'
    },
    G => {
        num         => 1, 
        oneletter   => 'H'
    },
    I => {
        num         => 1, 
        oneletter   => 'H'
    },
    B => {
        num         => 2, 
        oneletter   => 'E'
    },
};
my @ss_num = qw(0 1 2 1 1 2);
my @ss_dssp = qw(L H E G I B);
my @ss_oneletter = qw(L H E H H E);

#--------------------------------------------------
# Res dictionary 
#-------------------------------------------------- 
my $res_dict;

my @res_oneletter = qw(A R N D C Q E G H I L K M F P S T W Y V);
my @res_threeletter = qw(ALA ARG ASN ASP CYS GLU GLN GLY HIS ILE LEU LYS MET PHE PRO SER THR TRP TYR VAL);

foreach my $num (0 .. 19) {
    my $oneletter = $res_oneletter[$num];
    my $threeletter = $res_threeletter[$num];

    $res_dict->{$num}{oneletter} = $oneletter;
    $res_dict->{$num}{threeletter} = $threeletter;
    $res_dict->{$num}{num} = $num;
    $res_dict->{$oneletter}{num} = $num;
    $res_dict->{$oneletter}{threeletter} = $threeletter;
    $res_dict->{$oneletter}{oneletter} = $oneletter;
    $res_dict->{$threeletter}{oneletter} = $oneletter;
    $res_dict->{$threeletter}{num} = $num;
    $res_dict->{$threeletter}{threeletter} = $threeletter;
}

#--------------------------------------------------
# Subs 
#-------------------------------------------------- 
sub convert_id {
        my $in = shift;
        my $format = shift || 'pdb';

        my $result;
	while ($in =~ m/$id_dict->{$format}/g) {
		$result = $1;
	}
	return lc $result;
}

sub convert_res {
    my $value = shift;
    my $format = shift || 'oneletter';

    if (ref $value) {
        return convert_res(get_max_array_pos($value), 'oneletter');
    }
    if ($format eq 'profile') {
        my @array = map 0, (1 .. 20);
        $array[convert_res($value, 'num')] = 1;
        return \@array;
    }

    return $res_dict->{uc $value}{$format} || 'X';
}

sub convert_ss {
    my $value = shift;
    my $format = shift || 'oneletter';

    if (ref $value) {
        return convert_ss(get_max_array_pos($value), 'oneletter');
    }
    if ($format eq 'profile') {
        my @array = map 0, (1 .. 3);
        $array[convert_ss($value, 'num')] = 1;
        return \@array;
    }

    return $ss_dict->{uc $value}{$format};
}

# DUMMY
sub convert_acc {
    my ($value, $format) = @_;

    return $value;
}

1;
