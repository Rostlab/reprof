#!/usr/bin/perl

package Prot::Download::Pdb;

use strict;
use Net::FTP;

sub download {
	my $opts = shift;

	# Change pwd to download directory
	chdir $opts->{'local_dir'};

	# Connect to ftp
	my $ftp = Net::FTP->new($opts->{'host'}) or die "ftp connection error $@";
	$ftp->login or die "ftp login error";
    #$ftp->login("anonymous",'-anonymous@') or die "ftp login error";

	# Get remote filelist
	$ftp->cwd($opts->{'remote_dir'}) or die "ftp cwd error";
	my $filelist = $ftp->ls;
	printf "Found %d files on remote server\n", scalar @$filelist;

	# Download files
	my $count = 0;
	foreach (@$filelist) {
		if (!-e $_) {
			printf "Downloading %s (file %d of %d)\n", $_, ++$count, scalar @$filelist;
			$ftp->get($_) or die "ftp get error $@";
		}
		else {
			printf "Skipping %s (file %d of %d)\n", $_, ++$count, scalar @$filelist;
		}
	}

	# Quit ftp connection
    $ftp->quit or die "ftp disconnect error";
}	

1;
