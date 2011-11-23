package Reprof::Source::redisis;

sub reprof {
    my ($self, $raw_id) = @_;
    my $dir = "/mnt/project/reprof/data/redisis/";

    my $file = "$dir/$raw_id.redisis";
    chomp $file;

    return ($file);
}

1;
