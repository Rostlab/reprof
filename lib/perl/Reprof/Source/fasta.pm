package Reprof::Source::fasta;
use feature qw(say);

sub predictprotein {
    my ($self, $raw, $seq) = @_;
    say $raw;
    say $seq;

    my $target = "fasta";
    my ($file) = grep /$target/, (`ppc_fetch --seq=$seq`);
    chomp $file;

    return $file;
}

1;
