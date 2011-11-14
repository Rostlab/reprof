package Reprof::Source::isis;

sub predictprotein {
    my ($self, $raw, $seq) = @_;

    my @split = split /::/, $self;
    my $target = $split[scalar @split - 1];

    my ($file) = grep /\.$target$/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}

1;
