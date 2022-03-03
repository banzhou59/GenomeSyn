# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 633 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/times.al)"
sub times {
    use BSD::Resource qw(RUSAGE_SELF RUSAGE_CHILDREN);

    my ($u,  $s ) = _getrusage(RUSAGE_SELF);
    my ($cu, $cs) = _getrusage(RUSAGE_CHILDREN);

    return ($u, $s, $cu, $cs);
}

1;
1;
# end of BSD::Resource::times
