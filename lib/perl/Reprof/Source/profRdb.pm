package Reprof::Source::profRdb;


sub predictprotein {
    my ($self, $raw, $seq) = @_;

    my $target = "profRdb";
    my ($file) = grep /$target/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}

1;
