#############################################################################
# Math/Big/Factors.pm -- factor big numbers into prime factors

package Math::Big::Factors;
use vars qw($VERSION);
$VERSION = 1.02;    # Current version of this package
require  5.006002;  # requires this Perl version or later

use Math::BigInt;
use Math::BigFloat;
use Math::Big;
use Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( wheel factors_wheel
               );
#@EXPORT = qw( );
use strict;

sub wheel
  {
  # calculate a prime-wheel of order $o
  my $o = abs(shift || 1);              # >= 1

  # some primitive wheels as shortcut:
  return [ Math::BigInt->new(2), Math::BigInt->new(1) ] if $o == 1;

  my @primes = Math::Big::primes($o*5);		# initial primes, get some more

  my $mul = Math::BigInt->new(1); my @wheel;
  for (my $i = 0; $i < $o; $i++)
    {
    #print "$primes[$i]\n";
    $mul *= $primes[$i]; push @wheel,$primes[$i];
    }
  #print "Mul $mul\n";
  my $last = $wheel[-1];                        # get biggest initial
  #print "last is $last\n";
  # now sieve any number that is a multiply of one of the inital ones
  @primes = ();                                 # undef => leftover
  foreach (@wheel)
    {
    next if $_ == 2;                            # dont mark these, we skip 'em
    my $i = $_; my $add = $i;
    while ($i < $mul)
      {
      $primes[$i] = 1; $i += $add;
      }
    }
  push @wheel, Math::BigInt->new(1);
  my $i = $last;
  while ($i < $mul)
    {
    push @wheel,$i if !defined $primes[$i]; $i += 2;    # skip even ones
    }
  \@wheel;
  }
 
sub _transform_wheel
  {
  # from a given prime-wheel, calculate a increment table that can be used
  # to step trough numbers
  # input:  ref to array with prime wheel
  # output: ($restart,$ref_to_add_table);

  my (@wheel,$we);
  my $add = shift; shift @$add;         # remove the first 2 from wheel

  if (@$add == 1)                       # order 1
    {
    my $two = Math::BigInt->new(2);
    # (2,2) or (2,2,2,2,2,2) etc would do, too
    @wheel = ($two->copy(),$two->copy(),$two->copy(),$two->copy());
    return (1,\@wheel);
    }
  # from the list of divisors above create a add-table which we can take to
  # increment from 3 onwards. The tabe consists of two parts, the second part
  # will be repeatedly used
  my $last = -1; my $mod = 2; my $i = 0;
  # create the increment part for the initial primes (3,5, or 3,5,7 etc)
  while ($add->[$i] != 1)
    {
    $mod *= $add->[$i];
    push @wheel, $add->[$i] - $last if $last != -1;     # skip the first
    #print $wheel[-1],"\n" if $last != -1;
    $last = $add->[$i]; $i++;
    }
  #print "mod $mod\n";
  my $border = $i-1;                                    # account for ++
  my $length = scalar @$add-$i;
  my $ws = $border+$length;                             # remember this
  #print "border: $border length $length $mod\n";

  # now we add two arrays in a row, both are equal except the first element
  # which is in case A a step from the last inital prime to the second in list
  # and in case B a step from '1' to the second in list

  #print "add[border+1]: ",$add->[$border+1]," add[border] $add->[$border]\n";
  $wheel[$border] = $add->[$border+2]-$add->[$border];
  $wheel[$border+$length] = $add->[$border+2]-1;
  # and last add a wrap-around around $mod
  #print "last: ",$add->[-1],"\n";
  $wheel[$border+$length-1] = 1+$mod-$add->[-1];
  $wheel[$border+$length*2-1] = $wheel[$border+$length-1];
 
  $i = $border + 1;
  # now fill in the rest
  while ($i < $length+$border-1)
    {
    $wheel[$i] = $add->[$i+2]-$add->[$i+1];
    $wheel[$i+$length] = $wheel[$i];
    $i++;
    }
  ($ws,\@wheel);
  }

