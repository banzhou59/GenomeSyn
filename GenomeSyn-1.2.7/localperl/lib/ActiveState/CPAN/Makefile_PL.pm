package ActiveState::CPAN::Makefile_PL;

use strict;

use base 'Exporter';
our @EXPORT_OK = qw(parse_makefile_pl);

use ActiveState::Handy qw(file_content);
use Text::Balanced qw(extract_bracketed extract_quotelike);

sub parse_makefile_pl {
    my $f = shift;
    #print "*** $f ***\n";
    local $_ = file_content($f);
    return undef unless defined($_);
    if (/^([ \t]*)(?:ExtUtils::MakeMaker::)?WriteMakefile\s*\(\s*$([^\0]*?)^\1\)/m) {
        $_ = $2;
        s/^\s*(#.*)?\n//gm;
        return parse_hash($_);
    }
    return {};
}

sub parse_hash {
    local $_ = shift;

    s/^\s*{// && s/}\s*\z//;

    my %hash;
    while (s/^\s*('|"|)([a-zA-Z][\w:]*)\1\s*=>\s*//) {
        my $k = $2;
        my $v;
        #print "X [$2]\n";
        if (/^['"]/) {
            ($v, $_) = extract_quotelike($_);
            last unless defined $v;
            $v = unquote($v);
        }
        elsif (/^[{\[]/) {
            ($v, $_) = extract_bracketed($_, "{[");
            last unless defined $v;
            $v = parse_hash($v) if $v =~ /^{/;
        }
        elsif (s/^(\d+(?:\.\d*)?)//) {
            $v = $1;
        }
        else {
            #warn "Warning: Giving up on hash value [$_]";
            last;  # give up
        }
        $hash{$k} = $v;
        s/^\s*,\s*(?:#.*)?//;
    }
    #print "REMAINING=[$_]\n" if /\S/;
    return \%hash;
}

sub unquote {
    my $v = shift;
    $v = substr($v, 1, -1);
    return $v;
}

1;
