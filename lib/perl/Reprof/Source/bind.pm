package Reprof::Source::bind;

sub reprof {
    my ($self, $raw_id) = @_;
    my $dir = "/mnt/project/reprof/data/bind/";

    my $file = "$dir/$raw_id.bind";
    chomp $file;

    return ($file);
}

1;
