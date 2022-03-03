package ActiveState::Unix::DiskFree;

use strict;
use base 'Exporter';
our @EXPORT_OK = qw(df);

our @df = ("df", "-Pk");
$df[0] = "/usr/xpg4/bin/df" if $^O eq "solaris";
$df[1] = "-k" if $^O eq 'darwin';

sub df {
    my @files = @_;
    my $pid = open(my $df, "-|");
    die "Can't fork: $!" unless defined $pid;
    unless ($pid) {
	open(STDERR, ">/dev/null");
	exec(@df, @files);
	die "Can't exec $df[0]: $!";
    }

    my @res;
    local $_;
    my $first = 1;
    while(<$df>) {
	chomp;
	if ($first) {
	    $first = 0;
	    s/\s+/ /g;
	    die "Unrecongnized df output format: '$_'"
		unless /^Filesystem 1(?:024|[Kk])-blocks Used Avail(?:able)? (Use%|Capacity) Mounted on$/;
	}
	else {
	    my($fs, $total, $used, $free, $used_p, $root) = split(' ', $_, 6);
	    push(@res, {
		filesystem => $fs,
		size => $total * 1024,
		used => $used * 1024,
		($used_p && $used_p =~ s/%$// ? (used_p => $used_p) : ()),
		free => $free * 1024,
		root => $root,
	    });
	}
    }
    close($df);
    die "'$df[0]' failed: $?" if $?;

    wantarray ? @res : $res[0];
}

1;

=head1 NAME

ActiveState::Unix::DiskFree - Portable interface to the df command

=head1 SYNOPSIS

 use ActiveState::Unix::DiskFree qw(df);
 my $info = df(".");
 print "$info->{free} bytes available.\n";

=head1 DESCRIPTION

This module provide a single function called df() that run the system
utility C<df> and returns the information extracted.

=over

=item $info = df(".")

=item ($info_root, $info_var) = df("/", "/var")

=item @info = df()

The df() function returns disk status information for the directories
given as argument.  If no argument is given it will return an entry
for each file system present.  In scalar context only the first
entry is returned.

An information entry is a reference to an hash with the following
keys:

=over

=item filesystem

The name of disk partition that this file system resides on.

=item root

The location that this disk partition is mounted.

=item size

Amount of disk space (in bytes) present in the file system.

=item used

Amount of allocated disk space (in bytes).

=item used_p

Percentage of disk space allocated.  This field might be missing.

=item free

Amount of unallocated disk space (in bytes).

=back


=head1 COPYRIGHT

Copyright (C) 2003 ActiveState Corp.  All rights reserved.

=head1 SEE ALSO

L<ActiveState::Bytes>

