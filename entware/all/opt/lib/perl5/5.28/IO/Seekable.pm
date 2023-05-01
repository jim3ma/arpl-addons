
package IO::Seekable;


use 5.008_001;
use Carp;
use strict;
use IO::Handle ();
use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
require Exporter;

our @EXPORT = qw(SEEK_SET SEEK_CUR SEEK_END);
our @ISA = qw(Exporter);

our $VERSION = "1.39";

sub seek {
    @_ == 3 or croak 'usage: $io->seek(POS, WHENCE)';
    seek($_[0], $_[1], $_[2]);
}

sub sysseek {
    @_ == 3 or croak 'usage: $io->sysseek(POS, WHENCE)';
    sysseek($_[0], $_[1], $_[2]);
}

sub tell {
    @_ == 1 or croak 'usage: $io->tell()';
    tell($_[0]);
}

1;
