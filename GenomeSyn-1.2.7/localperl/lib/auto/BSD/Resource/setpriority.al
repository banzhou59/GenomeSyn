# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 617 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/setpriority.al)"
sub setpriority (;$$$) {
    my ($which, $who, $prio) = @_;
    if (@_) {
	$which = _find_prio('setpriority', $which);
    }
    if (@_ == 3) {
	_setpriority($which, $who, $prio);
    } elsif (@_ == 2) {
	_setpriority($which, $who);
    } elsif (@_ == 1) {
	_setpriority($which);
    } else {
	_setpriority();
    }
}

# end of BSD::Resource::setpriority
1;
