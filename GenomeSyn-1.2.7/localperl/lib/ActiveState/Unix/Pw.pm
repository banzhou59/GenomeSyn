package ActiveState::Unix::Pw;

use strict;
use ActiveState::Run qw(run);
use Cwd;

use base 'Exporter';
our @EXPORT_OK;

my %cmd;
my %commands = (
        useradd => 'useradd',
        userdel => 'userdel',
        usermod => 'usermod',
        groupadd => 'groupadd',
        groupdel => 'groupdel',
        su       => 'su',
);

if ($^O eq 'aix') {
    @commands{qw(useradd userdel usermod groupadd groupdel)} =
              qw(mkuser  rmuser  chuser  mkgroup  rmgroup);
}

for my $c (keys %commands) {
    $cmd{$c}{cmd} = [$commands{$c}];
    push(@EXPORT_OK, $c);
}

if (-x "/usr/sbin/pw") {
    for my $v (values %cmd) {
	unshift(@{$v->{cmd}}, "/usr/sbin/pw");
    }
}
else {
    for my $v (values %cmd) {
        if ($v->{cmd}[0] eq 'mkuser' or 
            $v->{cmd}[0] eq 'chuser' or
            $v->{cmd}[0] eq 'mkgroup') {
            substr($v->{cmd}[0], 0, 0) = "/usr/bin/";
        }
        else {
            substr($v->{cmd}[0], 0, 0) = "/usr/sbin/";
        }
    }
}

sub useradd {
    my %opt = @_;
    my @cmd = @{$cmd{useradd}{cmd}};
    return ActiveState::Unix::Darwin::Pw::useradd(\%opt) if $^O eq 'darwin';

    # default arguments
    my %arg = ( comment => '-c',
                home => '-d',
                create_home => sub { '-m' },
                uid => '-u',
              );
    # os specific arguments
    my %osarg = ( aix => { comment => sub { "gecos=$_[0]" },
                           home => sub { "home=$_[0]" },
                           create_home => sub { "" },
                           group => sub { "groups="
                                          . join(',', grep defined, @{$_[0]}) },
			   uid => sub { "" },
                         },
                  freebsd => { user => sub { "-n", $_[0] },
                             },
                );
                           
    foreach my $o (qw(comment home create_home uid group user )) {
        my $v = delete $opt{$o};
        die "user option is mandatory for useradd" if $o eq 'user' and !$v;
        next unless defined $v;
            
        # use the default arg if it exists and the value  
        my @foo = ($arg{$o}, $v);
        @foo = ($arg{$o}->($v)) if ref($arg{$o}) eq 'CODE';

        # default group args are a little trickier...
        if ($o eq 'group') {
            $v = [$v] unless ref($v) eq 'ARRAY';
            my ($pg, @og) = @$v;
            @foo = defined $pg ? ('-g', $pg) : ();
            push @foo, '-G', join(',', @og) if @og;
        }

        # os specific option
        @foo = ($osarg{$^O}{$o}->($v)) if exists $osarg{$^O}{$o};

        push @cmd, grep {defined and length} @foo;
    }

    _run('useradd', \%opt, \@cmd);
}

sub userdel {
    my %opt = @_;
    my @cmd = @{$cmd{userdel}{cmd}};
    my $user;
    my $home;
    my $norun = $opt{_norun};
    return ActiveState::Unix::Darwin::Pw::userdel(\%opt) if $^O eq 'darwin';

    if ($^O eq 'aix') {
        if (delete $opt{remove_home} and $opt{user}) {
            # find user's home dir for AIX
            my $lsuser = `/usr/sbin/lsuser -a home $opt{user} 2>/dev/null`;
            if (!$? and $lsuser) {
		chomp($lsuser);
                ($home = $lsuser) =~ s/^.*?=//;
            }
        }
    }
    else {
        push(@cmd, "-r") if delete $opt{remove_home};
    }
    
    if ($user = delete $opt{user}) {
	push(@cmd, "-n") if $^O eq "freebsd";
	push(@cmd, $user);
    }
    else {
	die "user option is mandatory for userdel";
    }
    my ($rc,@rc);
    if (wantarray and $norun) {
        @rc = _run('userdel', \%opt, \@cmd);
    }
    else {
        $rc = _run('userdel', \%opt, \@cmd);
    }
        
    # manually remove home dir for AIX
    if ($home) {
        my @rm_cmd = ('rm','-rf',$home);
        # don't run it, just show the command we would have run
        if ($norun) {
            wantarray ? return (@cmd,';',@rm_cmd) : return $rc.";"._shell_escape(@rm_cmd);
        }
        # run the command
        elsif ($rc) {
            $rc = run(@rm_cmd);
        }
    }

    $rc;
}

