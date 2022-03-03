# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 597 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/getpriority.al)"
sub getpriority (;$$) {
    my ($which, $who) = @_;
    if (@_) {
	$which = _find_prio('getpriority', $which);
    }
    if (@_ == 2) {
	_getpriority($which, $who);
    } elsif (@_ == 1) {
	_getpriority($which);
    } else {
	_getpriority();
    }
}

# end of BSD::Resource::getpriority
1;
