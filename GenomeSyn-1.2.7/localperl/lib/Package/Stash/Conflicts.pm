package # hide from PAUSE
    Package::Stash::Conflicts;

use strict;
use warnings;

use Dist::CheckConflicts
    -dist      => 'Package::Stash',
    -conflicts => {
        'Class::MOP' => '1.08',
        'MooseX::Method::Signatures' => '0.36',
        'MooseX::Role::WithOverloading' => '0.08',
        'namespace::clean' => '0.18',
    },
    -also => [ qw(
        B
        Carp
        Dist::CheckConflicts
        Module::Implementation
        Package::DeprecationManager
        Scalar::Util
        Symbol
        constant
        strict
        warnings
    ) ],

;

1;
