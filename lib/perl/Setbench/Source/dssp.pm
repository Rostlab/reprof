package Setbench::Source::dssp;

sub rost_db {
    my ($self, $raw_id) = @_;
    my $dssp_dir = "/mnt/project/rost_db/data/dssp/";

    my ($id, $chain) = split /:/, $raw_id;
    my $file = "$dssp_dir/" . (substr $id, 1, 2) . "/pdb$id.dssp";

    return ($file, $chain);
}

1;
