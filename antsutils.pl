#!/usr/bin/perl
#======================================================================
#                    A N T S U T I L S . P L 
#                    doc: Fri Jun 19 23:25:50 1998
#                    dlm: Fri Jun 12 07:31:08 2015
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 103 66 NIL 0 0 70 10 2 4 NIL ofnI
#======================================================================

# Miscellaneous auxillary functions

# HISTORY:
#	Mar 08, 1999: - added &antsFunUsage()
#	Mar 20, 1999: - added &fnr()
#				  - BUG &numberp() returned TRUE on "sigma2"
#	Mar 21, 1999: - added semantics of &antsFunUsage() to specify min
#					args on negative number
#	Mar 22, 1999: - added round(); NB: there's a BUG:
#					int(2.155*10**2+0.5)/100 returns 215!!!
#	Jul 31, 1999: - added &cardinalp() and plugged into &fnr()
#				  - change &numberp() to conform with &antsFloatArg()
#	Sep 13, 1999: - added &SQR()
#				  - removed "" from valid numbers
#	Sep 18, 1999: - added &integerp()
#				  - added typechecking to &antsFunUsage()
#	Sep 20, 1999: - cosmetics
#	Aug 24, 2000: - added #include directive to Description files
#				  - added stringlengths to &antsFunUsage()
#	Aug 28, 2000: - added str2num to remove leading 0es & lead/trail spcs
#				  - changed opt_P to opt_A
#	Aug 29, 2000: - added &antsRequireParam()
#	Sep 01, 2000: - added prefix as 2nd arg to #include directive
#				  - disallow <> in #include directive
#				  - debugged &str2num()
#	Sep 03, 2000: - allowed for %param to pass through fnr w/o error check
#	Sep 05, 2000: - str2num always kills leading/trailing spaces
#	Sep 19, 2000: - added interpretation to ./ to #include
#				  - inherit prefix for chained inclusion (do not chain, however)
#	Nov 25, 2000: - backslashed leading + in regexp to increase portability
#	May 29, 2001: - adapted &antsNumbers() to handle %PARAMs
#				  - added &antsVal()
#	Jul  6, 2001: - added degree notation to str2num()
#	Jul 12, 2001: - made $# notation 1-relative (awk, shell)
#	Jul 15, 2001: - added field name to Description open error
#	Jul 16, 2001: - added &localFnr()
#	Jul 19, 2001: - added &croak()
#	Aug  1, 2001: - BUG: numberp() returned false on "-.360"
#	May  7, 2002: - BUG: numberp() returned true on "."
#	Mar  8, 2003: - changed Description to Layout
#   Dec  7, 2005: - antsFName -> antsLayout (not tested)
#	Dec  8, 2005: - Version 3.2 (see [HISTORY])
#	Dec 12, 2005: - BUG: &outFnr() was broken
#				  - BUG: [Layout] overrode local #FIELDS#
#   Dec 23, 2005: - replaced defined(@array) (c.f. perlfunc(1))
#	Jan  2, 2006: - changed numberp to allow for multiple args
#				  - changed right back
#	Jan  9, 2006: - BUG: fnrNoErr() had not increased $antsBufNFields on
#					     import of an externally defined field
#	Jan 10, 2006: - added &antsLoadModel()
#	Jan 12, 2006: - removed -A support
#	Jan 13: 2006: - BUG: str2num(3.00) did not yield 3
#	Jul  1, 2006: - added isNaN (from perlfunc(1))
#				  - changed numberp() according to perldata(1)
#	Jul 24, 2006: - added $PRACTICALLY_ZERO, &equal()
#	Aug 23, 2006: - improved model loading (& added model w. params)
#	Aug 24, 2006: - made 2nd argument of round() optional
#				  - added frac()
#	May 11, 2007: - added Floor(), Ceil()
#	Oct 17, 2007: - added default field names (w. caching) to &antsFunUsage()
#	Oct 18, 2007: - added support for optional parameters
#	Oct 19, 2007: - generalized antsFunUsage to allow default %PARAMs
#				  - BUG: make sure usage is printed in abc when called with
#						 wrong # of args
#	Nov 14, 2007: - made optional arguments to round, Floor, Ceil more intuitive
#	Dec 19, 2007: - added &numbersp()
#	Mar  2, 2008: - adapted fnr to partial matches
#	Mar  4, 2008: - added $antsFnrExactMatch flag
#				  - BUG: couldn't select f1 if there is also an f10
#	Mar 26, 2008: - BUG: abbreviated field names were imported from external
#						 Layout
#	Mar 27, 2008: - added %pi
#	Mar 28, 2008: - move %pi to [argtest]; when set here filediff -e bombs
#	Apr 15, 2008: - added &log10()
#	Apr 16, 2008: - MAJOR CHANGE: suppress croak() STDOUT error output on -Q
#	Apr 29, 2008: - added &ismember()
#	Jun 11, 2008: - adder perl 5.8.8 bug workaround (0*-0.1 = -0)
#	Nov 12, 2008: - added opt_T
#	Mar 21, 2009: - added debug()
#	Nov 17, 2009: - added listAllRecs flag for list(1)
#	May 12, 2010: - BUG: round() did not work correctly for -ve numbers
#	May 21, 2011: - added support for $antsFnrNegativeOk
#	Nov 11, 2011: - added exact flag to fnrNoErr()
#	Feb 13, 2012: - BUG: failure to specify exact flag resulted in ignoring antsFnrExactMatch
#				  - BUG: fnrNoErr disregarded exact flag for external layouts
#	May 16, 2012: - adapted to V5.0
#	May 31, 2012: - changed ismember() semantics for use in psSamp
#	Jun 12, 2012: - added &compactList()
#	Dec 17, 2012: - added default to antsLoadModel()
#	Sep  5, 2013: - FINALLY: added $pi
#	May 23, 2014: - made ismember understand "123,1-10"
#	Jul 22, 2014: - removed support for antsFnrNegativeOk
#	May 18, 2015: - added antsFindParam()
#	Jun 21, 2015: - added antsParam(), modified antsRequireParam()

