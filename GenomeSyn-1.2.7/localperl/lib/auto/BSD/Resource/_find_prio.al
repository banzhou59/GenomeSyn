# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 559 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/_find_prio.al)"
sub _find_prio ($$) {
    my ($func, $lim) = @_;
    if ($lim =~ /^PRIO_/) {
	my $prios = get_prios();
	if (exists $prios->{$lim}) {
	    $lim = $prios->{$lim};
	}
    }
    if ($lim =~ /^\d+$/) {
	# Looks fine.
    } else {
	croak "$func: Unknown limit '$lim'";
    }
    return $lim;
}

# end of BSD::Resource::_find_prio
1;
