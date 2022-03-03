package ActiveState::Unix::ProcInfo;

use strict;
use base 'Exporter';

our @EXPORT_OK = qw(proc_info);

my $ps = "UNIX95=1 /bin/ps";
my $ps_opts;
my $args = "args";
my $rss = "rss";
if ($^O eq "freebsd" or $^O eq 'darwin') {
    $ps_opts = "-axww";
    $args = "command";
}
else {
    $ps_opts = "-e";
    if ($^O eq "linux") {
	$ps_opts .= "ww";
	$ps_opts .= "m"
	    unless `$ps -m 2>&1` =~ /Thread display not implemented/;
    }
    elsif ($^O eq "solaris") {
	$ps_opts .= "L";
    }
    elsif ($^O eq "hpux") {
	$rss = "sz";
    }
    elsif ($^O eq "aix") {
	$ps_opts .= "m";
	$rss = "vsz";  # no such fields on AIX, reusing 'vsz' again
    }
}

sub proc_info {
    my %opts = @_;
    my $root_pid = delete $opts{root_pid};
    my $root_args_match = delete $opts{root_args_match};

    if ($^W) {
	require Carp;
	Carp::carp("Unknown option '$_' passed to proc_info")
	    for keys %opts;
    }

    # get snapshot of currently running processes/threads from ps(1)
    my %ps;
    if (open(my $ps, "$ps ${ps_opts}o pid,ppid,vsz,$rss,$args |")) {
	local $_;
	my $last_pid;
	while (<$ps>) {
	    next unless /^\s*(\d|-)/;
	    chomp;
	    my($pid, $ppid, $vsz, $rss, $args) = split(' ', $_, 5);

	    # AIX will make the 'vsz' field empty for zombies
	    if ($vsz eq "<defunct>") {
		$args = $vsz;
		$vsz = $rss = 0;
	    }

	    $args =~ s/\s+\z//;

	    if ($pid eq "-") {
		# AIX shows pid "-" for threads
		$ps{$last_pid}{threads}++ if $last_pid;
		next;
	    }
	    else {
		$last_pid = $pid;
	    }

	    if ($ps{$pid}) {
		$ps{$pid}{threads} ||= 1;
		$ps{$pid}{threads}++;
		warn "Thread vsz not the same" unless $vsz == $ps{$pid}{vsz};
		warn "Thread rss not the same" unless $rss == $ps{$pid}{rss};
		warn "Thread args not the same" unless $args eq $ps{$pid}{args};
	    }
	    else {
		$ps{$pid} = { ppid => $ppid,
			      vsz  => $vsz,
			      rss  => $rss,
			      args => $args,
			    };
	    }
	}
	close($ps);
    }

    my %process;
    if ($root_pid) {
	$root_pid = [$root_pid] unless ref($root_pid) eq "ARRAY";
	for (@$root_pid) {
	    my $root = delete $ps{$_} || next;
	    $process{$_} = $root;
	}
	unless (%process) {
	    return if wantarray;
	    return \%process;
	}
    }
    elsif ($root_args_match) {
	while (my($pid, $proc) = each %ps) {
	    next unless $proc->{args} =~ $root_args_match;
	    $process{$pid} = delete $ps{$pid};
	}
	unless (%process) {
	    return if wantarray;
	    return \%process;
	}
    }
    else {
	# select them all
	%process = %ps;
	%ps = ();
    }

    
    my $found_proc = 1;
    while ($found_proc) {
	$found_proc = 0;
	for my $pid (keys %ps) {
	    next unless $process{$ps{$pid}{ppid}};
	    $found_proc++;
	    $process{$pid} = delete $ps{$pid};
	}
    }
    undef(%ps);  # the rest is junk

    if ($^O eq "linux") {
	# eliminate and count threads
	for my $pid (keys %process) {
	    my $proc = $process{$pid};
	    my $ppid = $proc->{ppid};
	    my $pproc = $process{$ppid};
	    next unless $pproc;

	    next if $proc->{vsz} != $pproc->{vsz};
	    next if $proc->{rss} != $pproc->{rss};
	    next if $proc->{args} ne $pproc->{args};

	    # We have a parent/child with the same memory sizes and
	    # command line, so assume the child is a thread.  This
	    # also the heuristics that 'ps -m' uses to differentiate
	    # threads from "real" processes.
	    $pproc->{threads} ||= 1;
	    $pproc->{threads} += $proc->{threads} || 1;

	    delete $process{$pid};  # drop record for the thread
	    push(@{$pproc->{thread_pids}}, $pid, @{$proc->{thread_pids} || []});

	    # and re-parent those that had the thread as parent
	    for my $p (values %process) {
		next unless $p->{ppid} == $pid;
		$p->{ppid} = $ppid;
	    }
	}
    }

    # count up process children
    for my $pid (keys %process) {
	my $ppid = $process{$pid}{ppid};
	my $direct_descendant = 1;
	while (my $proc = $process{$ppid}) {
	    last if $ppid == $proc->{ppid};  # proc is its own parent
	    $proc->{children}++ if $direct_descendant;
	    $direct_descendant = 0;
	    $proc->{descendants}++;
	    $ppid = $proc->{ppid};
	}
    }
    
    return \%process unless wantarray;
    
    while (my($pid, $proc) = each %process) {
	$proc->{pid} = $pid;
    }
    return sort { $a->{pid} <=> $b->{pid} } values %process;
}

1;

=head1 NAME

ActiveState::Unix::ProcInfo - Portable extraction of process info

=head1 SYNOPSIS

 use ActiveState::Unix::ProcInfo qw(proc_info);
 my $info = proc_info(root_pid => $$);
 # examine $info

 for my $p (proc_info()) {
     print "$p->{pid} $p->{vsz} $p->{args}\n";
 }

=head1 DESCRIPTION

This module provides a single function called proc_info() that is a
portable wrapper around the system's C<ps> command.  The function
takes the following key/value arguments:

=over

=item root_pid => $pid

=item root_pid => [$pid1, $pid2,...]

Only processes with the given PID (or PIDs) and their descendants are
selected.

=item root_args_match => qr/.../

Only processes and their descendants who's command line matches the 
regular expression are selected.

Note that this might not match as expected on platforms where C<args>
is truncated, see the description of C<args> below.

=back


If no arguments are given, information about all
processes on the system is returned.

In scalar context a hash reference is returned.  The keys of this hash
are the PIDs of the processes selected and the value is a hash with the
following elements:

=over

=item C<ppid>

The PID of the parent of this process.

=item C<vsz>

The size of the process in virtual memory in 1024 byte units.

=item C<rss>

The size of the process in physical memory in 1024 byte units.

=item C<args>

The command with its arguments as a single string.  The command and
arguments are separated by space.  The string might be truncated.

On Solaris it is truncated to the first 80 chars.  On HP-UX it is
truncated to the first 60 chars.  On Linux the limit appears to be 4096.

=item C<threads>

The number of threads running in this process.  This field might be
missing for systems where the thread count can't be determined.

=item C<children>

The number of direct children of this process.

=item C<descendants>

The number of children + grand-children + grand-grand-children + ...

=back

In list context a list of hash references are returned, each one
representing a single process.  The hash has the same fields as
described above, plus a C<pid> field.

=head1 SEE ALSO

L<ps>

=cut