# fnr notes:
#	- matches field names starting with the string given, i.e. "sig" is
#     really "^sig"
#	- if exact match is desired, a $ can be appended to the field name
#	- following regexp meta chars are auto-quoted: .

#----------------------------------------------------------------------
# Flags
#----------------------------------------------------------------------

$antsFnrExactMatch = 0;				# set to force exact match, e.g. for antsNewField* [antsutils.pl]

#----------------------------------------------------------------------
# Error-Exit
#----------------------------------------------------------------------

sub croak($)
{
	print("#ANTS#ERROR# @_[0]") unless (-t 1 || $opt_Q);
	die(@_[0]);
}

#----------------------------------------------------------------------
# Number-related funs
#----------------------------------------------------------------------

$pi = 3.14159265358979;		# from $PI in [libvec.pl]

$PRACTICALLY_ZERO = 1e-9;
$SMALL_AMOUNT	  = 1e-6;

sub numberp(@)
{ return  $_[0] =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/; }

sub numbersp(@)
{
	foreach my $n (@_) {
		return undef unless numberp($n);
	}
	return 1;
}

sub equal($$)
{ return (@_ >= 2) && (abs($_[0]-$_[1]) < $PRACTICALLY_ZERO); }

#----------------------------------------------------------------------
# check whether given val is member of a set
#	- set can either be an array or a comma-separated string
#----------------------------------------------------------------------

