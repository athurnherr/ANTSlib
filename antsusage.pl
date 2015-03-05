#/usr/bin/perl
#======================================================================
#                    A N T S U S A G E . P L 
#                    doc: Fri Jun 19 13:43:05 1998
#                    dlm: Wed Jul 30 12:43:52 2014
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 365 24 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Dec 30, 1998: - removed directory from $0
#				  - added global -P option (pass comments)
#	Jan 02, 1999: - changed -P to -T and added -P)refix for [./fnr]
# 	Feb 08,	1999: - added &antsUsageError()
#	Feb 17, 1999: - added -N
#	Feb 28, 1999: - forced string interpretation for -O, -R, -I
#	Mar 08, 1999: - added -L, $antsLibs
#	Mar 20, 1999: - added exit(1) for unknown options
#				  - added optional argument to &antsUsageError()
#	May 28, 1999: - library loading generated headers even on -Q
#	Jun 31, 1999: - added &antsDescription()
#	Jul 31, 1999: - added parameter typechecking (field, float, card, int, file)
#	Aug 02, 1999: - changed &antsDescription() to be option-dependent
#	Sep 18, 1999: - added option delimiter --
#				  - treat cardinals & integers differently
#				  - added option typechecking funs, e.g. &antsIntOpt()
#				  - auto set -Q if stdout is tty
#	Sep 19, 1999: - changed &getopts() from Perl4 to Perl5
#	Sep 21, 1999: - load local libraries first
#	Mar 06, 2000: - added for-M)at
#	Mar 07, 2000: - worked on -M
#	Aug 24, 2000: - removed setting -Q on tty (bad for [yoyo] and [Split])
#	Aug 28, 2000: - added -Z
#				  - changed -P to -A
#				  - added new -P
#	Sep 19, 2000: - set opt_M (dodgily) if not specifically set (only affects
#					[count] so far)
#	Sep 20, 2000: - added []-syntax to -P
#				  - added workaround for -M %0xd bug
#	Sep 25, 2000: - changed order of -P and -L processing
#	Sep 26, 2000: - cosmetics
#	Nov 13, 2000: - BUG: -- had left a single empty argument
#	Nov 15, 2000: - added &antsParamParam()
#				  - added &antsFileOpt()
#	Nov 17, 2000: - made -P override any header PARAMs
#	Jan  4, 2001: - moved -L processing before -P
#	Feb  8, 2001: - added -G)range option
#   Mar 17, 2001: - param->arg
#				  - added @file:field argument syntax
#				  - added #num-num[:step] syntax
#	Mar 23, 2001: - added prefix{#-#}suff syntax
#	Mar 31, 2001: - changed -G)range to #[..#]{,#[..#}
#				  - added -F)ields f{,f}
#	Apr  3, 2001: - added +f syntax to -F)ields
#	Apr  5, 2001: - added f+ syntax to -F)ields
#	Apr 24, 2001: - removed err msg in case of -G f:* (select numbers)
#	Apr 30, 2001: - shortened date, added pwd
#	Jun 23, 2001: - removed default setting of $opt_M
#	Jul  6, 2001: - added degree notation to &antsFloatArg() via str2num()
#	Jul 10, 2001: - added select field names (for V.3)
#	Jul 13, 2001: - store ONLY field names (replaced on 1st use)
#				  - added quotes to usage history
#	Jul 15, 2001: - added &antsNewFieldOpt()
#	Jul 16, 2001: - made it work with Description again
#	Jul 24, 2001: - removed fnr lookup on -G
#	Jul 30, 2001: - BUG: made parseHeader conditional on $antsFixedFormat
#	Aug  9, 2001: - chgd pref{#-#}suff syntax to expand only to exist files
#	Oct 28, 2001: - BUG: added -K handling before parseHeader
#	Nov 22, 2001: - moved logic into &antsParseHeader()
#	Nov 28, 2001: - cosmetics
#	Jan 18, 2002: - old -N => -X; new -N
#	Mar 24, 2002: - BUG: &antsFieldArg('file') did not handle %PARAMs correctly
#	Jul 26, 2002: - removed common usage from antsUsageError unless -U is set
#	Jan  6, 2003: - added regexp option to -G
#	Feb  9, 2003: - BUG: {103-103}.ens hung
#	Jun 26, 2004: - made sure that near-zero \#args are rounded to zero
#	Jun 27, 2004: - BUG: \#22-14 did not work correctly any more
#	Jul 12, 2004: - removed &antsDescription()
#	May  5, 2005: - added &antsNewField()
#	May 17, 2005: - allowed &antsFieldArg() to check [Layout]
#	Nov  1, 2005: - disallowed numeric options by adding -- if first argument
#				    begins with -[0-9]
#	Nov  8, 2005: - removed -P, -T => -P, -Z => -T, added -Z
#	Nov 17, 2005: - removed $antsLibs
#				  - removed remainder of -D
#				  - added $antsARGV0 for [yoyo]
#				  - added !<arg> quoting (for filenames)
#	Nov 18, 2005: - finally allowed %PARAMs in -G
#	Nov 21, 2005: - BUG: had not been allowed in -G fieldname
#   Dec  7, 2005: - antsFName -> antsLayout (not tested)
#	Dec  9, 2005: - Version 3.2 (see [HISTORY])
#	Dec 11, 2005: - error on 0 args & tty stdin
#	Dec 20, 2005: - created &antsFieldInFileArg() & added flag to &antsFieldArg
#				  - simplified opt_M, because it now works w/o $#
#	Dec 22, 2005: - added $antsInteractive for [abc]
#   Dec 23, 2005: - replaced defined(@array) (c.f. perlfunc(1))
#	Dec 31, 2005: - BUG: @-notation was broken (used antique [fields]!!!)
#	Jan  3, 2006: - added support for -S)elect
#	Jan  9, 2006: - removed old line-masking code
#	Jan 12, 2006: - removed -A support
#				  - removed support for $ENV{ANTS}
#				  - changed from old -H)eader <skip> to -H)ead <n lines>
#	Jan 13, 2006: - moved -G handling to -S
#				  - BUG: -G regexpr did not allow :
#				  - renamed -T)rim to -C)anonical
#				  - removed warnings on -M/-C
#				  - removed weird -Z)ap
#	Jan 14, 2006: - removed -G (now handled by -S)
#				  - changed semantics of pref{#-#}suff special arg to
#					expand non-existing file names
#	Jul 28, 2006: - made special arg #-#:# numerically more robust
#	Aug 18, 2006: - improved special arg to pref{#,#-#,...} and allow / instead of ,
#	Dec 14, 2006: - exported handling of -X to [antsio.pl]
#				  - disallow -P & -Q
#	May 31, 2007: - added -G
#	Nov 28, 2007: - replaced / by + to separate ranges in {} arguments
#	Mar  4, 2008: - disallow partial fname matches in antsNewField*()
#	Mar 24, 2008: - new usage formatting (glorious!)
#	Mar 25, 2008: - added $antsSummary
#   Mar 26, 2008: - extended -F syntax
#	Mar 27, 2008: - modified &antsUsage() to allow disabling common options
#	Apr 24, 2008: - added &antsFieldListOpt()
#	May  7, 2008: - disabled -N/-S for utilities without header parsing
#	May 13, 2008: - moved -U to standard usage message
#	Aug  5, 2008: - suppress empty usage lines
#   Nov 12, 2008: - added opt_T
#	Aug 24, 2009: - added V4 dependency on @file:field special args, file args & opts
#	Oct  3, 2009: - BUG: sometime recently I had changed the pref{}suff semantics to be
#				    much more permissive; this led to problems as args like {print $0}
#					were erroneously expanded; changed => pref{}suff is only expanded
#					if first expanded element is existing file
#				  - special args expanding to zilch are not expanded any more
#	Aug 16, 2010: - added -A)ctivate output (F/S Poseidon, P403, Lucky Strike)
#	Aug 28, 2010: - added suppress -D)ependency check option
#				  - improve common-options usage help
#	Oct 15, 2010: - removed diagnostic output about loading libs
#	Oct 29, 2010: - replaced list by Cat in expansion of @-special args
#	Dec 21, 2010: - made $@ at end of -F list optional (i.e. -F can end with ,)
#	Jul 21, 2011: - modified -D usage info
#	Sep 19, 2011: - SEMANTICS: pref{#-#}suff does now produce warning on missing files
#	Oct  3, 2011: - BUG: pref{}suff special args were (again) too permissive and matched
#						 output formats; this time, I solved problem by making regexp
#						 more restrictive; if this does not work, I can go back to
#					     earlier solution (see BUG Oct 3 2009)
#	Oct 16, 2011: - added support for \, escape in -F to protect commas used, e.g. in
#					function calls, from splitting the opt_F argument string
#	Nov 11, 2011: - BUG: antsNewField did not work for external layouts
#	Dec 29, 2011: - BUG: antsNewField did not work Cat -f c=1,1,10 without input
#				  - BUG: antsNewField did still not work for external layouts (the bug
#						 resulted in always extending the layout, even when the field already
#						 existed)
#	Feb 13, 2012: - antsNewFieldOpt simplified by using 2nd arg to fnrNoErr
#	Oct 29, 2012: - diabled "no file" messages on special args
#	Mar 29, 2013: - added support for $ANTSLIBS
#	Apr  2, 2013: - BUG: pref{}suff special args did sometimes produce unexpanded as well
#						 as expanded output (unexpanded should be produced only if the
#						 expansion is empty)
#	Jul 30, 2014: - added special args to -U)sage output

