package SQL::Dialects::Role;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT  = qw(get_config_as_hash);
our $VERSION = '1.402';

sub get_config_as_hash
{
    my $class = $_[0];

    my @data = split( m/\n/, $class->get_config() );

    my %config;
    my $feature;
    for (@data)
    {
        chomp;
        s/^\s+//;
        s/\s+$//;
        next unless ($_);
        if (/^\[(.*)\]$/i)
        {
            $feature = lc $1;
            $feature =~ s/\s+/_/g;
            next;
        }
        my $newopt = uc $_;
        $newopt =~ s/\s+/ /g;
        $config{$feature}{$newopt} = 1;
    }

    return \%config;
}

=head1 NAME

SQL::Dialects::Role - The role of being a SQL::Dialect

=head1 SYNOPSIS

    package My::SQL::Dialect;

    use SQL::Dialects::Role;

    sub get_config {
        return <<CONFIG;
    [SECTION]
    item1
    item2

    [ANOTHER SECTION]
    item1
    item2
    CONFIG
    }

=head1 DESCRIPTION

This adds the role of being a SQL::Dialect to your class.

=head2 Requirements

You must implement...

=head3 get_config

    my $config = $class->get_config;

Returns information about the dialect in an INI-like format.

=head2 Implements

The role implements...

=head3 get_config_as_hash

    my $config = $class->get_config_as_hash;

Returns the data represented in get_config() as a hash ref.

Items will be upper-cased, sections will be lower-cased.

The example in the SYNOPSIS would come back as...

    {
        section => {
            ITEM1       => 1,
            ITEM2       => 2,
        },
        another_section => {
            ITEM1       => 1,
            ITEM2       => 2,
        }
   }

=head1 SEE ALSO

L<SQL::Parser/dialect()>

=cut
