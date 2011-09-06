package Setbench::Source::fasta;

sub predictprotein {
    my ($self, $raw_id) = @_;

    #--------------------------------------------------
    # config 
    #-------------------------------------------------- 
    my $target = "fasta";
    my $fasta_file = "/mnt/project/reprof/data/fasta/$raw_id.fasta";

    my ($file) = grep /$target/, (`ppc_fetch --seqfile=$fasta_file`);

    return $file;
}

1;
