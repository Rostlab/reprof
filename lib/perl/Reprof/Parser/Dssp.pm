package Reprof::Parser::Dssp;

use strict;
use feature qw(say);

use Reprof::Tools::Converter qw(convert_res convert_id convert_ss convert_acc);

sub new {
    my ($class, $file) = @_;

    my $self = {
        _file   => $file || warn "No file given to parser\n",
        _chains => [],
        _chain  => {}
    };

    bless $self, $class;
    $self->_parse;
    return $self;
}

sub _parse {
    my $self = shift;

    my $id = convert_id($self->{_file}, "pdb");

    my $res_started = 0;
    my $break = 0;
    open FH, $self->{_file} or return 0;# "Could not open $file\n";
    while (my $line = <FH>) {
        if (!$res_started && $line =~ m/^  #  RESIDUE AA STRUCTURE/) {
            $res_started = 1;
        }
        elsif ($res_started) {
            if ($line =~ /!\*/) { # chain break
                $break = 0;
            }
            elsif ($line =~ /!/) { # interrupted backbone 
                $break++;
            }
            else {
                my $resnr = _parsefield($line, 3, 5);
                my $chain = _parsefield($line, 12, 12);# . $break;				
                my $res = _parsefield($line, 14, 14);
                my $ss  = _parsefield($line, 17, 17);
                my $acc = _parsefield($line, 36, 38);

                push @{$self->{_chain}{$chain}{_pos}}, $resnr;
                push @{$self->{_chain}{$chain}{_acc}}, convert_acc($acc);
                push @{$self->{_chain}{$chain}{_ss}}, convert_ss($ss, "oneletter");
                push @{$self->{_chain}{$chain}{_res}}, convert_res($res, "oneletter");
            }
        }
    }
    close FH;

    foreach my $chain (sort keys %{$self->{_chain}}) {
        push @{$self->{_chains}}, $chain;
        $self->{_chain}{$chain}{_id} = "$id:$chain";
    }
}

sub get_pos {
    my ($self, $chain) = @_;

    return $self->{_chain}{$chain}{_pos};
}

sub get_ss {
    my ($self, $chain) = @_;

    return $self->{_chain}{$chain}{_ss};
}

sub get_res {
    my ($self, $chain) = @_;

    return $self->{_chain}{$chain}{_res};
}

sub get_acc {
    my ($self, $chain) = @_;

    return $self->{_chain}{$chain}{_acc};
}

sub get_id {
    my ($self, $chain) = @_;

    return $self->{_chain}{$chain}{_id};
}

sub get_chains {
    my $self = shift;

    return $self->{_chains};
}

#--------------------------------------------------
# INTERN
#-------------------------------------------------- 

#--------------------------------------------------
# Function which returns a part of a record field
# (taking the numbers provided in the pdb doc)
#-------------------------------------------------- 
sub _parsefield {
    my ($entry, $from, $to) = @_;
    my $val;
    if (defined $to) {
        $val = substr $entry, $from - 1, $to-($from - 1);
    }
    else {
        $val = substr $entry, $from - 1;
    }

    chomp $val;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    return $val;
}

1;
