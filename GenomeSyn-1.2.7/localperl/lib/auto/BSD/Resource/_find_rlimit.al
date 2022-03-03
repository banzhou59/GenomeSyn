# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 543 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/_find_rlimit.al)"
sub _find_rlimit ($$) {
    my ($func, $lim) = @_;
    if ($lim =~ /^RLIMIT_/) {
	my $rlimits = get_rlimits();
	if (exists $rlimits->{$lim}) {
	    $lim = $rlimits->{$lim};
	}
    }
    if ($lim =~ /^\d+$/) {
	# Looks fine.
    } else {
	croak "$func: Unknown limit '$lim'";
    }
    return $lim;
}

# end of BSD::Resource::_find_rlimit
1;
