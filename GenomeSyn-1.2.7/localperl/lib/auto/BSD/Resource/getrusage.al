# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 503 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/getrusage.al)"
sub getrusage (;$) {
    my @rusage = _getrusage(@_);

    if (wantarray) {
	@rusage;
    } else {
	my $rusage = {};
	my $key;

	for $key (qw(utime stime maxrss ixrss idrss isrss minflt majflt nswap
		     inblock oublock msgsnd msgrcv nsignals nvcsw nivcsw)) {
	    $rusage->{$key} = shift(@rusage);
	}
	
	bless $rusage;
    }
}

# end of BSD::Resource::getrusage
1;
