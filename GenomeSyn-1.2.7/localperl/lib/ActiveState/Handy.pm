package ActiveState::Handy;

use strict;

our $VERSION = '1.03';

use base 'Exporter';
our @EXPORT_OK = qw(
    add ceil
    cat cat_text
    file_content
    iso_date iso_datetime
    xml_esc xml_clean
    cp_tree cp_files
    stringf
);

# legacy
use ActiveState::Run qw(run shell_quote decode_status);
push(@EXPORT_OK, qw(run shell_quote decode_status));

sub ceil {
    my $n = shift;
    my $i = int $n;
    return $i if $i == $n or $n < 0;
    return ++$i;
}

sub add {
    my $sum = 0;
    $sum += shift while @_;
    return $sum;
}

sub cat {
    return file_content(shift);
}

sub cat_text {
    my $f = shift;
    open(my $fh, "<", $f) || return undef;
    local $/;
    return scalar <$fh>;
}

sub cp_files {
    require File::Copy;
    require File::Path;

    my($from,$to,@files) = @_;
    File::Path::mkpath($to) unless -d $to;
    foreach my $file (@files) {
	die "$from/$file doesn't exist" unless -f "$from/$file";
	File::Path::mkpath("$to/$1") if $file =~ m|^(.*)/[^/]+$|;
	chmod 0777, "$to/$file";
	File::Copy::copy("$from/$file", "$to/$file")
	    or die "Can't copy '$from/$file' to '$to/$file'";
    }
}

sub cp_tree {
    require File::Copy;
    require File::Path;

    my($from,$to) = @_;
    opendir(my $dir, $from) or die "Can't read directory '$from': $!";
    while (defined(my $file = readdir($dir))) {
	next if $file =~ /^\.\.?$/;
	if (-d "$from/$file") {
	    cp_tree("$from/$file", "$to/$file");
	    next;
	}
	next unless -f "$from/$file";
	File::Path::mkpath($to) unless -d $to;
	chmod 0777, "$to/$file";
	File::Copy::copy("$from/$file", "$to/$file")
	    or die "Can't copy '$from/$file' to '$to/$file'";
    }
}

sub file_content {
    my $name = shift;
    if (@_) {
	# write
	my $f;
	unless (open($f, ">", $name)) {
	    my $err = $!;
	    if (!-e $name) {
		# does it help to create the directory first
		require File::Basename;
		require File::Path;
		my $dirname = File::Basename::dirname($name);
		if (File::Path::mkpath($dirname)) {
		    # retry
		    undef($err);
		    unless (open($f, ">", $name)) {
			$err = $!;
		    }
		}
	    }
	    die "Can't create '$name': $err" if $err;
	}
	binmode($f);
	print $f $_[0];
	close($f) || die "Can't write to '$name': $!";
	return;
    }

    # read
    open(my $f, "<", $name) || return undef;
    binmode($f);
    local $/;
    return scalar <$f>;
}

sub iso_date {
    my($y, $m, $d) = @_;
    if (@_ == 1) {
	($y, $m, $d) = (localtime $y)[5, 4, 3];
	$y += 1900;
	$m++;
    }
    return sprintf "%04d-%02d-%02d", $y, $m, $d;
}

sub iso_datetime {
    my($Y, $M, $D, $h, $m, $s) = @_;
    if (@_ == 1) {
	($Y, $M, $D, $h, $m, $s) = (localtime $Y)[5, 4, 3, 2, 1, 0];
	$Y += 1900;
	$M++;
    }
    return sprintf "%04d-%02d-%02dT%02d:%02d:%02d", $Y, $M, $D, $h, $m, $s;
}

sub xml_esc {
    local $_ = shift;
    tr[\000-\010\013-\037][]d;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/]]>/]]&gt;/g;
    s/([^\n\040-\176])/sprintf("&#x%x;", ord($1))/ge;
    return $_;
}

sub xml_clean {
    local $_ = shift;
    tr[\000-\010\013-\037][]d;
    return $_;
}

sub stringf {
    local $_ = shift;
    my %p = ("%" => "%", "n" => "\n", "t" => "\t", @_);
    s/(%(-?)(\d*)(?:\.(\d*))?(?:{(.*?)})?(\S))/_fmt(\%p, $1, $2, $3, $4, $5, $6)/ge;
    return $_;
}

sub _fmt {
    my($p, $orig, $left, $min, $max, $arg, $c) = @_;
    return $orig unless exists $p->{$c};
    my $v = $p->{$c};
    $v = $v->($arg) if ref($v) eq "CODE";
    return substr($v, 0, $max) if $max && $max < length $v;
    $min ||= 0;
    $min -= length $v;
    if ($min > 0) {
        my $pad = " " x $min;
        $v = $left ? "$v$pad" : "$pad$v";
    }
    return $v;
}

1;

=head1 NAME

ActiveState::Handy - Collection of small utility functions

=head1 SYNOPSIS

 use ActiveState::Handy qw(add);
 my $sum = add(1, 2, 3);

=head1 DESCRIPTION

This module provides a collection of small utility functions.

The following functions are provided:

=over 4

=item add( @numbers )

Adds the given arguments together.

=item cat( $filename )

Returns the content of a file.  Same as file_content( $filename ).
This function is still present for legacy reasons.

=item cat_text( $filename )

Just like cat() but will read the file in text mode.  Makes a
difference on some platforms (like Windows).

=item ceil( $number )

Rounds the number up to the nearest integer.  Same as POSIX::ceil().

=item cp_files( $from, $to, @files )

Copies files from source to destination directory. Destination directory
will be created if it doesn't exist.  Function dies if any file cannot
be found.

=item cp_tree( $from, $to )

Recursively copies all files and subdirectories from source to destination
directory. All destination directories will be created if they don't
already exist.

=item file_content( $filename )

=item file_content( $filename, $content )

Get or set the content of a file.  The file I/O takes place in binary
mode.

If called with a single argument, then try to read the given file and
return C<undef> if the file could not be opened.

If called with two arguments, try to write the given $content to the
file denoted by the given $filename, creating the file itself or
missing directories as needed.  If the file can't be opened or created
this function will croak.  There is no return value when the file is
set.

=item iso_date( $time )

=item iso_date( $y, $m, $d )

Returns a ISO 8601 formatted date; YYYY-MM-DD format.  See
C<http://www.cl.cam.ac.uk/~mgk25/iso-time.html>.

=item iso_datetime( $time )

=item iso_datetime( $y, $m, $d, $h, $m, $s )

Returns a ISO 8601 formatted timestamp; YYYY-MM-DDThh:mm:ss format.  See
C<http://www.cl.cam.ac.uk/~mgk25/iso-time.html>.

=item xml_esc( $text )

Will escape a piece of text so it can be embedded as text in an XML
element.

=item xml_clean( $text )

Will remove control characters so it can be embedded as text in an XML
element. Does not perform escaping.

=item stringf( $format, %hash )

printf-style template expansion compatible with the L<String::Format> module.

=back

For legacy reasons this module re-exports the functions run(),
shell_quote() and decode_status() from C<ActiveState::Run>.

=head1 BUGS

none.

=head1 SEE ALSO

L<ActiveState::Run>

=cut
