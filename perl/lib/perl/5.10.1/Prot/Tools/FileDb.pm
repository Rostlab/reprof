#--------------------------------------------------
# AUTHOR: hoenigschmid@rostlab.org
#-------------------------------------------------- 
#--------------------------------------------------
# Class providing a very simple file based
# database
#-------------------------------------------------- 
package Prot::Tools::FileDb;

use strict;
use feature qw(say);

sub new {
	my $class = shift;

	my $self = {
		_fields	=> [],
		_data	=> [],
		_file	=> undef
	};

	bless $self;
}

sub fields {
	my ($self, @fields) = @_;
	return @{$self->{_fields}} unless @fields;

	$self->{_fields} = \@fields;
}

sub add {
	my ($self, @data) = @_;
	push @{$self->{_data}}, join(';', @data);
}

sub save {
	my ($self, $file) = @_;
	open OUT, '>', $file;
	my $fields = join ';', @{$self->{_fields}};
	say OUT $fields;

	foreach (@{$self->{_data}}) {
		say OUT $_;
	}
	close OUT;
}

sub load {
	my ($self, $file) = @_;
	open IN, $file;
	$self->{_data} = \<IN>;
	close IN;
	$self->fields(split ';', (shift @{$self->{_data}}));
}

1;