# NOTES:
#	- ksh expands {}-arguments with commas in them!!! Use + instead

use Getopt::Std;

sub antsUsageError() {									# die with Usage error
	if (defined($antsSummary)) {
		print(STDERR "\n$0 -- $antsSummary\n\n")
	} else {
		print(STDERR "\n$0\n\n")
	}
	if ($opt_U) {
		print(STDERR "Options & Arguments: $antsCurUsage$_[0]\n\n" .
			"Common Options:\n" .
				"\t[-F)ields {%P|f|[\$@]|[f]=expr}[,...]]\n" .
				"\t[num for-M)at] [-C)anonical numbers] [-G)eographic lat/lon]\n" .
				"\t[-A)ctivate output] [LaTeX -T)able output]\n" .
				"\t[-S)elect <addr-expr>] [-N)ums f[,...]] [-H)ead <n lines>]\n" .
				"\t[-P)ass comments] [-Q)uiet (no headers)] [-X (no new header)]\n" .
				"\t[suppress -D)ependency checks & addition of new dependencies]\n" .
				"\t[-L)oad <lib,...>]\n" .
	            "\t[-I)n field-sep] [-O)ut field-sep] [-R)ecord sep]\n\n" .
			"Special Argument Expansion:\n" .
				"\t@<file>:<field>\t\t\t<field> values in <file>\n" .
				"\t#<from>-<to>[:<step>]\t\tenumerated values\n" .
				"\t[prefix]{<ranges>}[suffix]\texisting files (ranges: <from>[-<to>][+...])\n" .
				"\t[prefix]((<file>))[suffix]\tfiles, using <file> with ranges\n");
	} else {
		print(STDERR "Options & Arguments: $antsCurUsage$_[0]\n");
	}
	croak("\n");
}

