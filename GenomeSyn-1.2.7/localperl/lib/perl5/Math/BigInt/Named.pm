#!/usr/bin/perl -w

package Math::BigInt::Named;

require 5.006001;
use strict;

use Math::BigInt::Named;
use vars qw($VERSION @ISA
            $accuracy $precision $round_mode $div_scale);

@ISA = qw(Math::BigInt);

$VERSION = '0.03';

# Globals
$accuracy = $precision = undef;
$round_mode = 'even';
$div_scale = 40;

use Math::BigInt::Named::English;		# default

# Not all of them exist yet
my $LANGUAGE = {
  en => 'english',
  de => 'german',
  sp => 'spanish',
  fr => 'french',
  ro => 'romana',
  it => 'italian',
  };

my $LOADED = { };

sub name
  {
  # output the name of the number
  my ($x) = shift;

  # make Math::BigInt::Name->name(123) work
  $x = $x->new( shift ) unless ref ($x);

  return 'NaN' if $x->is_nan();

  my $opt;
  if (ref($_[0]) eq 'HASH')
    {
    $opt = shift;
    }
  else
    {
    $opt = { @_ };
    }
  my $lang = $opt->{language} || 'english';
  $lang = $LANGUAGE->{$lang} if exists $LANGUAGE->{$lang};	# en => english

  $lang = 'Math::BigInt::Named::' . ucfirst($lang);

  if (!defined $LOADED->{$lang})
    {
    eval "use $lang;"; $LOADED->{$lang} = 1;
    }
  my $y = $lang->new($x);
  $y->name();
  }

sub from_name
  {
  # create a Math::BigInt::Name from a name string
  my $name = shift;

  my $x = Math::BigInt->bnan();
  }

1;

__END__

=head1 NAME

Math::BigInt::Named - Math::BigInts that know their name in some languages

=head1 SYNOPSIS

  use Math::BigInt::Named;

  $x = Math::BigInt::Named->new($str);

  print $x->name(),"\n";			# default is english
  print $x->name( language => 'de' ),"\n";	# but German is possible
  print $x->name( language => 'German' ),"\n";	# like this
  print $x->name( { language => 'en' } ),"\n";	# this works, too

  print Math::BigInt::Named->from_name('einhundert dreiundzwanzig),"\n";

=head1 DESCRIPTION

This is a subclass of Math::BigInt and adds support for named numbers. 

=head1 METHODS

=head2 name()

	print Math::BigInt::Name->name( 123 );

Convert a BigInt to a name.

=head2 from_name()
  
	my $bigint = Math::BigInt::Name->from_name('hundertzwanzig');

Create a Math::BigInt::Name from a name string. B<Not yet implemented!>

=head1 BUGS

Not fully implemented yet. Please see also L<Math::BigInt>.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigFloat> and L<Math::Big> as well as L<Math::BigInt::BitVect>,
L<Math::BigInt::Pari> and  L<Math::BigInt::GMP>.

The package at
L<http://search.cpan.org/search?dist=Math-BigInt-Named> may
contain more documentation and examples as well as testcases.

=head1 AUTHORS

(C) by Tels <http://bloodgate.com> in late 2001, early 2002, 2007.

Based on work by Chris London Noll.

=cut
