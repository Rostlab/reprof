package Setbench::Source::pssm;

sub reprof {
    my ($self, $raw_id) = @_;
    my $pssm_dir = "/mnt/project/reprof/data/pssm/";

    my $file = "$pssm_dir/$raw_id.pssm";
    
    return $file;
}

1;
