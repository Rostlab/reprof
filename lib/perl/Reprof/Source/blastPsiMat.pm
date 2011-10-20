package Reprof::Source::blastPsiMat;

sub predictprotein {
    my ($self, $raw, $seq) = @_;

    my $target = "blastPsiMat";
    my ($file) = grep /$target/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}

1;
