
package List::Util;

use strict;
use warnings;
require Exporter;

our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw(
  all any first min max minstr maxstr none notall product reduce sum sum0 shuffle uniq uniqnum uniqstr
  head tail pairs unpairs pairkeys pairvalues pairmap pairgrep pairfirst
);
our $VERSION    = "1.50";
our $XS_VERSION = $VERSION;
$VERSION    = eval $VERSION;

require XSLoader;
XSLoader::load('List::Util', $XS_VERSION);

sub import
{
  my $pkg = caller;

  # (RT88848) Touch the caller's $a and $b, to avoid the warning of
  #   Name "main::a" used only once: possible typo" warning
  no strict 'refs';
  ${"${pkg}::a"} = ${"${pkg}::a"};
  ${"${pkg}::b"} = ${"${pkg}::b"};

  goto &Exporter::import;
}

sub List::Util::_Pair::key   { shift->[0] }
sub List::Util::_Pair::value { shift->[1] }









1;