# NB: "-" as first char in opts string disables common-option processing

sub antsUsage($$@) {									# handle options
	my($opts,$min,@usage) = @_;
	my($cOpts) = 'ADM:QN:XCGPH:UI:O:R:L:F:S:T';
	my($d,$p);
	$antsCurUsage .= "\n\t[print full -U)sage]";
	foreach my $uln (@usage) {
		$antsCurUsage .= "\n\t$uln"						# suppress emtpy, e.g.
			unless ($uln eq '');						# for interp. model usage
	}

	&antsUsageError()									# no args && tty stdin
		if (!$antsInteractive && $min == 0 && @ARGV == 0 && -t 0);
	
	unshift(@ARGV,'--') if ($ARGV[0] =~ /^-\d/);		# -ve number heuristics

	chomp($0 = `basename $0`);							# set scriptname
	chop($d = `date +%D`);								# build header line
	chop($p = `pwd`);
	$p = "..." . substr($p,-17) if (length($p) > 20);
	$antsCurHeader = "#ANTS# [$d $p] $0";
	my($i,$eoo);
	for ($i=0; $i<=$#ARGV; $i++) {
		$antsCurHeader .= " '$ARGV[$i]'";
		$eoo = 1 if ($ARGV[$i] eq '--');				# -- handling
		$ARGV[$i] = "!$ARGV[$i+1]" if ($eoo); 			# make -ve non-options
	}
	$antsCurHeader .= "\n";
	pop(@ARGV) if ($eoo);								# remove last ARG

	if ($opts =~ m{^-}) {								# no common options processing
		$opts = $';
		undef($cOpts);
	}
	&antsUsageError(), exit(1)							# parse options
		unless (&getopts($cOpts . $opts));

	unless ($antsParseHeader) {
		croak("$0: -S not supported (implementation restriction)\n")
			if defined($opt_S);
		croak("$0: -N not supported (implementation restriction)\n")
			if defined($opt_N);
	}

	if ($eoo) {											# reset args
		for ($i=0; $i<=$#ARGV; $i++) {
			$ARGV[$i] = substr($ARGV[$i],1);
		}
	}

	if (defined($cOpts)) {								# process common options

		croak("$0: illegal option combination (-P & -Q)\n")
			if ($opt_P && $opt_Q);

		&antsActivateOut() if ($opt_A);					# activate output

		if ($opt_T) {									# LaTeX table output
			croak("$0: illegal option combination (-T & -G)\n")
				if ($opt_G);
			croak("$0: illegal option combination (-T & -O)\n")
				if defined($opt_O);
			$opt_O = ' & ';
			croak("$0: illegal option combination (-T & -R)\n")
				if defined($opt_R);
			$opt_R = ' \\\\\\\\\n';
        }
        
		if (defined($opt_I)) {							# defaults
			eval('$opt_I = "' . $opt_I .'";');			# interpret strings 
		} else {										# ... as perl strings
			$opt_I = '\s+';
		}
		if (defined($opt_O)) {
			eval('$opt_O = "' . $opt_O .'";');
		} else {
			$opt_O = "\t";
		}
		if (defined($opt_R)) {
			eval('$opt_R = "' . $opt_R .'";');
		} else {
			$opt_R = "\n";
		}
	
		if (defined($opt_L)) {							# load libraries
			foreach $lib (split(',',$opt_L)) {
				if (-r "lib$lib.pl") {
					require "lib$lib.pl";
				} elsif (-r "$ANTS/lib$lib.pl") {
					require "$ANTS/lib$lib.pl";
				} elsif (-r "$ANTSLIBS/lib$lib.pl") {
					require "$ANTSLIBS/lib$lib.pl";
				} else {
					croak("$0: cannot load {.,$ANTS,$ANTSLIBS}/lib$lib.pl\n");
				}
			}
		}
	
		if (defined($opt_N)) {							# parse -N)ums
			@antsNFNames = split(',',$opt_N);
	    }

		if (defined($opt_F)) {							# parse -F)ields
			$opt_F =~ s/\\,/aNtScOmMa/g;
			@antsOutExprs = split(',',$opt_F);	
			push(@antsOutExprs,'$@') if ($opt_F =~ /,$/);
			foreach my $e (@antsOutExprs) {
				$e =~ s/aNtScOmMa/,/;
			}
		}
	}

	my($ai);
	for ($ai=0; $ai<=$#ARGV; $ai++) {					# parse special args
		my(@exp);
		if ($ARGV[$ai] =~ /^@([^:]+):(.+)/) {			# @file:field
			&antsAddDeps($1);
			@exp = `Cat -QF$2 $1`;
			croak("(...while expanding $ARGV[$ai])\n") if ($?);
		} elsif ($ARGV[$ai] =~ /^#(-?[\d\.]+)-(-?[\d\.]+):?(-?[\d\.]+)?/) {
			my($step) = 1;								# #num-num:step
			if (defined($3)) {
				$step = $3;
			} elsif ($2 < $1) {
				$step = -1;
			}
			if ($step > 0) {
				for (my($c)=0,my($i)=$1; $i<=$2+$step/1e6; $c++,$i=$1+$c*$step) {
					$i = 0 if (abs($i) < abs($step) / 1e6);
					push(@exp,$i);
				}
			} else {
				for (my($c)=0,my($i)=$1; $i>=$2+$step/1e6; $c++,$i=$1+$c*$step) {
					$i = 0 if (abs($i) < abs($step) / 1e6);
					push(@exp,$i);
				}
			}
		} elsif ($ARGV[$ai] =~ m{\{([-\+,\d]+)\}}) {	# pref{list of ranges}suff
			my($pref) = $`; my($suff) = $';
			foreach my $range (split('[,\+]',$1)) {
				if ($range =~ /^(\d+)-(\d+)$/) {
					my($fmt) = length($1)==length($2) ?
							   sprintf("$pref%%0%dd$suff",length($1)) : "$pref%d$suff";
					if ($2 > $1) {
						for (my($i)=$1; $i<=$2; $i++) {
							my($f) = sprintf($fmt,$i);
							if (-f $f) { push(@exp,$f); }
#							else { &antsInfo("$ARGV[$ai]: no file <$f>"); }
						}
					} else {
						for (my($i)=$1; $i>=$2; $i--) {
							my($f) = sprintf($fmt,$i);
							if (-f $f) { push(@exp,$f); }
#							else { &antsInfo("$ARGV[$ai]: no file <$f>"); }
	                    }
	                }
				} else {
					my($f) = "$pref$range$suff";
#					print(STDERR "f = $pref . $range . $suff\n");
					if (-f $f) { push(@exp,$f); }
#					else { &antsInfo("$ARGV[$ai]: no file <$f>"); }
	            }
	        }
			@exp = ($ARGV[$ai])							# make sure it *was* special arg
				unless (@exp);
		} elsif ($ARGV[$ai] =~ m{\(\(([^\)]+)\)\)}) {		# pref((file))suff
			my($pref) = $`; my($suff) = $';
			&antsAddDeps($1);
			open(F,$1) || croak("$1: $!\n");
			while (<F>) {
				s/#.*//g; next if /^\s+$/;					# handle comments and empty lines
				s/\s*//g;
				chomp($_);
				if ($_ =~ /^(\d+)-(\d+)$/) {
					my($fmt) = length($1)==length($2) ?
							   sprintf("$pref%%0%dd$suff",length($1)) : "$pref%d$suff";
					if ($2 > $1) {
						for (my($i)=$1; $i<=$2; $i++) {
							push(@exp,sprintf($fmt,$i));
						}
					} else {
						for (my($i)=$1; $i>=$2; $i--) {
							push(@exp,sprintf($fmt,$i));
	                    }
	                }
				} else {
					push(@exp,"$pref$_$suff");
	            }
	        }
			close(F);
		} else {										# regular argument
			next;
		}
		&antsInfo("WARNING: special arg $ARGV[$ai] expands to nothing"),
		push(@exp,$ARGV[$ai])
			unless ($#exp >= 0);
		splice(@ARGV,$ai,1,@exp);
	}

	my($nargs) = $#ARGV + 1;							# check arg count
	&antsUsageError() if ($opt_U || ($min > 0) && ($nargs < $min));

	$antsARGV0 = $ARGV[0];								# save 1st filename
	&antsParseHeader();									# get fields & params

	for (my($i)=0; $i<=$#ARGV; $i++) {					# remove leading ! from args
		$ARGV[$i] =~ s/^!//;
	}
	
	return $nargs;
}

#======================================================================
# argument typechecking
#======================================================================

sub antsFieldInFileArg($)
{
	my($fn) = @_;
	my($fnr);
	
	&antsUsageError() unless defined($ARGV[0]);
	open(F,$fn) || croak("$fn: $!\n");
	if ($ARGV[0] =~ /^%/) {
		croak("$0: no PARAM $ARGV[0] in $fn\n")
			unless (defined(&antsFileScanParam(F,$')));
		$fnr = $ARGV[0];
	} else {
		$fnr = &antsFileScanFnr(F,$ARGV[0]);
		unless (defined($fnr)) {
			print(STDERR "$0: WARNING: no field $ARGV[0] in $fn\n");
			$fnr = &fnr($ARGV[0]);
		}	    
	}
    close(F);

	shift(@ARGV);
	return $fnr;
}

sub antsFieldArg($)
{
	&antsUsageError() unless defined($ARGV[0]);
	my($paramsAllowed) = @_;
	my($fnr) = &fnr($ARGV[0]);
	croak("$0: $ARGV[0] is not a field\n")
		unless (numberp($fnr) || $paramsAllowed);
	shift(@ARGV);
	return $fnr;
}

sub antsFieldOpt(@)
{
	my($opt,$default) = @_;
	if (ref($opt)) {									# reference => set
		if (defined(${$opt})) {							# defined => check,set
			${$opt} = &fnr(${$opt});
		} elsif (defined($default)) {					# not defined => default
			${$opt} = &fnr($default);
		}
		return ${$opt};
	} else {											# not ref => do not set
		return defined($opt) ? &fnr($opt) :
					defined($default) ? &fnr($default) : $opt;
	}
}

sub antsFieldListOpt($)
{
	my($opt) = @_;
	my(@fn) = split(',',$opt);
	my(@fi);

	for (my($i)=0; $i<@fn; $i++) {
		$fi[$i] = &fnr($fn[$i]);
	}
	return @fi;
}

sub antsNewField($)										# allocate if needed
{
	my($fname) = @_;
	my($fnr);
	
	$fnr = &fnrNoErr($fname,1);							# exact match
	unless (defined($fnr)) {
		return $antsBufNFields++						# external layout
			unless ($antsBufNFields==0 || @antsLayout);
		@antsNewLayout = @antsLayout
			unless (@antsNewLayout);
		push(@antsNewLayout,$fname);
		$fnr = $#antsNewLayout;
	}
	$antsBufNFields = $fnr+1 if ($fnr >= $antsBufNFields);
	return $fnr;
}

sub antsNewFieldOpt(@)									# allocate if does not exist
{
	my($opt,$default) = @_;
	my($fname,$fnr);

	if (ref($opt)) {									# reference => set
		if (defined(${$opt})) {							# defined => check,set
			$fname = ${$opt};
		} elsif (defined($default)) {					# not defined => default
			$fname = $default;
		}
		if (defined($fname)) {
			$fnr = &antsNewField($fname);
			${$opt} = $fnr;
			return $fnr;
		} else { return undef; }
	} else {											# not ref => do not set
		if (defined($opt)) {
			$fname = $opt;
		} elsif (defined($default)) {
			$fname = $default;
		}
		return defined($fname) ? &antsNewField($fname) : undef;
	}
}

sub antsNoFileErr($$)
{
	croak("$0: $_[0] $_[1] is not a valid file\n")
		unless (-r $_[1]);
	&antsAddDeps($_[1]);
}

sub antsFileArg()	# arg 1 => do not shift
{
	&antsUsageError() unless defined($ARGV[0]);
	&antsNoFileErr("Argument",$ARGV[0]);
	my($res) = $ARGV[0];
	shift(@ARGV) unless ($_[0]);
	return $res;
}

sub antsFileOpt($)
{
	my($opt) = @_;
	&antsNoFileErr("Option Argument",$opt)
		if (defined($opt));
}

sub antsParamArg()
{
	&antsUsageError() unless defined($ARGV[0]);
	croak("$0: Argument $ARGV[0] is not a valid PARAM\n")
		unless ($ARGV[0] =~ /^%/);
	shift(@ARGV);
	return $';
}

sub antsNoCardErr($$)
{
	croak("$0: $_[0] $_[1] is not a cardinal number\n")
		unless (cardinalp($_[1]));
}

sub antsCardArg()
{
	&antsUsageError() unless defined($ARGV[0]);
	$ARGV[0] = &{&antsCompileConstExpr($')}
		if ($ARGV[0] =~ m{^=});
	&antsNoCardErr("Argument",$ARGV[0]);
	my($res) = 1.0*$ARGV[0];
	shift(@ARGV);
	return $res;
}

sub antsCardOpt(@)
{
	my($opt,$default) = @_;
	if (ref($opt)) {									# reference => set
		if (defined(${$opt})) {							# defined => check
			$$opt = &{&antsCompileConstExpr($')} if ($$opt =~ m{^=});
			&antsNoCardErr("Option Argument",${$opt});
		} else {										# not defined => default
			${$opt} = $default;
		}
		return ${$opt};
	} else {											# not ref => do not set
		if (defined($opt)) {
			$opt = &{&antsCompileConstExpr($')} if ($opt =~ m{^=});
			&antsNoCardErr("Option Argument",$opt);
	        return $opt;
	    } else {
	    	return $default;
	    }
	}
}

sub antsNoIntErr($$)
{
	croak("$0: $_[0] $_[1] is not an integer\n")
		unless (integerp($_[1]));
}

sub antsIntArg()
{
	&antsUsageError() unless defined($ARGV[0]);
	$ARGV[0] = &{&antsCompileConstExpr($')}
		if ($ARGV[0] =~ m{^=});
	&antsNoIntErr("Argument",$ARGV[0]);
	my($res) = 1.0*$ARGV[0];
	shift(@ARGV);
	return $res;
}

sub antsIntOpt(@)
{
	my($opt,$default) = @_;
	if (ref($opt)) {									# reference => set
		if (defined(${$opt})) {							# defined => check
			$$opt = &{&antsCompileConstExpr($')} if ($$opt =~ m{^=});
			&antsNoIntErr("Option Argument",${$opt});
		} else {										# not defined => default
			${$opt} = $default;
		}
		return ${$opt};
	} else {											# not ref => do not set
		if (defined($opt)) {
			$opt = &{&antsCompileConstExpr($')} if ($opt =~ m{^=});
			&antsNoIntErr("Option Argument",$opt);
	        return $opt;
	    } else {
	    	return $default;
	    }
	}
}

sub antsNoFloatErr($$)
{
	croak("$0: $_[0] $_[1] is not a number\n")
		unless (numberp($_[1]));
}

sub antsFloatArg()
{
	&antsUsageError() unless defined($ARGV[0]);
	$ARGV[0] = &{&antsCompileConstExpr($')}
		if ($ARGV[0] =~ m{^=});
	my($res) = str2num($ARGV[0]);
	&antsNoFloatErr("Argument",$res);
	shift(@ARGV);
	return $res;
}

sub antsFloatOpt(@)
{
	my($opt,$default) = @_;
	if (ref($opt)) {									# reference => set
		if (defined(${$opt})) {							# defined => check
			$$opt = &{&antsCompileConstExpr($')} if ($$opt =~ m{^=});
			&antsNoFloatErr("Option Argument",${$opt});
		} else {										# not defined => default
			${$opt} = $default;
		}
		return ${$opt};
	} else {											# not ref => do not set
		if (defined($opt)) {
			$opt = &{&antsCompileConstExpr($')} if ($opt =~ m{^=});
			&antsNoFloatErr("Option Argument",$opt);
	        return $opt;
	    } else {
	    	return $default;
	    }
	}
}

1;														# return true
