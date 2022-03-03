# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 611 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/setrlimit.al)"
sub setrlimit ($$$) {
    my ($lim, $soft, $hard) = @_;
    $lim = _find_rlimit('setrlimit', $lim);
    _setrlimit($lim, $soft, $hard);
}

# end of BSD::Resource::setrlimit
1;
