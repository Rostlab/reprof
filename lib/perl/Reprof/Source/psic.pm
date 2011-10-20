package Reprof::Source::psic;


sub predictprotein {
    my ($self, $raw, $seq) = @_;

    my $target = "psic";
    my ($file) = grep /$target/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}

1;
