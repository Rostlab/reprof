package Reprof::Source::horiz;

sub reprof {
    my ($self, $raw_id) = @_;
    my $horiz_dir = "/mnt/project/reprof/data/horiz";

    my $file = "$horiz_dir/$raw_id.horiz";
    chomp $file;

    return $file;
}

1;