sub usermod {
    my %opt = @_;
    my @cmd = @{$cmd{usermod}{cmd}};

    # default arguments
    my %arg = ( home => '-d',
                login => '-l',
              );
    # os specific arguments
    my %osarg = ( aix => { home => sub { "home=$_[0]" },
                           # chuser doesn't have options to do this.  The
                           # workaround is to create a new user with the same
                           # uid, and then delete the old user
                           login => sub { die "Not available on AIX" },
                         },
                  freebsd => { user => sub { "-n", $_[0] } },
                );
                           
    foreach my $o (qw(home login user)) {
        my $v = delete $opt{$o};
        die "user option is mandatory for usermod" if $o eq 'user' and !$v;
        next unless defined $v;
            
        # use the default arg if it exists and the value  
        my @foo = ($arg{$o}, $v);
        @foo = ($arg{$o}->($v)) if ref($arg{$o}) eq 'CODE';

        # os specific option
        @foo = ($osarg{$^O}{$o}->($v)) if exists $osarg{$^O}{$o};

        push @cmd, grep defined, @foo;
    }

    _run('usermod', \%opt, \@cmd);
}

sub groupadd {
    unshift(@_, "group") if @_ == 1;
    my %opt = @_;
    my @cmd = @{$cmd{groupadd}{cmd}};
    return ActiveState::Unix::Darwin::Pw::groupadd(\%opt) if $^O eq 'darwin';

    if (exists $opt{gid}) {
	my $gid = int(delete $opt{gid});
	if ($^O eq 'aix') {
            push(@cmd, "id=$gid");
	}
	else {
            push(@cmd, "-g", $gid);
	}
    }

    if ($^O eq 'aix') {
        delete $opt{unique}; # ignore for aix - can't override
    }
    else {
        push(@cmd, "-o") if exists $opt{unique} && !delete $opt{unique};
    }
    
    #Redhat Linux specific - on other OS's _run() will warn about unknown options
    if ($^O eq 'linux') {
        push(@cmd, "-r") if delete $opt{system};
        push(@cmd, "-f") if delete $opt{force};
    }

    # must be last
    if (my $g = delete $opt{group}) {
	push(@cmd, $g);
    }
    else {
	die "user option is mandatory for groupadd";
    }

    _run('groupadd', \%opt, \@cmd);
}

sub groupdel {
    unshift(@_, "group") if @_ == 1;
    my %opt = @_;
    my @cmd = @{$cmd{groupdel}{cmd}};
    return ActiveState::Unix::Darwin::Pw::groupdel(\%opt) if $^O eq 'darwin';

    if (my $g = delete $opt{group}) {
	push(@cmd, $g);
    }
    else {
	die "group option is mandatory for groupdel";
    }
    _run('groupdel', \%opt, \@cmd);
}

sub _run {
    my($f, $opt, $cmd) = @_;

    my $norun = delete $opt->{_norun};
    my $nocroak = delete $opt->{_nocroak};

    for my $o (sort keys %$opt) {
	warn "Unrecognized option '$o' in $f";
    }

    #use Data::Dump; Data::Dump::dump($cmd);
    substr($cmd->[0], 0, 0) = "-" if $nocroak;

    return run(@$cmd) unless $norun;
    wantarray ? @$cmd : _shell_escape(@$cmd);
}

