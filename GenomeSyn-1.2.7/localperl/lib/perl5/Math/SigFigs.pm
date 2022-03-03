package Math::SigFigs;

# Copyright (c) 1995-2009 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################

require 5.000;
require Exporter;
use Carp;
use warnings;
@ISA = qw(Exporter);
@EXPORT     = qw(FormatSigFigs
                 CountSigFigs
                );
@EXPORT_OK  = qw(FormatSigFigs
                 CountSigFigs
                 addSF subSF multSF divSF
                 VERSION);

%EXPORT_TAGS = (all => \@EXPORT_OK);

$VERSION = 1.09;

use strict;

sub addSF {
  my($n1,$n2)=@_;
  $n1 = _Simplify($n1);
  $n2 = _Simplify($n2);
  return ()  if (! defined $n1  ||  ! defined $n2);
  return $n2 if ($n1==0);
  return $n1 if ($n2==0);

  my $m1 = _LSP($n1);
  my $m2 = _LSP($n2);
  my $m  = ($m1>$m2 ? $m1 : $m2);

  my($n) = $n1+$n2;
  my($s) = ($n<0 ? "-" : "");
  $n     = -1*$n  if ($n<0);          # n = 1234.44           5678.99
  $n =~ /^(\d*)/;
  my $i = ($1);                       # i = 1234              5678
  my $l = length($i);                 # l = 4

  if ($m>0) {                         # m = 5,4,3,2,1
    if ($l >= $m+1) {                 # m = 3,2,1; l-m = 1,2,3
      $n = FormatSigFigs($n,$l-$m);   # n = 1000,1200,1230    6000,5700,5680
    } elsif ($l == $m) {              # m = 4
      if ($i =~ /^[5-9]/) {
        $n = 1 . "0"x$m;              # n =                   10000
      } else {
        return 0;                     # n = 0
      }
    } else {                          # m = 5
      return 0;
    }

  } elsif ($i>0) {                    # n = 1234.44           5678.99
    $n = FormatSigFigs($n,$l-$m);     # m = 0,-1,-2,...

  } else {                            # n = 0.1234    0.00123   0.00567
    $n =~ /\.(0*)(\d+)/;
    my ($z,$d) = ($1,$2);
    $m = -$m;

    if ($m > length($z)) {            # m = -1,-2,..  -3,-4,..  -3,-4,..
      $n = FormatSigFigs($n,$m-length($z));

    } elsif ($m == length($z)) {      # m =           -2        -2
      if ($d =~ /^[5-9]/) {
        $n = "0." . "0"x($m-1) . "1"; # n =                     0.01
      } else {
        return 0;                     # n =           0
      }

    } else {                          # m =           -1        -1
      return 0;
    }
  }

  return "$s$n";
}

sub subSF {
  my($n1,$n2)=@_;
  $n2 = _Simplify($n2);
  if ($n2<0) {
    $n2 =~ s/\-//;
  } else {
    $n2 =~ s/^\+?/-/;
  }
  addSF($n1,$n2);
}

sub multSF {
  my($n1,$n2)=@_;
  $n1 = _Simplify($n1);
  $n2 = _Simplify($n2);
  return ()  if (! defined $n1  ||  ! defined $n2);
  return 0   if ($n1==0  or  $n2==0);
  my($m1)=CountSigFigs($n1);
  my($m2)=CountSigFigs($n2);
  my($m)=($m1<$m2 ? $m1 : $m2);
  my($n)=$n1*$n2;
  FormatSigFigs($n,$m);
}

sub divSF {
  my($n1,$n2)=@_;
  $n1 = _Simplify($n1);
  $n2 = _Simplify($n2);
  return ()  if (! defined $n1  ||  ! defined $n2);
  return 0   if ($n1==0);
  return ()  if ($n2==0);
  my($m1)=CountSigFigs($n1);
  my($m2)=CountSigFigs($n2);
  my($m)=($m1<$m2 ? $m1 : $m2);
  my($n)=$n1/$n2;
  FormatSigFigs($n,$m);
}

