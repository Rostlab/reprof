package Reprof::Source::ent;

sub rost_db {
    my ($self, $raw_id) = @_;
    my $dssp_dir = "/mnt/project/rost_db/data/pdb/";

    my ($id, $chain) = split /:/, $raw_id;
    my $file = "$dssp_dir/" . (substr $id, 1, 2) . "/pdb$id.ent";
    chomp $file;

    return ($file, $chain);
}

1;
