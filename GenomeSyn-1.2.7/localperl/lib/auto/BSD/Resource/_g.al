# NOTE: Derived from blib/lib/BSD/Resource.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package BSD::Resource;

#line 521 "blib/lib/BSD/Resource.pm (autosplit into blib/lib/auto/BSD/Resource/_g.al)"
sub _g {
    exists $_[0]->{$_[1]} ?
	$_[0]->{$_[1]} : die "BSD::Resource: no method '$_[1]',";
}

# end of BSD::Resource::_g
1;
