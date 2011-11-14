package Reprof::Source::blastPsiMat;

sub predictprotein {
    my ($self, $raw, $seq) = @_;

    my @split = split /::/, $self;
    my $target = $split[scalar @split - 1];

    my ($file) = grep /\.$target$/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}

sub hhblits_sec {
    my ($self, $raw, $seq) = @_;

    my $file = "/mnt/project/reprof/data/hhblits_sec/$raw.blastPsiMat";

    return $file;
}

sub hhblits_dna {
    my ($self, $raw, $seq) = @_;

    my $file = "/mnt/project/reprof/data/hhblits_dna/$raw.blastPsiMat";

    return $file;
}

sub hhblits_sec_nr {
    my ($self, $raw, $seq) = @_;

    my $file = "/mnt/project/reprof/data/hhblits_sec_nr/$raw.blastPsiMat";

    return $file;
}

sub hhblits_dna_nr {
    my ($self, $raw, $seq) = @_;

    my $file = "/mnt/project/reprof/data/hhblits_dna_nr/$raw.blastPsiMat";

    return $file;
}

1;
