#!perl -w


package File::DosGlob;

our $VERSION = '1.12';
use strict;
use warnings;

require XSLoader;
XSLoader::load();

sub doglob {
    my $cond = shift;
    my @retval = ();
    my $fix_drive_relative_paths;
  OUTER:
    for my $pat (@_) {
	my @matched = ();
	my @globdirs = ();
	my $head = '.';
	my $sepchr = '/';
        my $tail;
	next OUTER unless defined $pat and $pat ne '';
	# if arg is within quotes strip em and do no globbing
	if ($pat =~ /^"(.*)"\z/s) {
	    $pat = $1;
	    if ($cond eq 'd') { push(@retval, $pat) if -d $pat }
	    else              { push(@retval, $pat) if -e $pat }
	    next OUTER;
	}
	# wildcards with a drive prefix such as h:*.pm must be changed
	# to h:./*.pm to expand correctly
	if ($pat =~ m|^([A-Za-z]:)[^/\\]|s) {
	    substr($pat,0,2) = $1 . "./";
	    $fix_drive_relative_paths = 1;
	}
	if ($pat =~ m|^(.*)([\\/])([^\\/]*)\z|s) {
	    ($head, $sepchr, $tail) = ($1,$2,$3);
	    push (@retval, $pat), next OUTER if $tail eq '';
	    if ($head =~ /[*?]/) {
		@globdirs = doglob('d', $head);
		push(@retval, doglob($cond, map {"$_$sepchr$tail"} @globdirs)),
		    next OUTER if @globdirs;
	    }
	    $head .= $sepchr if $head eq '' or $head =~ /^[A-Za-z]:\z/s;
	    $pat = $tail;
	}
	#
	# If file component has no wildcards, we can avoid opendir
	unless ($pat =~ /[*?]/) {
	    $head = '' if $head eq '.';
	    $head .= $sepchr unless $head eq '' or substr($head,-1) eq $sepchr;
	    $head .= $pat;
	    if ($cond eq 'd') { push(@retval,$head) if -d $head }
	    else              { push(@retval,$head) if -e $head }
	    next OUTER;
	}
	opendir(D, $head) or next OUTER;
	my @leaves = readdir D;
	closedir D;

	# VMS-format filespecs, especially if they contain extended characters,
	# are unlikely to match patterns correctly, so Unixify them.
	if ($^O eq 'VMS') {
	    require VMS::Filespec;
	    @leaves = map {$_ =~ s/\.$//; VMS::Filespec::unixify($_)} @leaves;
        }
	$head = '' if $head eq '.';
	$head .= $sepchr unless $head eq '' or substr($head,-1) eq $sepchr;

	# escape regex metachars but not glob chars
	$pat =~ s:([].+^\-\${}()[|]):\\$1:g;
	# and convert DOS-style wildcards to regex
	$pat =~ s/\*/.*/g;
	$pat =~ s/\?/.?/g;

	my $matchsub = sub { $_[0] =~ m|^$pat\z|is };
      INNER:
	for my $e (@leaves) {
	    next INNER if $e eq '.' or $e eq '..';
	    next INNER if $cond eq 'd' and ! -d "$head$e";
	    push(@matched, "$head$e"), next INNER if &$matchsub($e);
	    #
	    # [DOS compatibility special case]
	    # Failed, add a trailing dot and try again, but only
	    # if name does not have a dot in it *and* pattern
	    # has a dot *and* name is shorter than 9 chars.
	    #
	    if (index($e,'.') == -1 and length($e) < 9
	        and index($pat,'\\.') != -1) {
		push(@matched, "$head$e"), next INNER if &$matchsub("$e.");
	    }
	}
	push @retval, @matched if @matched;
    }
    if ($fix_drive_relative_paths) {
	s|^([A-Za-z]:)\./|$1| for @retval;
    }
    return @retval;
}


our %entries;

sub glob {
    my($pat,$cxix) = ($_[0], _callsite());
    my @pat;

    # glob without args defaults to $_
    $pat = $_ unless defined $pat;

    # if we're just beginning, do it all first
    if (!$entries{$cxix}) {
      # extract patterns
      if ($pat =~ /\s/) {
	require Text::ParseWords;
	@pat = Text::ParseWords::parse_line('\s+',0,$pat);
      }
      else {
	push @pat, $pat;
      }

      # Mike Mestnik: made to do abc{1,2,3} == abc1 abc2 abc3.
      #   abc3 will be the original {3} (and drop the {}).
      #   abc1 abc2 will be put in @appendpat.
      # This was just the easiest way, not nearly the best.
      REHASH: {
	my @appendpat = ();
	for (@pat) {
	    # There must be a "," I.E. abc{efg} is not what we want.
	    while ( /^(.*)(?<!\\)\{(.*?)(?<!\\)\,.*?(?<!\\)\}(.*)$/ ) {
		my ($start, $match, $end) = ($1, $2, $3);
		#print "Got: \n\t$start\n\t$match\n\t$end\n";
		my $tmp = "$start$match$end";
		while ( $tmp =~ s/^(.*?)(?<!\\)\{(?:.*(?<!\\)\,)?(.*\Q$match\E.*?)(?:(?<!\\)\,.*)?(?<!\\)\}(.*)$/$1$2$3/ ) {
		    #  these expansions will be performed by the original,
		    #  when we call REHASH.
		}
		push @appendpat, ("$tmp");
		s/^\Q$start\E(?<!\\)\{\Q$match\E(?<!\\)\,/$start\{/;
		if ( /^\Q$start\E(?<!\\)\{(?!.*?(?<!\\)\,.*?\Q$end\E$)(.*)(?<!\\)\}\Q$end\E$/ ) {
		    $match = $1;
		    #print "GOT: \n\t$start\n\t$match\n\t$end\n\n";
		    $_ = "$start$match$end";
		}
	    }
	    #print "Sould have "GOT" vs "Got"!\n";
		#FIXME: There should be checking for this.
		#  How or what should be done about failure is beyond me.
	}
	if ( $#appendpat != -1
		) {
	    #FIXME: Max loop, no way! :")
	    for ( @appendpat ) {
	        push @pat, $_;
	    }
	    goto REHASH;
	}
      }
      for ( @pat ) {
	s/\\([{},])/$1/g;
      }
 
      $entries{$cxix} = [doglob(1,@pat)];
    }

    # chuck it all out, quick or slow
    if (wantarray) {
	return @{delete $entries{$cxix}};
    }
    else {
	if (scalar @{$entries{$cxix}}) {
	    return shift @{$entries{$cxix}};
	}
	else {
	    # return undef for EOL
	    delete $entries{$cxix};
	    return undef;
	}
    }
}

{
    no strict 'refs';

    sub import {
    my $pkg = shift;
    return unless @_;
    my $sym = shift;
    my $callpkg = ($sym =~ s/^GLOBAL_//s ? 'CORE::GLOBAL' : caller(0));
    *{$callpkg.'::'.$sym} = \&{$pkg.'::'.$sym} if $sym eq 'glob';
    }
}
1;

__END__


