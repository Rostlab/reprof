package Setbench::Source::fasta;

sub reprof {
    my ($self, $raw_id) = @_;
    my $fasta_dir = "/mnt/project/reprof/data/fasta/";

    my $file = "$fasta_dir/$raw_id.fasta";
    
    return $file;
}

1;
