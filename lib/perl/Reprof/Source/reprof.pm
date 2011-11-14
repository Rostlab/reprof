package Reprof::Source::reprof;

sub predictprotein {
    my ($self, $raw, $seq) = @_;

    my $target = "profRdb";
    my ($file) = grep /\.$target$/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}


sub reprof {
    my ($self, $raw, $seq) = @_;

    return "/mnt/project/reprof/data/reprof/$raw.reprof";
}

1;
