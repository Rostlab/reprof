package Setbench::Source::pssm;


sub predictprotein {
    my ($self, $raw_id) = @_;

    #--------------------------------------------------
    # config 
    #-------------------------------------------------- 
    my $target = "blastPsiMat";
    my $fasta_file = "/mnt/project/reprof/data/fasta/$raw_id.fasta";

    my ($file) = grep /$target/, (`ppc_fetch --seqfile=$fasta_file`);

    return $file;
}

1;