sub FormatSigFigs {
  my($N,$n)=@_;
  my($ret);
  $N = _Simplify($N);
  return ""  if (! defined($N)  or  $n !~ /^\d+$/  or  $n<1);
  my($l,$l1,$l2,$m,$s)=();
  $N=~ s/\s+//g;               # Remove all spaces
  $N=~ s/^([+-]?)//;           # Remove sign
  $s=(defined $1 ? $1 : "");
  $N=~ s/^0+//;                # Remove all leading zeros
  $N=~ s/0+$//  if ($N=~/\./); # Remove all trailing zeros (when decimal point)
  $N=~ s/\.$//;                # Remove a trailing decimal point
  return "${s}0"  if ($N eq "");
  $N= "0$N"  if ($N=~ /^\./);  # Turn .2 into 0.2

  # If $N has fewer sigfigs than requested, pad it with zeros and return it.
  $m=CountSigFigs($N);
  if ($m==$n) {
    $N="$N."  if (length($N)==$n);
    return "$s$N";
  } elsif ($m<$n) {
    if ($N=~ /\./) {
      return "$s$N" . "0"x($n-$m);
    } else {
      $N=~ /(\d+)$/;
      $l=length($1);
      return "$s$N"  if ($l>$n);
      return "$s$N." . "0"x($n-$l);
    }
  }

  if ($N=~ /^([1-9]\d*)\.([0-9]*)/) {     # 123.4567  (l1=3, l2=4)
    ($l1,$l2)=(length($1),length($2));
    if ($n>=$l1) {                        # keep some decimal points
      $l=$n-$l1;
      ($l2>$l) && ($N=~ s/5$/6/);         # 4.95 rounds down... make it go up
      $ret=sprintf("%.${l}f",$N);
      $m=CountSigFigs($ret);
      if ($m==$n) {
        $ret="$ret."  if ($l==0 && $m==length($ret));
        return "$s$ret";
      }

      # special case 9.99 (2) -> 10.
      #              9.99 (1) -> 10

      $l--;
      if ($l>=0) {
        $ret=sprintf("%.${l}f",$N);
        $ret="$ret."  if ($l==0);
        return "$s$ret";
      }
      return "$s$ret";
    } else {
      my($a)=substr($N,0,$n);             # Turn 1234.56 into 123.456 (n=3)
      $N =~ /^$a(.*)\.(.*)$/;
      my($b,$c)=($1,$2);
      $N="$a.$b$c";
      $N=sprintf("%.0f",$N);              # Turn it to 123
      $N .= "0" x length($b);             # Turn it to 1230
      return "$s$N";
    }

  } elsif ($N=~ /^0\.(0*)(\d*)$/) {       # 0.0123
    ($l1,$l2)=(length($1),length($2));
    ($l2>$n) && ($N=~ s/5$/6/);
    $l=$l1+$n;
    $ret=sprintf("%.${l}f",$N);
    $m=CountSigFigs($ret);
    return "$s$ret"  if ($n==$m);

    # special cases 0.099 (1) -> 0.1
    #               0.99  (1) -> 1.

    $l--;
    $ret=sprintf("%.${l}f",$N);
    $m=CountSigFigs($ret);
    $ret="$ret."  if ($l==0);
    return "$s$ret"  if ($n==$m);
    $ret =~ s/0$//;
    return "$s$ret";
  }

  return 0  if ($N==0);

  if ($N=~ /^(\d+?)(0*)$/) {              # 123
    ($l1,$l2)=(length($1),length($2));
    ($l1>$n) && ($N=~ s/5(0*)$/6$1/);
    $l=$n;
    $m=sprintf("%.${l}f",".$N");          # .123
    if ($m>1) {
      $l--;
      $m=~ s/\.\d/\.0/  if ($l==0);
    } else {
      $m =~ s/^0//;
    }
    $m=~ s/\.//;
    $N=$m . "0"x($l1+$l2-$n);
    $N="$N."  if (length($N)==$n);
    return "$s$N";
  }
  "";

}

sub CountSigFigs {
  my($N)=@_;
  $N = _Simplify($N);
  return ()  if (! defined($N));
  return 0   if ($N==0);

  my($tmp)=();
  if ($N=~ /^\s*[+-]?\s*0*([1-9]\d*)\s*$/) {
    $tmp=$1;
    $tmp=~ s/0*$//;
    return length($tmp);
  } elsif ($N=~ /^\s*[+-]?\s*0*\.0*(\d*)\s*$/) {
    return length($1);
  } elsif ($N=~ /^\s*[+-]?\s*0*([1-9]?\d*\.\d*)\s*$/) {
    return length($1)-1;
  }
  ();
}

########################################################################
# NOT FOR EXPORT
#
# These are exported above only for debug purposes.  They are not
# for general use.  They are not guaranteed to remain backward
# compatible (or even to exist at all) in future versions.
########################################################################

# This returns the power of the least sigificant digit.
sub _LSP {
  my($n) = @_;
  $n =~ s/\-//;
  if ($n =~ /(.*)\.(.+)/) {
    return -length($2);
  } elsif ($n =~ /\.$/) {
    return 0;
  } else {
    return length($n) - CountSigFigs($n);
  }
}

# This prepares a number by converting it to it's simplest correct
# form.
sub _Simplify {
  my($n)    = @_;
  return undef  if (! defined $n);
  return undef  if ($n !~ /^\s*([+-]?)\s*0*(\d+\.?\d*)\s*$/  and
                    $n !~ /^\s*([+-]?)\s*0*(\.\d+)\s*$/);
  $n="$1$2";
  return $n;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:
