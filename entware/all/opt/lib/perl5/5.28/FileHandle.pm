package FileHandle;

use 5.006;
use strict;
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);

$VERSION = "2.03";

require IO::File;
@ISA = qw(IO::File);

@EXPORT = qw(_IOFBF _IOLBF _IONBF);

@EXPORT_OK = qw(
    pipe

    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed

    print
    printf
    getline
    getlines
);

IO::Handle->import( grep { !defined(&$_) } @EXPORT, @EXPORT_OK );

{
    no strict 'refs';

    my %import = (
	'IO::Handle' =>
	    [qw(DESTROY new_from_fd fdopen close fileno getc ungetc gets
		eof flush error clearerr setbuf setvbuf _open_mode_string)],
	'IO::Seekable' =>
	    [qw(seek tell getpos setpos)],
	'IO::File' =>
	    [qw(new new_tmpfile open)]
    );
    for my $pkg (keys %import) {
	for my $func (@{$import{$pkg}}) {
	    my $c = *{"${pkg}::$func"}{CODE}
		or die "${pkg}::$func missing";
	    *$func = $c;
	}
    }
}

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    require Exporter;
    Exporter::export($pkg, $callpkg, @_);

    #
    # If the Fcntl extension is available,
    #  export its constants.
    #
    eval {
	require Fcntl;
	Exporter::export('Fcntl', $callpkg);
    };
}


sub pipe {
    my $r = IO::Handle->new;
    my $w = IO::Handle->new;
    CORE::pipe($r, $w) or return undef;
    ($r, $w);
}

bless *STDIN{IO},  "FileHandle" if ref *STDIN{IO}  eq "IO::Handle";
bless *STDOUT{IO}, "FileHandle" if ref *STDOUT{IO} eq "IO::Handle";
bless *STDERR{IO}, "FileHandle" if ref *STDERR{IO} eq "IO::Handle";

1;

__END__