sub _shell_escape {
    my @words = @_;
    for (@words) {
	# XXX real escapes etc
	$_ = qq("$_") if /\s/;
    }
    join(" ", @words);
}


sub su {
    my %opt = @_;
    my @cmd = ();

    # su Notes
    # Linux     /bin            su - user -c "command args"
    # Solaris   /usr/bin        su - user -c "command args"
    # FreeBSD   /usr/bin        su - user -c "command args"
    # Darwin    /usr/bin        su - user -c "command args"
    # HP-UX     /usr/bin        su - user -c "command args"
    # AIX       /usr/bin        su - user "-c dir/command options"
    my $silent = delete $opt{silent} ? '@' : '';
    if ($^O eq 'linux') {
        push(@cmd, "$silent/bin/su");
    }
    else {
        push(@cmd, "$silent/usr/bin/su");
    }

    my $login = "-" if delete $opt{login};

    my $u = delete $opt{user};
    die "user option is mandatory for su" unless $u;
    push(@cmd, $login) if $login;
    push(@cmd, $u);

    if (my $cmd = delete $opt{command}) {
        if ($^O eq 'aix') {
            push(@cmd, "-c $cmd");
        }
        else {
            push(@cmd, "-c", $cmd);
        }
    }

    my $cur_dir = getcwd();
    my $user_home = getpwnam $u;
    chdir $user_home if $user_home;
    my $rc;
    eval {
        $rc = _run('su', \%opt, \@cmd);
    };
    my $err = $@;
    chdir $cur_dir if $user_home and $cur_dir;
    die $err if $err;
    return $rc;
}

package ActiveState::Unix::Darwin::Pw;

my $niutil = "/usr/bin/niutil";
my $nidump = "/usr/bin/nidump";
my $passwd = "/usr/bin/passwd";

sub _run {
    my ($f, $opt, $cmd) = @_;
    warn "$f: @$cmd\n";
    return ActiveState::Unix::Pw::_run(@_)
}

sub useradd {
    my $opt = shift;

    my ($user, $comment, $home, $create_home, $group) = delete @$opt{qw(
	 user   comment   home   create_home   group
    )};

    if ($user) {
	my @cmd;

	# Find the next free UID:
	chomp(my $uid = `$nidump passwd . | cut -d: -f3 | sort -n | tail -1`);
	die "WHOA: can't set uid for $user" unless defined $uid && $uid >= 0;
	++$uid;

	_run('useradd', $opt, [$niutil, '-create', '.', "/users/$user"]);
	_run('useradd', $opt,
	    [$niutil, '-createprop', '.', "/users/$user", 'passwd', '*']);
	_run('useradd', $opt,
	    [$niutil, '-createprop', '.', "/users/$user", uid => $uid]);
	_run('useradd', $opt,
	    [$niutil, '-createprop', '.', "/users/$user", shell => '/bin/bash']);
    }
    else {
	die "user option is mandatory for useradd";
    }

    my $pg;
    if ($group) {
	my @og;
	$group = [$group] unless ref($group) eq 'ARRAY';
	($pg, @og) = @$group;

	# Set the primary group id
	if (defined $pg) {
	    defined(my $gid = getgrnam($pg))
		or die "useradd: invalid group $pg";
	    _run('useradd', $opt,
		[$niutil, '-createprop', '.', "/users/$user", gid => $gid]);
	}

	# Add this user to the other groups
	for my $g (@og) {
	    defined (my $gid = getgrnam($g))
		or die "useradd: invalid group $g";
	    _run('useradd', $opt,
		[$niutil, '-appendprop', '.', "/groups/$g", users => $user]);
	}
    }
    else {
	die "group option is mandatory for useradd on darwin";
    }

    if ($comment) {
	_run('useradd', $opt,
	    [$niutil, '-createprop','.', "/users/$user", realname => $comment]);
    }

    $home ||= "/Users/$user";
    _run('useradd', $opt,
	[$niutil, '-createprop', '.', "/users/$user", home => $home]);

    if ($create_home) {
	mkdir($home) or die "useradd: can't mkdir $home: $!";
	_run('useradd', $opt, ['/usr/sbin/chown', '-R', "$user:$group", $home]);
	_run('useradd', $opt, ['/bin/chmod', '755', $home]);
    }
}