sub factors_wheel
  {
  my $n = shift;
  my $o = abs(shift || 1);

  $n = Math::BigInt->new($n) unless ref $n;
  my $two = Math::BigInt->new(2);
  my $three = Math::BigInt->new(3);

  my @factors = ();
  my $x = $n->copy();

  return ($x) if $x < 4;
  my ($i,$y,$w,$div,$rem);

  #print "Using a wheel of order $o, length ";
  my $wheel = wheel($o);
  #print scalar @$wheel,":\n";
  my ($ws,$add) = _transform_wheel($wheel); undef $wheel;
  my $we = scalar @$add - 1;

  # reduce to odd number (after that, no odd left-over divisior will ocur)
  while (($x->is_even) && (!$x->is_zero))
    {
    push @factors, $two->copy();
    #print "factoring $x (",$x->length(),")\n";
    #print "2\n";
    $x /= $two;
    }
  # 8 => 6 => 3, 7, 6 => 3, 5, 4 => 2 => 1, 3, 2 => 1, are all prime
  # so the first number interesting for us is 9
  my $op = 0;
 OUTER:
  while ($x > 8)
    {
    #print "factoring $x (",$x->length(),")\n";
    $i = $three; $w = 0;
    while ($i < $x)             # should be sqrt()
      {
      # $steps++;
      # $op = 0, print "$i\r" if $op++ == 1024;
      $y = $x->copy();
      ($div,$rem) = $y->bdiv($i);
      if ($rem == 0)
        {
        #print "$i\n";
        push @factors,$i;
        $x = $div; next OUTER;
        }
      #print "$i + ",$add->[$w]," ($w)\n";
      #$i += 2;                                   # trial div by odd numbers
      $i += $add->[$w];
      #print "restart $w $ws\n" if $w == $we;  # wheel of 2,3,5,7...
      $w = $ws if $w++ == $we;                  # wheel of 2,3,5,7...
      #exit if $i > 100000;
      }
    last;
    }
  push @factors,$x if $x != 1 || $n == 1;
  @factors;
  }

sub _factor
  {
  # later: factor ( n => $n, algorithmn => 'wheel', order => 3 );
  }

1;
__END__

#############################################################################

=head1 NAME

Math::Big::Factors - factor big numbers into prime factors using different algorithmns

=head1 SYNOPSIS

    use Math::Big::Factors;

    $wheel	= wheel (4);			# prime number wheel of 2,3,5,7
    print $wheel->[0],$wheel->[1],$wheel->[2],$wheel->[3],"\n";

    @factors	= factor_wheel(19*71*59*3,1);	# using prime wheel of order 1
    @factors	= factor_wheel(19*71*59*3,7);	# using prime wheel of order 7

=head1 REQUIRES

perl5.005, Exporter, Math::BigInt, Math::BigFloat, Math::Big

=head1 EXPORTS

Exports nothing on default, but can export C<wheel()>, C<factor()>,
C<factor_wheel()>;

=head1 DESCRIPTION

This module contains some routines that may come in handy when you want to
factor big numbers into prime factors.
examples.

=head1 METHODS

=head2 B<wheel()>

	$wheel = wheel($o);

Returns a reference to a prime wheel of order $o. This is used for factoring
numbers into prime factors.

A wheel of order 7 saves about 50% of all trial divisions over the normal
trial division factor algorihmn. Higher oder will save less and less, but
a wheel of size 8 takes so long to compute and much memory that it is not
worth the effort, limiting wheels of practicable size to order 7. For very
small numbers the computation of the wheel of order 7 may actually take
longer than the factorization, but anything that has more than 10 digits will
usually benefit from order 7.

=head2 B<factors_wheel()>

Factor a number into its prime factors and return a list of factors.

=head1 BUGS

None discovered yet.

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

If you use this module in one of your projects, then please email me. I want
to hear about how my code helps you ;)

Quite a lot of ideas from other people, especially D. E. Knuth, have been used,
thank you!

Tels http://bloodgate.com 2001-2007.

=cut

1;
