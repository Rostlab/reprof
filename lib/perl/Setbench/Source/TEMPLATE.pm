package Setbench::Source::TEMPLATE;

#--------------------------------------------------
# Template for a Source plugin 
#-------------------------------------------------- 

#--------------------------------------------------
# A source method gets an entry from the
# provided list file and should return 
# an absolute pathname to the corresponding
# file
#-------------------------------------------------- 
sub my_example_source_provider_method {
    my ($i_get_dumped, $entry_from_list_file) = @_;
    my $ = "/mnt/project/rost_db/data/dssp/";

    my ($id, $chain) = split /:/, $raw_id;
    my $file = "$dssp_dir/" . (substr $id, 1, 2) . "/pdb$id.dssp";

    return ($file, $chain);
}

1;
