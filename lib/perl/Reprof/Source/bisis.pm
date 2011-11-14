package Reprof::Source::bisis;

sub reprof {
    my ($self, $raw_id) = @_;
    my $dir = "/mnt/project/reprof/data/bisis/";

    my $file = "$dir/$raw_id/query.dnaBISIS";
    chomp $file;

    return ($file);
}

1;
