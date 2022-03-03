package ActiveState::Unix::Network;
use strict;
use warnings;
use ActiveState::Run qw(decode_status);
use base 'Exporter';
our @EXPORT_OK = qw(interfaces mask_off num2ip);

sub interfaces {
    my @interfaces;
    for my $path ("/sbin", "/usr/sbin", split(/:/, $ENV{PATH})) {
	my $ifconfig = "$path/ifconfig";
	next unless -x $ifconfig;
	if ( $^O eq "hpux" ) {
	    $ifconfig = "netstat -in |  tail -n +2 | cut -f 1 -d \" \" | xargs -l $ifconfig";
	}
	else {
	    $ifconfig .= " -a";
	}
	my $out = `$ifconfig`;
        if ($?) {
            my $err = decode_status;
            die "Error running '$ifconfig': $err\n";
        }

	my %mask_done;
	while ($out =~ /inet(?: addr)?:?\s*(\d+(?:\.\d+){3}).*(?:net)?mask:?\s*(\S+)/gci)
	{
	    my($ip, $mask) = ($1, $2);
	    next if $ip =~ /^127\./;
	    $mask = num2ip(hex($1)) if $mask =~ /^(?:0x)?([fF]{2}[a-fA-F0-9]+)$/;
	    next unless $mask =~ /^\d+(?:\.\d+){3}$/;
	    my $subnet = mask_off($ip, $mask);

            my $network_bits = 0;
            foreach (split /\./, $mask) {
                my $binmask = dec2bin($_);
                $network_bits += $binmask =~ tr/1//;
            }

            push @interfaces, { ip => $ip,
                                netmask => $mask,
                                subnet => $subnet,
                                network_bits => $network_bits,
                              };
        }
        last;
    }
    return @interfaces;
}

sub mask_off {
    my($addr, $mask) = @_;
    for ($addr, $mask) {
	$_ = unpack("N", pack("C*", split(/\./, $_)));
    }
    $addr &= $mask;
    return num2ip($addr);
}

sub num2ip {
    return join(".", unpack("C*", pack("N", $_[0])));
}

sub dec2bin {
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
}

1;

=head1 NAME

ActiveState::Unix::Network - Portable way to determine host networking info

=head1 SYNOPSIS

 use ActiveState::Unix::Network qw(interfaces);
 my $interfaces = interfaces;
 foreach my $i (@$interfaces) {
     foreach (qw(ip netmask subnet)) {
         print "ip = $i->{$_}\n";
     }
     print "\n";
 }

=head1 DESCRIPTION

This module provides a single function called interfaces() that will run ifconfig
(and lanscan on HPUX) to examine the external network interfaces.  It will parse 
the networking info and return an array of external interfaces.

=over 4

=item interfaces()

This function will return an arrayref containing a hashref for each of the 
interfaces discovered.  Each hashref will contain the following keys:

=over 4

=item ip

=item netmask

=item subnet

=item network_bits

Number of network bits in IP address (used for CIDR blocks).

=back 

=item mask_off( $ip, $mask )

Computes the subnet from an IP and netmask.

=item num2ip( $ip )

Converts an IP address from numeric to string form.

=back

=head1 NOTES

These functions currently only support IPv4 addresses.

=head1 COPYRIGHT

Copyright (C) 2005 ActiveState Software Inc.  All rights reserved.