sub userdel {
    my $opt = shift;
    die;
}

sub groupadd {
    my $opt = shift;

    delete $opt->{unique}; # not supported in Mac OS X

    my ($group, $gid) = delete @$opt{qw(
	 group   gid
    )};

    unless (defined $gid) {
	# Find the next free GID:
	chomp($gid = `$nidump group . | cut -d: -f3 | sort -n | tail -1`);
	die "WHOA: can't set gid for $group" unless defined $gid && $gid >= 0;
	++$gid;
    }

    if ($group) {
	_run('groupadd', $opt, [$niutil, '-create', '.', "/groups/$group"]);
    }
    else {
	die "group option is mandatory for groupadd";
    }

    _run('groupadd', $opt,
	[$niutil, '-createprop', '.', "/groups/$group", gid => $gid]);

    _run('groupadd', $opt, ["\@$nidump group . >/dev/null"]);
    sleep 1;
}

sub groupdel {
    my $opt = shift;
    die;
}

1;

__END__

=head1 NAME

ActiveState::Unix::Pw - Portable manipulation of user accounts

=head1 SYNOPSIS

 use ActiveState::Unix::Pw qw(useradd userdel groupadd groupdel su);

=head1 DESCRIPTION

The C<ActiveState::Unix::Pw> module provide functions to add and
remove user accounts from the system.  It is a portable interface to
the system utility commands that manipulate the passwd and group
databases.

All functions provided take key/value pairs as arguments.  The
following special arguments are recognized by all functions:

=over

=item _norun

Instead of feeding commands to the run() function (see
L<ActiveState::Run>) the commands to run are returned as a string.

=item _nocroak

Tell the run() not to ignore errors.  By default it will croak if the
command signals an error.

=back

The following functions are provided by this module.  None of them are
exported by default:

=over

=item useradd( %opts )

The following options are recognized:

=over

=item user

The username to use.  Mandatory.

=item comment

The password comment field.  Usually the full name of the user.

=item home

The home directory to use.

=item create_home

Boolean; if TRUE create the home directory and set it up.  If FALSE
only the password database is updated.

=item group

What group or group should this user be part of.  The value can either
be a plain scalar or an array reference if multiple groups are to be
specified.  When multiple groups are specified, then the first group
will be the primary group.  The first group can be specified as
C<undef> to let the system select a default primary group.

=back

=item userdel( %opts )

The following options are recognized:

=over

=item user

The username to delete.  Mandatory.

=item remove_home

Boolean; if TRUE then the home directory will be deleted as well as
the user information.

=back

=item usermod( %opts )

The following options are recognized:

=over

=item user

The username to modify.  Mandatory.

=item home

The new home directory of the user.

=item login

The new login name of the user.

=back

=item groupadd( %opts )

The following options are recognized:

=over

=item group

The group name to add.  Mandatory.

=item gid

A group identifier.  If left unspecified a free one will be
assigned.

=item unique

Boolean; if TRUE non-unique gids are allowed.  Does not work everywhere.

=item system

Make a system account.  Only available on Linux.

=item force

Boolean; this will cause failure if the group already exists.  Only
available on Linux.

=back

=item groupdel( %opts )

The following extra option is recognized:

=over

=item group

The value is the name of the group to delete.  Mandatory.

=back

=item su( %opts )

The following options are recognized:

=over

=item user

The username to su to.  Mandatory.

=item command

The command to execute as the specified user.

=item login

If true, makes the shell a login shell.

=item silent

If true, suppresses the command echo.

=back

=cut

=head1 COPYRIGHT

Copyright (C) 2003 ActiveState Corp.  All rights reserved.

=head1 SEE ALSO

L<ActiveState::Run>
