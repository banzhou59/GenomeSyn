package Clone;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw( clone );

$VERSION = '0.34';

bootstrap Clone $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Clone - recursively copy Perl datatypes

=head1 SYNOPSIS

  package Foo;
  use parent 'Clone';

  package main;
  my $original = Foo->new;
  $copy = $original->clone;
  
  # or

  use Clone qw(clone);
  
  $a = { 'foo' => 'bar', 'move' => 'zig' };
  $b = [ 'alpha', 'beta', 'gamma', 'vlissides' ];
  $c = Foo->new;

  $d = clone($a);
  $e = clone($b);
  $f = clone($c);

=head1 DESCRIPTION

This module provides a clone() method which makes recursive
copies of nested hash, array, scalar and reference types, 
including tied variables and objects.


clone() takes a scalar argument and duplicates it. To duplicate lists,
arrays or hashes, pass them in by reference. e.g.
    
    my $copy = clone (\@array);

    # or

    my %copy = %{ clone (\%hash) };

=head1 SEE ALSO

L<Storable>'s dclone() is a flexible solution for cloning variables,
albeit slower for average-sized data structures. Simple
and naive benchmarks show that Clone is faster for data structures
with 3 or less levels, while dclone() can be faster for structures
4 or more levels deep.

=head1 COPYRIGHT

Copyright 2001-2012 Ray Finch. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Ray Finch C<< <rdf@cpan.org> >>

Breno G. de Oliveira C<< <garu@cpan.org> >> and
Florian Ragwitz C<< <rafl@debian.org> >> perform routine maintenance
releases since 2012.

=cut
