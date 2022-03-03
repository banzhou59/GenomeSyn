# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 575 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/getrlimit.al)"
sub getrlimit ($) {
    my $lim = _find_rlimit('getrlimit', $_[0]);
    my @rlimit = _getrlimit($lim);

    if (wantarray) {
	return @rlimit;
    } else {
	return $rlimit[0];
    }
}

# end of BSD::Resource::getrlimit
1;