sub ismember($@)
{
	my($val,@set) = @_;
	@set = split(',',$set[0])
		if (@set == 1 && !numberp($set[0]));
	for (my($i)=0; $i<@set; $i++) {
		if (numberp($val) && numberp($set[$i])) {
			return 1 if ($val == $set[$i]);
		} elsif (numberp($val) && ($set[$i] =~ m{-}) && numberp($`) && numberp($')) {
			return 1 if (ismember($val,$`..$'));
		} else {
			return 1 if ($val eq $set[$i]);
		}
	}
	return undef;
}

sub isnan($) # perlfunc(1)
{ return $_[0] != $_[0]; }

sub cardinalp($)
{ return $_[0] =~ /^\+?\d+$/; }

sub integerp($)
{ return $_[0] =~ /^[+-]?\d+$/; }

sub antsNumbers(@)
{
	my($n);
	foreach $n (@_) {
		return 0 unless (&numberp(&antsVal($n)));
	}
	return 1;
}

sub round(@)
{
	my($accuracy) = defined($_[1]) ? $_[1] : 1;
	return $_[0] >= 0 ? int($_[0] / $accuracy + 0.5) * $accuracy
					  : int($_[0] / $accuracy - 0.5) * $accuracy;
}

sub Ceil(@)
{
	my($accuracy) = defined($_[1]) ? $_[1] : 1;
	return int($_[0]/$accuracy + 1 - $PRACTICALLY_ZERO) * $accuracy;
}

sub Floor(@)
{
	my($accuracy) = defined($_[1]) ? $_[1] : 1;
	return int($_[0]/$accuracy) * $accuracy;
}

sub frac($) { return $_[0] - int($_[0]); }

sub SQR($) { return $_[0] * $_[0]; }

sub str2num($)
{
	my($num) = @_;
	$num =~ s/^\s*//;					# kill leading spaces
	$num =~ s/\s*$//;					# kill trailing spaces
	$num = (substr($1,0,1) eq '-') ? $1-$2/60 : $1+$2/60	# degrees
		if ($num =~ /^([+-]?\d*):(\d*\.?\d*)$/);
	return $num unless (numberp($num));
	$num =~ s/^(-?)0*/\1/;				# kill leading 0es
	$num =~ s/(\.\d*[1-9])0*$/\1/;		# kill trailing fractional 0es
	$num =~ s/^\./0./;					# ensure digit before decimal pnt
	$num =~ s/^-\./-0./;				# ditto
	$num =~ s/\.$/.0/;					# ensure digit after decimal pnt
	$num =~ s/^-0(\.0?)$/0/;			# 0 is positive
	$num =~ s/\.0+$//;					# kill trailing fractional 0es
	return ($num eq "") ? 0 : $num;
}

sub fmtNum($$)							# format number for output
{
	my($num,$fname) = @_;
	
	$num = 0 if ($num eq '-0');			# perl 5.8.8: 0*-0.1 = -0, which is 
										# not handled correctly by all progs
	$num = str2num($num) if ($opt_C);
	if ($opt_G && numberp($num)) {
		$num = sprintf("%d:%04.1f%s",
						abs(int($num)),
						(abs($num)-abs(int($num)))*60,
						$num>=0 ? "N" : "S")
			if (lc($fname) =~ /lat/);
		$num = sprintf("%d:%04.1f%s",
						abs(int($num)),
						(abs($num)-abs(int($num)))*60,
						$num>=0 ? "E" : "W")
			if (lc($fname) =~ /lon/);
	}
	if ($opt_T && numberp($num)) {
		$num = sprintf("\\lat%s{%d}{%04.1f}",
						$num>=0 ? "N" : "S",
						abs(int($num)),
						(abs($num)-abs(int($num)))*60)
			if (lc($fname) =~ /lat/);
		$num = sprintf("\\lon%s{%d}{%04.1f}",
						$num>=0 ? "E" : "W",
						abs(int($num)),
						(abs($num)-abs(int($num)))*60)
			if (lc($fname) =~ /lon/);
	}
	$num = sprintf($opt_M,$num)
        if defined($opt_M) && numberp($num);

    return $num;
}

sub log10 { my $n = shift; return ($n>0) ? log($n)/log(10) : nan; }	# c.v. perlfunc(1)


#----------------------------------------------------------------------
# Layout-related funs
#----------------------------------------------------------------------

sub fname_match($$)									# modified regexp match
{
	my($pat,$trg) = @_;
	return ($pat eq $trg) if ($antsFnrExactMatch);	# exact match (pre 3.4 behavior)
#	print(STDERR "pattern: $pat -> ");
	$pat =~ s/\./\\\./g;							# may want more of these
	$pat =~ s/^/\^/;
#	print(STDERR "$pat\n");
	return $trg =~ /$pat/;
}

sub fnrInFile(...)
{
	my($fname,$file,$pref,$found) = @_;
	my($fullName);
	local(*D);
	open(D,$file) || return (undef,$fname);
	while (<D>) {
		s/\s\b/ $pref/g	if m/^#\d+/;
		my(@fn) = split;
		if (/^#\s*include\s*([^\s]+)\s*([^\s]+)?/) {
			my($npref) = ($2 eq "") ? $pref : $2;
			if (substr($1,0,2) eq "./") {
				my($dirname) = $file;
				$file = $1;
				$dirname =~ s@[^/]+$@@;
				$file = $dirname . $file;
			} else {
				$file = $1;
			}
			($found,$fullName) = &fnrInFile($fname,$file,$npref,$found);
		}
		next unless ($fn[0] =~ /^#\d+$/);
		for (my($i)=1; $i<=$#fn; $i++) {
			close(D),return ($1,$fname)
				if (/^#(\d+)\b.*\b$fname\b/);
		}
		for (my($i)=1; $i<=$#fn; $i++) {
			next unless fname_match($fname,$fn[$i]);
			croak("$0: $fname matches multiple fields in Layout files\n")
				if defined($found);
			$fullName = $fn[$i];
			($found) = ($fn[0] =~ /^#(\d+)/);
		}
    }
    close(D);
	return ($found,$fullName);
}

sub localFnr($@)
{
	my($fnm,@layout) = @_;
	my($i,$fnr);

#	print(STDERR "finding $fnm...\n");
	croak("$0: illegal 0-length field name\n")
		if ($fnm eq "");
	return $fnm if ($fnm =~ /^%/);
	if ($fnm =~ /^\$/) {
		croak("$0: invalid field identifier \$$'\n")
			unless (cardinalp($'));
		return $' - 1;
	}
	my($i,$found);
	if (@layout) {
		for ($i=0; $i<=$#layout; $i++) {
			return $i if ($layout[$i] eq $fnm);
	    }
		for ($i=0; $i<=$#layout; $i++) {
			next unless fname_match($fnm,$layout[$i]);
			croak("$0: $fnm matches multiple fields ($layout[$found],$layout[$i],...)\n")
				if defined($found);
			$found = $i;
	    }
	} else {
		for ($i=0; $i<=$#antsLayout; $i++) {
			return $i if ($antsLayout[$i] eq $fnm);
	    }
		for ($i=0; $i<=$#antsLayout; $i++) {
			next unless fname_match($fnm,$antsLayout[$i]);
			croak("$0: $fnm matches multiple fields ($antsLayout[$found],$antsLayout[$i],...)\n")
				if defined($found);
			$found = $i;
	    }
	}
	return $found;
}

sub fnrNoErr($)
{
	my($fnm,$exact) = @_;

	my($tmp) = $antsFnrExactMatch;
	$antsFnrExactMatch = $exact if defined($exact);
	my($fnr) = &localFnr($fnm);
	$antsFnrExactMatch = $tmp;
	
	my($fullName);

	return $fnr if defined($fnr); 						# internal layout

	my($tmp) = $antsFnrExactMatch;
	$antsFnrExactMatch = $exact if defined($exact);
	($fnr,$fullName) = &fnrInFile($fnm,"Layout","");	# external [Layout]
	$antsFnrExactMatch = $tmp;
	
    return undef unless defined($fnr);
    return undef										# [Layout] cannod override
		if (defined($antsLayout[$fnr]) &&				# local definition
			!fname_match($fnm,$antsLayout[$fnr]));

	$antsLayout[$fnr] = $fullName if defined($fullName);# found -> add to local
	$antsBufNFields = $fnr+1							# can happen on externally
		if ($antsBufNFields < $fnr+1);					# ... defined fields
	return($fnr);
}

sub fnr(@)
{
	my(@fnm) = @_;
	my($f,@fnr);
	for ($f=0; $f<=$#fnm; $f++) {
		$fnr[$f] = &fnrNoErr($fnm[$f]);
		next if defined($fnr[$f]);						# normal case -> done
	    croak("$0: Unknown field $fnm[$f]\n")
	    	unless defined($fnr[$f]);
    }
	return(@fnr>1 ? @fnr : $fnr[0]);
}

# fnr()-equivalent but checks in output format
#	- only used for -F processing => single argument only

sub outFnr($)
{
	my($fnm) = @_;
	my($f,$fnr,$fullName);

	$fnr = &localFnr($fnm,@antsNewLayout);
	return $fnr if defined($fnr); 					# normal case -> done
    
	($fnr,$fullName)  = &fnrInFile($fnm,"Layout","");	# look in [Layout]
	croak("$0: Unknown field $fnm\n")
		unless defined($fnr);
		
	$antsNewLayout[$fnr] = $fullName;
	return $fnr;
}

#----------------------------------------------------------------------
# model-loading funs
#----------------------------------------------------------------------

sub antsLoadModel(...)
{
	my($opt,$pref,$default) = @_;
	my($name);
	
	for ($a=0;											# find model name
		 $a<=$#ARGV && !($ARGV[$a] =~ m/^-\S*$opt$/);
		 $a++) { }
	$name = ($a < $#ARGV) ? $ARGV[$a+1] : $default;		# use default if not found

	return undef unless defined($name);

	if (-r "$pref.$name") { 							# load in local directory
		&antsInfo("loading local $pref.$name...");
		require "$pref.$name";
		return $name;
	} else {											# load from ANTSlib 
		my($path) = ($0 =~ m{^(.*)/[^/]*$});
		require "$path/$pref.$name";
		return $name;
    }
}

sub antsLoadModelWithArgs($$)
{
	my($opt,$pref) = @_;
	
	for ($a=0;											# find model name
		 $a<=$#ARGV && !($ARGV[$a] =~ m/^-\S*$opt$/);
		 $a++) { }
	if ($a < $#ARGV) {									# found
		my($name,$args) = ($ARGV[$a+1] =~ /([^\(]+)\(([^\)]*)\)$/);
		$name = $ARGV[$a+1] unless defined($name);
		if (-r "$pref.$name") {							# local
			&antsInfo("loading local $pref.$name...");
			require "$pref.$name";
			return ($name,split(',',$args));
		} else {
			my($path) = ($0 =~ m{^(.*)/[^/]*$});
			require "$path/$pref.$name";
			return ($name,split(',',$args));
		}
	}
	return undef;
}

#----------------------------------------------------------------------
# deal with lists of numbers
#----------------------------------------------------------------------

sub compactList(@)
{
	my(@out);
	my($seqStart);
	my($lv) = -9e99;

	foreach my $v (@_) {
		if (numberp($v)) {
			if ($v == $lv+1) {						# we're in a sequence
				$seqStart = $lv						# record beginning value
					unless defined($seqStart);
			} elsif (defined($seqStart)) {			# we've just completed a sequence
				pop(@out);
				push(@out,"$seqStart-$lv");
				push(@out,$v);
				undef($seqStart);
			} else {								# not in a sequence
				push(@out,$v);
			}
			$lv = $v;
		} else {
			push(@out,$v);
			$lv = -9e99;
		}
	}
	if (defined($seqStart)) {						# list ends with a sequence
		pop(@out);
		push(@out,"$seqStart-$lv");					
	}
	
	return @out;
}

#----------------------------------------------------------------------
# Misc funs
#----------------------------------------------------------------------

# return either current field value or PARAM
sub antsVal($)
{ return ($_[0] =~ /^%/) ? $P{$'} : $ants_[$ants_][$_[0]]; }

# USAGE:
# 	OLD: argc, type-string, errmesg, params to parse
# 	NEW: adds between errmesg & params:
#		1) reference to static array for caching fnrs
#		2) list (argc elts) of field names

# NOTES:
#	- backward compatible
#	- fnr_caching only works with fixed-argc funs
#	- undef field names denote required arguments that must be
#	  supplied by the user, e.g. for dn2date

sub antsFunUsage($$$@)
{
	my($argc,$types,$msg,@params) = @_;

	if (ref($params[0]) && @antsLayout>0 && @params<2*$argc+1) {  # default params
		my(@newparams);									# 2nd test is for abc
		my($npi) = $argc+1;

		$listAllRecs = 1;								# special flag for list(1)

		if (@{$params[0]} > 0) {						# fnrs already in cache
			for (my($i)=0; $i<@{$params[0]}; $i++) {
				push(@newparams,defined($params[0]->[$i]) ?
							    &antsVal($params[0]->[$i]) :
								$params[$npi++]);
			}
			return(@newparams);
		}
	    
		for (my($i)=1; $i<=$argc; $i++) {				# fill cache & do tests
			if (defined($params[$i])) {
				push(@{$params[0]},&fnr($params[$i]));
				push(@newparams,&antsVal($params[0]->[$#{$params[0]}]));
			} else {
				croak("usage: $msg\n") unless ($npi <= $#params);
				push(@{$params[0]},undef);
				push(@newparams,$params[$npi++]);
			}
		}
		croak("usage: $msg\n") unless ($npi > $#params);
		
		@params = @newparams;
	} elsif (ref($params[0])) {
		splice(@params,0,$argc+1);
	}

	if ($argc >= 0) {									# argument count
		croak("usage: $msg\n") unless (@params == $argc);
	} else {
		croak("usage: $msg\n") unless (@params >= -$argc);
	}
    
	for (my($i)=0; $i<length($types); $i++) {			# type checking
		$_ = substr($types,$i,1);
		SWITCH: {
			last unless defined($params[$i]);
			&antsNoCardErr("",$params[$i]),last SWITCH if (/c/);
			&antsNoIntErr("",$params[$i]),last SWITCH if (/i/);
			&antsNoFloatErr("",$params[$i]),last SWITCH if (/f/);
			&antsNoFileErr("",$params[$i]),last SWITCH if (/F/);
			if (/\d/) {
				croak("$0: $params[$i] is not a string of length $_\n")
					unless ($_ == length($params[$i]));
				last SWITCH;
			}
			last SWITCH if (/\./);
			croak("&antsFunUsage: illegal type specifier $_\n");
		}
	}
    
	return @params;
} # sub antsfunusage()

#----------------------------------------------------------------------

sub antsRequireParam($)
{
	my($pn) = @_;
	my($pv) = antsParam($pn);
	croak("$0: required PARAM $pn not set\n")
		unless defined($pv);
	return $pv;
}


sub antsFindParam($)								# find parameter using RE (e.g. antsFindParam('dn\d\d'))
{
	my($re) = @_;
	foreach my $k (keys(%P)) {
		return ($k,$P{$k}) if ($k =~ /^$re$/);
	}
	return (undef,undef);
}

sub antsParam($)									# get parameter value for any ::-prefix
{
	my($pn) = @_;
	my($nfound,$val);
	foreach my $k (keys(%P)) {
		next unless ($k eq $pn) || ($k =~ /::$pn$/);
		$val = $P{$k};
		$nfound++;
	}
	croak("$0: %PARAM $pn ambiguous\n")
		if ($nfound > 1);
	return $val;
}

#----------------------------------------------------------------------

{ my($term);	# STATIC

sub debug($)
{
	my($prompt) = @_;
	unless (defined($term)) {						# initialize
		use Term::ReadLine;
		$term = new Term::ReadLine $ARGV0;
    }
	do {
		my($expr) = $term->readline("$prompt>");
		return if ($expr eq 'return');
		$res = eval($expr);
		if 	(defined($res)) {						# no error
			print(STDERR "$res\n");
		} else {									# error
			print(STDERR "$@");
		}
	} while (1);
}

} # STATIC SCOPE

1;
