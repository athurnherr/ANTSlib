#!/usr/bin/perl
#======================================================================
#                    A N T S I O . P L 
#                    doc: Fri Jun 19 19:22:51 1998
#                    dlm: Wed Apr 10 16:57:59 2019
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 217 48 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jun 19, 1998: - created
#	Dec 29, 1998: - added antsLineFlag and antsLinePrefix
#	Dec 30, 1998: - added -P)assthrough option handling, arg to &antsFlush()
#	Jan 02, 1999: - changed -P to -T and added -P)refix for [./fnr]
#	Feb 17, 1999: - added &antsReadFile()
#	Feb 25, 1999: - added &antsInfo()
#	Mar 11, 1999: - set undefined ret-vals of &antsBufOut() to NaN
#	Mar 12, 1999: - added FILE to &antsPrintHeaders()
#	Mar 14, 1999: - BUG ensured that $ants_[0] was defined when
#				    typical &antsBufFull was called on empty buffer
#				  - added &antsPostFlush()
#				  - added &antsSetR_()
#				  - BUG padding by &antsSet_() was broken
#	Mar 20, 1999: - added code to abort if file on cmdline does not exist
#				  - removed &antsReadFile()
#	Oct 31, 1999: - BUG when using -I
#	Dec 06, 1999: - made &antsInfo() respect -Q
#	Mar 07, 2000: - adapted to -M
#	Jul 31, 2000: - removed buffer auto growth unless $antsPadOut
#	Aug 21, 2000: - allow for in-line comments on -T
#	Aug 28, 2000: - added opt_Z to remove leading zeroes on output
#				  - added %P handling
#	Sep 03, 2000: - documentation
#	Sep 04, 2000: - ensure %PARAMS are not just whitespace strings
#	Oct 31, 2000: - added &antsReplaceParam()
#	Nov 07, 2000: - added &antsFileScanParam()
#	Nov 10, 2000: - made to ignore DOS EOF (BLOERKS!!!)
#	Nov 16, 2000: - added comment about antsIO() bypassing &antsBufOut()
#	Nov 17, 2000: - made -P override header PARAMs
#	Jan 16, 2001: - cosmetics
#	Feb 19, 2001: - added $antsNoHeaderCopy for [data]
#	Mar  8, 2001: - adapted to -G)range
#	Mar 18, 2001: - BUG: -G had selected NaNs
#	Mar 22, 2001: - added $antsNoEmbeddedHeaderCopy for [fields] [efields]
#	Mar 28, 2001: - mark header info of utils used in pipelines
#	Mar 31, 2001: - updated -G)range
#				  - adapted to -F)ields
#	Apr  3, 2001: - added appendfields
# 	Apr  5, 2001: - removed string interpolation from &antsOut()
#				  - added prependfields
#	May 15, 2001: - output NaN on undefined -F vals
#	Jun  4, 2001: - allowd %PARAMs on -F
#	Jun 19, 2001: - added pseudo param %FILE
#	Jul  9, 2001: - added Active ANTS stuff
#	Jul 10, 2001: - continued, split off &antsParseHeader()
#	Jul 11, 2001: - continued
#	Jul 13, 2001: - replace -F fields names on 1st use
#	Jul 16, 2001: - moved fchmod call to &antsPrintHeaders(), c.f. [Split]
#	Jul 19, 2001: - embedded error messages in pipeline
#				  - copy header on -ve -H
#	Jul 24, 2001: - BUG: set $antsNewLayout on -F
#				  - BUG: remove % from -F layout
#				  - moved fnr lookup for -G from [antsusage.pl]
#	Aug  1, 2001: - BUG: &antsIn() had not restored @ARGV on EOF
#	Aug  3, 2001: - added &antsFileScanLayout()
#	Aug  9, 2001: - BUG: $antsNewLayout was not set on prepend/append fields
#	Aug 10, 2001: - added $opt_G to &antsFileIn()
#	Aug 19, 2001: - BUG: &antsReplaceParam() re-written
#	Aug 29, 2001: - BUG: made -r into -f && -r
#	Oct 28, 2001: - BUG: handled antsLinePrefix on parseHeader
#	Nov 22, 2001: - added $antsParseHeader flag
#	Nov 28, 2001: - allowed %param in -G
#	Dec 30, 2001: - added &antsExit()
#	May 18, 2002: - added %BASENAME, %EXTN
#	May 20, 2002: - added $antsNewFile
#	Jun 22, 2002: - added $antsPadIn
#	Jan  6, 2003: - added $antsGrex (-G regex support)
#	Jan  8, 2003: - added &antsFileParams()
#	Mar  4, 2003: - added %RECNO
#	Apr 14, 2003: - BUG: antsReplaceParam() removed because in-stream
#						 %PARAMs are not generally handled correctly
#				  - BUG: antsFileScanParam() had returned the first
#						 value encountered, NOT the valid (last) one!!!
#	Apr 24, 2003: - BUG: added default $antsPadIn = 1 (required for
#						 [gamma_n])
#	May  8, 2003: - made antsFileIn() respect -N (for [gshear])
#	Jul  1, 2004: - BUG: $antsBufNFields was not set when an empty file
#						 with valid #ANTS#FIELDS# was read
#	Jul  9, 2004: - BUG: test of incompatible in-file field definitions
#						 did not work
#	Dec  5, 2004: - BUG: Jul 1 fix did not work correctly in cases where
#						 subsequent #ANTS#FIELDS# lines would shrink the
#						 number of fields; new fix was not debugged!
#	Jan 17, 2005: - removed path from active files and used perl -S
#	Feb  8, 2005: - made activation-status copy more portable (i.e.
#					independent of perl path)
#	Mar  7, 2005: - added %DIRNAME (& cleaned up %BASENAME %EXTN)
#	Nov  8, 2005: - changed -T to -P, -Z => -T, added -Z
#	Nov 17, 2005: - BUG: antsPreFlush() flushed one too few ([fmedian])
#				  - BUG: antsFlagged was not set correctly any more
#	Nov 18, 2005: - finally allowed %PARAMs bounds in -G
#	Nov 21, 2005: - BUG: %PARAM bounds in -G had broken regexp capability
#	Dec  7, 2005: - BUG: embedded layout overrode @antsFName if $antsNewLayout
#				  - replaced @antsFName by @antsLayout{In,Out}
#	Dec  8, 2005: - Version 3.2 (see [HISTORY])
#	Dec 12, 2005: - disable output padding in &antsOut() if new layout
#	Dec 14, 2005: - made &antsAddParams() set %P
#				  - removed &antsReplaceParam()
#	Dec 20, 2005: - BUG: empty field names in Layout replaced by undef
#				  - $# is buggy => implemented opt_M without $#
#	Dec 23, 2005: - replaced defined(@array) (c.f. perlfunc(1))
#                 - BUG: -F did not work ok when @antsNewLayout was set
#   Dec 29, 2005: - added $PARAMSonly to avoid output duplication on -F%param
#   Dec 30, 2005: - changed &antsFileIn() EOF return
#   Jan  3, 2006: - BUG: pseudo %PARAMs (e.g. BASENAME) were not set
#                        on EOF when buffer is not full
#                 - changed %FILE to %FILENAME
#                 - added support for -S)elect
#   Jan  4, 2006: - BUG: empty strings were not output as NaN
#   Jan  9, 2006: - removed line flagging code
#   Jan 12, 2006: - replaced old -H)eader skip support with new -H)ead
#   Jan 13, 2006: - new [antsexprs.pl]
#                 - removed -G handling (now done as -S)
#                 - renamed -T)rim to -C)anonical
#                 - removed -Z)ap handling
#   Jan 14, 2006: - continued removing -G
#   Jan 31, 2006: - BUG: selecting last field per record with -I produced
#                        an extraneous empty line
#   May 18, 2006: - BUG: set pseudo-params before -S test, to allow e.g.
#                        -S %RECNO==3 to work
#                 - BUG: set %RECNO on partially full buffer
#                 - added %LINENO pseudo param
#   Jun 27, 2006: - BUG: added formal param @ to allow antsOut(NaN) to be
#                        used in list -w
#				  - changed semantics of antsPadOut()
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#	Jul 10, 2006: - removed fchmod (now in perl chmod)
#	Jul 21, 2006: - removed obsolete code
#	Jul 22, 2006: - shuffled &antsOut() to allow for -H0
#	Jul 23, 2006: - BUG: -F%PARAM did not work any more
#	Jul 28, 2006: - BUG: pseudo-params were set during header parsing of
#						 an empty file
#	Jul 31, 2006: - BUG: @antsLayout was not set on 0-record files
#				  - code cleanup
#	Aug 24, 2006: - added $antsIgnoreInputParams
#	Aug 28, 2006: - made antsIgnoreInputParams into eva'ed expr for [bindata]
#	Oct 26, 2006: - allowed for empty lines in &antsFileScanParams()
#	Nov 10, 2006: - suppressed copying of layout even if embedded headers
#					are copied
#	Dec 17, 2007: - modified behavior of antsIgnoreInputParams (see NOTES below)
#	Jan 16, 2007: - re-implemented changes to -P mandated by Dec 14, 2006
#				    changes to [antsusage.pl]
#	May 31, 2007: - added support for -G)eographic coord format
#	Nov 14, 2007: - maded -G work with %PARAMS
#				  - BUG: %FILENAME (& others) not set on %PARAMS-only files
#	Nov 15, 2007: - BUG: -G had never worked correctly when selecting fields
#	Feb  8, 2008: - moved number output formatting to fmtNum() [antsutils.pl]
#	Mar 26, 2008: - modified/extended -F behavior
#	Mar 28, 2008: - fiddled
#	Apr 15, 2008: - BUG: pseudo params were not set during header parsing
#						 => e.g. %RECNO could not be used in ded addr-expr
#	May  1, 2008: - BUG: embedded header copy also copied embedded layout
#						 re-definitions
#	May 22, 2008: - BUG: $antsPadOut = 0 did not suppress padding as intended
#						 in presence of layout or new layout => add option of
#						 setting it to -1
#	Jul 11, 2008: - BUG: file-name-related pseudo %PARAMs did not work
#						 correctly for input files without extensions
#				  - added %FILENAME -> %PATHNAME
#	Jul 21, 2008: - fiddled with antsInfo()
#	Jul 23, 2008: - added code to allow deleting %PARAMs by setting them
#					to undef in [list]
#	Jul 29, 2008: - BUG: removed code to strip leading/trailing spaces from
#						 %PARAMs (before, a %PARAM containing just spaces
#						 was deleted on an NCode/listNC combo --- there is
#						 an example in [ubtest/NCode.TF]
#	Jun 10, 2009: - added duplicate-output-field sanity check
#	Aug  1, 2009: - BUG: duplicate unnamed output files generated error
#	Aug 23, 2009: - V4.0: added &antsAddDeps
#	Aug 25, 2009: - BUG: '-' was added as a dep for STDIN
#	Aug 27, 2009: - added pseudo %PARAM %DEPS
#	Oct  3, 2009: - added $antsAllowEmbeddedLayoutChange
#	Oct 12, 2009: - changed antsAddDeps() to ignore empty dependencies
#	Oct 13, 2009: - removed antsAddDeps() defaults
#	Oct 15, 2009: - replaced \n by \\n in antsAddParams(); primarily for listNC
#	Nov  3, 2009: - BUG: <> dependencies were not set when $antsParseHeader was set to 0
#	Nov  6, 2009: - BUG: stdin had sometimes produced empty dep
#	Aug 15, 2010: - turned error on duplicate output fields into warning
#	Aug 28, 2010: - moved dependency checks from [list] to here
#	Oct 18, 2010: - disabled dependency checks for files in other directories
#	Oct 19, 2010: - implemented &antsOut('EOF') to clear all static vars & other stuff to
#				    allow a single utility to output different ANTS files (used in
#				    LADCPproc)
#	Apr 28, 2011: - added code to make all nans lowercase to antsIn()
#	May 20, 2011: - BUG: %LINENO had not been reset between files any more
#	May 22, 2011: - adapted to new antsCompileEditExpr()
#	May 24: 2011: - BUG: forgot '$' in a variable (where???)
#	Jul 28, 2011: - disabled adding of new deps on -D
#	Apr 11, 2012: - improved layout-change error message
#	Apr 26, 2012: - BUG: antsFileScanParam() was not properly anchored (%start_date matched %BT.start_date)
#	Jul 20, 2014: - adapted antsFileScanParam() to :: convention
#	Jul 22, 2014: - BUG: antsPadIn was done after handling -S & -N
#				  - removed antsPadIn flag (made it always be true)
#	Aug  7, 2014: - allow optional % in param name in &antsFileScanParam()
#	Oct 29, 2014: - implemented abbreviated Layout and %PARAM definitions
#	Sep 27, 2015: - BUG: antsDeps() accumulate with multiple input files; solution is to make sure that
#						 antsCheckDeps() is called whenever a new input file has been read for the first
#						 time (as in [list]), because antsCheckDeps() deletes the dependencies after
#						 checking
#	Jan 15, 2016: - BUG: antsCheckDeps() cannot delete the dependencies after checking because,
#						 otherwise, dependencies are not inherited => presumably, Sep 27 bug fix has been
#						 reversed
#	Sep 13, 2016: - modified &antsAddParams to make more flexible
#	Mar 10, 2017: - BUG: antsCheckDeps() used ctime instead of mtime!!!
#	Apr  5, 2017: - BUG: stale file mtime dependency info was not printed correctly
#	Apr 23, 2018: - BUG: @antsLayout was not kept up-to-date when layout-changes are allowed
#	Apr 10, 2019: - disabled dependency warnings

# GENERAL NOTES:
#	- %P was named without an ants-prefix because associative arrays
#	  are rare (and perl supports multiple name spaces for the
#	  different variable types) and to facilitate its use in
#	  [list]
#	- copying of embedded (i.e. not appearing at start) headers is
#	  required e.g. for subsample -i ... | list %some-param

# ABBREVIATED LAYOUT & PARAM DEFINITIONS
#	- # definition [definition [...]]
#	- definition := field_name | %PARAM_def
#	- field_name := {string}
#	- %PARAM_def := string{string|num}
#	- implemented in October 2014 in order to make ANTS format easier to use for others
#	- abbreviated and full headers must not be used together
#	- abbreviated field definitions are additive (rather than replacing, as in the full headers)

# $antsIngoreInputParams:
#	- is eval'ed first time antsIn() is called (usually while parsing header)
#	- if it evaluates to TRUE, all input %PARAMS are ignored (even if it would
#	  later eval to FALSE)
#	- during header parsing, @ARGV only contains additional file arguments,
#	  i.e. setting $antsIgnoreInputParams = '@ARGV>0' before antsUsage() is
#	  called ignores all input %PARAMs if there is more than 1 file argument

#======================================================================
# Default Behaviour 
#======================================================================

# Flags

$antsFixedFormat = 0;						# remove leading & trailing stuff
$antsParseHeader = 1;						# parse header on &antsUsage()
$antsIgnoreInputParams = 0;					# ignore %PARAMs
$antsAllowEmbeddedLayoutChange = 0;			# disallow layount changes

# Standard Fixed Size Buffer

sub antsBufFull()							# default buffer full
    {return $#ants_+1 == $antsBufSize;}   
sub antsBufOut($)                           # default constructor
    {return $ants_[$ants_][$_[0]]; }

# Setup Size 1 Buffer

$antsBufSize = 1;							# default
$antsBufSkip = 1;

#======================================================================
# Interface
#======================================================================

sub antsInstallBufFull($)
{
	eval "sub antsBufFull() { $_[0] }";
	croak($@) if ($@);
	&antsReCompile();
}

sub antsInstallBufOut($)
{
	eval "sub antsBufOut(\$) { my(\$fnr)=\@_; $_[0] }";
	croak($@) if ($@);
	&antsReCompile();
}

sub antsActivateOut()
{
	$antsActiveHeader = "#!/usr/bin/perl -S list\n" unless ($opt_Q);
}

#----------------------------------------------------------------------
# antsCheckDeps([filename]):
#	- call only after header has been parsed
#	- by default, tests current <> file
#----------------------------------------------------------------------

{ my($warned) = 1;									# disable dependency warning

  sub antsCheckDeps()
  {
#	  print(STDERR "checking dependencies of file $infile (deps = @antsDeps)\n");
	  return unless (@antsDeps);					# no dependency info
	  return if ($opt_D);							# suppressed by user

	  my($infile) = @_ ? $_[0] : $ARGV; 			# default: check current input
	  my($indir) = ($infile =~ m{^(.*)/[^/]*$});
	  return if defined($indir) && $indir ne '.';	# not in current directory
	  
	  my(@stat) = stat($infile);					# get time
	  return unless (@stat);						# happens on stdin?
	  
	  my($mtimef) = 9; my($mtime) = $stat[$mtimef];
	  for (my($d)=0; $d<=$#antsDeps; $d++) {
		  @stat = stat($antsDeps[$d]);
		  if (@stat) {
			  croak("$0: <$infile> ($mtime) is stale with respect to <$antsDeps[$d]> ($stat[$mtimef])\n")
				  unless ($stat[$mtimef] <= $mtime);
		  } elsif (!$warned) {
			  &antsInfo("WARNING: dependency $antsDeps[$d] (&, possibly, others) not found");
			  $warned = 1;
		  }
	  }
#	  undef(@antsDeps);								# don't check again; BUG: 01/15/2016
  }
} # static scope

sub antsParseHeader()
{
	return if ($antsFixedFormat || !$antsParseHeader);
	$antsDoParseHeader = 1;						# glorks!
	my($success) = &antsIn();
	&antsCheckDeps();
	return $success;
}

#----------------------------------------------------------------------

sub def_abbrev($)
{
	my($def) = @_;
	if ($def =~ /^\{(\w+)\}$/) {
		push(@Layout,$1);
	} else {
		my($name,$val) = ($def =~ /(\w+)\{([^\}]+)\}/);
		$P{$name} = $val;
	}
}

sub antsReCompile()								# re-compile with funs
{ eval '

sub antsIn()
{
	local(@Layout);
	undef(@Layout);								# needed, but unclear why

	undef($antsNewFile);						# assume no new file

	unless ($antsHeaderParsed || $antsDoParseHeader) {
		for (my($i)=0; $i<=$#ARGV; $i++) {		# check file params
			open($ARGV[$i]),croak("$0: $ARGV[$i]: $!\n")
				unless (-f $ARGV[$i] && -r $ARGV[$i]);
	    }
		&antsAddDeps($ARGV,@ARGV);				# <> files
		$antsCurHeader =~ s/\]/\] |/			# mark as pipeline
			unless (-t 0);
	    $antsHeaderParsed = 1;
	}

	my(@tempARGV);								# temporily remove non-file args
	if ($antsDoParseHeader) {
		my($ai) = $#ARGV;
		while ($ai >= 0 && -f $ARGV[$ai]) { $ai-- }
#		print(STDERR "before: @ARGV\n");
		push(@tempARGV,splice(@ARGV,0,$ai+1));
#		print(STDERR "after: @ARGV\n");
		if ($#ARGV < 0 && -t 0) {					# donot wait on stdin
			push(@ARGV,@tempARGV);
			$antsDoParseHeader=0;
			return 0;
		}
	}

	splice(@ants_,0,$antsBufSkip);					# shift buffers

	IN: until ($#ants_>=0 && &antsBufFull()) {		# fill buffer; NEEDS RECOMPILE

		if (defined($antsPeekBuffer)) {				# from header parsing
			$_ = $antsPeekBuffer;
			$antsPeekBuffer = undef;
		} else {
			unless ($_ = <>) {						# get next record
				# EOF before buffer is full (can be partially filled)
				unshift(@ARGV,@tempARGV);			# restore ARGV list

				@antsLayout = @Layout if (@Layout);	# set last defined layout
				$antsBufNFields = @antsLayout		# adjust buffer width
					if (@antsLayout > $antsBufNFields);

				my($lastFile) = $P{PATHNAME};
				$P{PATHNAME} = $ARGV;				# set pseudo %PARAMs
				($P{DIRNAME},$P{FILENAME}) =
					($ARGV =~ m{^(.*)/([^/]+)$});
				unless (defined($P{DIRNAME})) {
					$P{DIRNAME} = ".";
					$P{FILENAME} = $P{PATHNAME};
				}
				($P{BASENAME},$P{EXTN}) =
					($P{FILENAME} =~ m{^([^\.]+)\.(.+)$});
				unless (defined($P{EXTN})) {
					$P{BASENAME} = $P{FILENAME};
					$P{EXTN} = "";
				}
				$P{DEPS} = "@antsDeps";

				return 0 if ($antsDoParseHeader);	# empty file!!!

				$P{RECNO} = -1						# set pseudo %PARAMs
					unless defined($P{RECNO});
	    		$P{RECNO}++;
			    $P{LINENO} = ($ARGV eq $lastFile) ? $P{LINENO}+1 : 0;

				return 0;							# return EOF
			}
		}

		next IN if (length == 1 && ord == 26);		# handle MS-DOG EOF

		&antsActivateOut(),next IN					# copy activation status
			if (m{^#![^\s]*/perl\s.*list$});

		exit(1) if (/^#ANTS#ERROR#/);				# error in pipeline

		if (/^#ANTS#PARAMS# ([^\{]+)\{([^\}]*)\}/) {
			if (eval($antsIgnoreInputParams)) {		# eval only 1st time
				$antsIgnoreInputParams = 1;
				next IN;
			}
			do {
				if ($2 eq "") {
					delete($P{$1});
				} else {
					$P{$1} = $2;
				}
			} while ($\' =~ m/ ([^\{]+)\{([^\}]*)\}/);
		} elsif (/^#ANTS#DEPS# \{([^\}]*)\}/) {		# handle dependencies
			do { push(@antsDeps,$1); }
				while ($\' =~ m/ \{([^\}]*)\}/);
		} elsif (/^#ANTS# \[[^\]]*\] [^|]/) {		# pipe-head => restart dependencies
			undef(@antsDeps);
		} elsif (/^#ANTS#FIELDS# \{([^\}]*)\}/) {	# handle layout
			undef(@Layout);
			do {
				push(@Layout,$1 eq "" ? undef : $1);
			} while ($\' =~ m/ \{([^\}]*)\}/);
		} elsif (/^# (\{\w+\}|\w+\{[^\}]+\})+/) {		# ABBREVIATED DEFINITIONS
			my($match) = $1; my($rem) = $\';
			do {
				def_abbrev($match);
				($match,$rem) = ($rem =~ /(\{\w+\}|\w+\{[^\}]+\})(.*)/);
			} while ($match);
		}
				
		if (!($opt_Q || $antsNoHeaderCopy) && /^#ANTS#/) {	# handle headers
			if (defined($antsHeadersPrinted)) {		# embedded headers
# The following is somewhat subtle because it must prevent embedded
# layout definitions to be copied 1) even if embedded headers are requested
# (because otherwise there will be embedded-layout-change errors) 2) but not
# if there has not been a layout defined already (ubtest common_opts);
				print unless ($antsNoEmbeddedHeaderCopy ||
								(/^#ANTS#FIELDS#/ && @antsLayout));
			} else {
				$antsOldHeaders .= $_;
			}
			next IN;
		}

		if (/^#/) {								# handle non-header comments
			&antsPrintHeaders(STDOUT,@antsNewLayout),print if ($opt_P);
			next IN;
		}

		next IN if /^\s*$/;						# skip empty lines
		unless ($antsFixedFormat) {
			s/^\s+//;							# strip leading space
			s/#.*$// unless ($opt_P);			# strip trailing comments
			s/\s+$//;							# strip trailing space
		}

		# DONE WITH HEADER PARSING
		
		# Handle Layout changes:
		#	- only allow when $antsAllowEmbeddedLayoutChange is set
		#	- ensure that antsLayout always contains up-to-date Layout
		croak("$0: embedded layout change when reading file $ARGV <@antsLayout> -> <@Layout>")
			if (!$antsAllowEmbeddedLayoutChange && @Layout && @antsLayout && ("@Layout" ne "@antsLayout"));
		@antsLayout = @Layout if (@Layout);

		$P{RECNO} = -1 unless defined($P{RECNO});	# set pseudo %PARAMs
		$P{LINENO} = -1 unless defined($P{LINENO});
		$P{DEPS} = "@antsDeps";
		
		my($lastFile) = $P{PATHNAME};
		$P{PATHNAME} = $ARGV;		    
		($P{DIRNAME},$P{FILENAME}) =
			($ARGV =~ m{^(.*)/([^/]+)$});
		unless (defined($P{DIRNAME})) {
			$P{DIRNAME} = ".";
			$P{FILENAME} = $P{PATHNAME};
		}
		($P{BASENAME},$P{EXTN}) =
			($P{FILENAME} =~ m{^([^\.]+)\.(.+)$});
		unless (defined($P{EXTN})) {
			$P{BASENAME} = $P{FILENAME};
			$P{EXTN} = "";
        }

		if ($antsDoParseHeader) {					# done parsing
			unshift(@ARGV,@tempARGV);
			$antsDoParseHeader = undef;
			$antsPeekBuffer = $_;
			$antsPadOut = $antsBufNFields = split($opt_I,$antsPeekBuffer);
			return 1;
		}
		
	    $P{RECNO}++;								# update pseudo %PARAMs
	    $P{LINENO} = ($ARGV eq $lastFile) ? $P{LINENO}+1 : 0;

		s/[Nn][Aa][Nn]/nan/g;						# make all nans lower case

        local(@in) = split($opt_I);                 # needs to be local for -S 
		if (@in > $antsBufNFields) {				# increase # of fields to expect
			$antsBufNFields = @in;
			for ($i=0; $i<$#ants_; $i++) {			# update recs already in buffer
				push(@{$ants_[$i]},nan)
					while ($#{$ants_[$i]}+1 < $antsBufNFields);
            }
		}
		push(@in,nan)								# pad current record
            while (@in<$antsBufNFields);

        if (defined($opt_S)) {                      # -S)elect
            $opt_S = &antsCompileAddrExpr($opt_S,\'$in\')
                unless ref($opt_S);
            next IN unless (&$opt_S);
        }
        
        if (@antsNFNames) {                         # -N)ums
            for (my($i)=0; $i<=$#antsNFNames; $i++) {
                unless (defined($antsNfnr[$i])) {
                    if ($antsNFNames[$i] =~ /^%/) {
                        croak("$0: illegal -N option ($antsNFNames[$i] undefined)\n")
                            unless (defined($P{$\'}));
                        next IN unless (numberp($P{$\'}));
                    } else {
                        $antsNfnr[$i] = &fnr($antsNFNames[$i]);
                        next IN unless (numberp($in[$antsNfnr[$i]]));
                    }
                } else {
                    next IN unless (numberp($in[$antsNfnr[$i]]));
                }
            }
        }

        chomp;
        $antsLineBuf = $_;                      # save

        push(@ants_,[@in]);                     # add to buffer

###		if ($#{$ants_[$#ants_]}+1 > $antsBufNFields) {	# grow # of fields
###			$antsBufNFields = $#{$ants_[$#ants_]} + 1;
####			print("antsBufNFields := $antsBufNFields --- $_");
###				for ($i=0; $i<$#ants_; $i++) {
###					push(@{$ants_[$i]},nan)
###						while ($#{$ants_[$i]}+1 < $antsBufNFields);
###	            }
###	        }
###		}
###		push(@{$ants_[$#ants_]},nan)			# pad this
###	        while ($#{$ants_[$#ants_]}+1 < $antsBufNFields);
	}

	$ants_ = ($#ants_ - $#ants_%2) / 2;			# set current idx to centre
#	print(STDERR "reading done; $#ants_+1 recs in buf, $ants_ is cur\n");

	if ($antsLastFileName ne $ARGV) {			# signal new file
		$antsLastFileName = $ARGV;
		$antsNewFile = 1;
	} 

	return $#ants_+1;							# ok
}

#----------------------------------------------------------------------

{ my(@ofn);				# output layout				# STATIC SCOPE
  my(@OEparam);			# -F %PARAMs
  my(@OEfield);			# -F fields
  my(@OEexpr);			# -F exprs (compiled)
  my($EOparamsOnly);	# nothing but %PARAMs in -F

  sub antsOut(@)
  {
	my(@out) = @_;
	if (@out == 1 && $out[0] eq "EOF") {
		undef(@ofn); undef(@OEparam); undef(@OEfield); undef(@OEexpr); undef($EOparamsOnly);
		undef($antsHeadersPrinted); undef(@antsOutExprs);
		$antsPadOut = $antsBufNFields = @antsNewLayout;	# NB: MUST BE SET BEFORE &antsOut("EOF");
		return;
	}
	
	# STEP 0: PREPARE STUFF

	@ofn = @antsNewLayout unless (@ofn);			# output layout
	@ofn = @antsLayout unless (@ofn);

	# STEP 1: CONSTRUCT @out IF NEEDED

	unless (@out > 0) {
		for (my($fnr)=0; $fnr<$antsBufNFields; $fnr++) {
       		$out[$fnr] = &antsBufOut($fnr);			# calc; NEEDS RECOMPILE
	    }
	}

	# STEP 2: HANDLE FIELD SELECTION (-F)

	if (@antsOutExprs) {
		
		unless ($antsOutExprsCompiled) {			# parse/compile
			my(@ofn_buf) = @ofn;					# save current output layout
			undef(@ofn);
			
			$OEparamsOnly = 1;
			for (my($if)=my($of)=0; $if<@antsOutExprs; $if++,$of++) {
#				if ($antsOutExprs[$if] =~ m{^%([\w\.]+)$}) {	# %PARAM
				if ($antsOutExprs[$if] =~ m{^%([^=]+)$}) {		# %PARAM
					$ofn[$of] = $1;
					$OEparam[$of] = 1;
	            } elsif ($antsOutExprs[$if] eq \'$@\') {		# all fields
					undef($OEparamsOnly);
	            	for (my($i)=0; $i<@ofn_buf; $i++,$of++) {
	            		$ofn[$of] = $ofn_buf[$i];
	            		$OEfield[$of] = $i;
	            	}
#				} elsif ($antsOutExprs[$if] =~ m{^[\w\.]+$}) { 	# single field
				} elsif ($antsOutExprs[$if] =~ m{^[^=]+$}) { 	# single field
					undef($OEparamsOnly);
					$ofn[$of] = $antsOutExprs[$if];
					$OEfield[$of] = &outFnr($antsOutExprs[$if]);
	            } else {										# expression
					undef($OEparamsOnly);
					my($expr);
	            	($ofn[$of],$expr) = ($antsOutExprs[$if] =~ m{^([^=]*)=(.*)$});
	            	croak("$0: cannot parse -F $antsOutExprs[$if]\n")
	            		unless defined($expr);
	            	my(@tmp) = @antsLayout;
	            	@antsLayout = @ofn_buf;
	            	$OEexpr[$of] = &antsCompileEditExpr($expr,\'$out_buf\');
	            	@antsLayout = @tmp;
	            }
	        }
			$antsOutExprsCompiled = 1;
		}
		
		local(@out_buf) = @out;						# save current output data
		undef(@out);								# accessible from within exprs
		
		for (my($f)=0; $f<@ofn; $f++) {				# create @out according to -F
			if ($OEparam[$f]) {
				$out[$f] = $P{$ofn[$f]};
			} elsif (defined($OEfield[$f])) {
				$out[$f] = $out_buf[$OEfield[$f]];
			} else {
				$out[$f] = &{$OEexpr[$f]};
			}
		}
	}

	# STEP 3: PRINT HEADERS 

	if (@antsNewLayout || @antsOutExprs) {
		&antsPrintHeaders(STDOUT,@ofn);
	} else {
		&antsPrintHeaders(STDOUT);
	}


	# STEP 4: DONE, DUE TO -H RUNNING OUT

	&antsExit() if (defined($opt_H) && ($opt_H-- == 0));


	# STEP 5: PRINT DATA

	$antsPadOut = @ofn if ($antsPadOut >= 0 && @ofn);
	push(@out,nan) while (@out < $antsPadOut);

	my($outStr);
	for (my($fnr)=0; $fnr<=$#out; $fnr++) {
		$out[$fnr] =
			fmtNum($out[$fnr],
				   @antsNewLayout ? $antsNewLayout[$fnr] : $antsLayout[$fnr]);
		$outStr .= (defined($out[$fnr]) && $out[$fnr] ne "" ? $out[$fnr] : nan)
				 . ($fnr == $#out ? $opt_R : $opt_O);
	}
	print($outStr);

	# STEP 6: DONE, DUE TO -F WITH PARAMS ONLY

	&antsExit() if ($OEparamsOnly);
	
  } # antsOut()
} # STATIC SCOPE
    
#----------------------------------------------------------------------

sub antsIO()									# combine input and output
{												# NB: BYPASSES &antsBufOut()!
	my($i);
	for ($i=0; $i<$antsBufSkip && $i<=$#ants_; $i++) {
		&antsOut(@{$ants_[$i]});
	}
	return &antsIn();							# re-fill
}

sub antsPreFlush()								# pre-flush buffer to cur
{
	my($i);
	for ($i=0; $i<=$ants_; $i++) {
		&antsOut(@{$ants_[$i]});
	}
}

sub antsPostFlush()								# post-flush buffer after cur
{
	my($i);
	for ($i=$ants_; $i<=$#ants_; $i++) {
		&antsOut(@{$ants_[$i]});
	}
}

sub antsFlush()									# flush buffer
{
	&antsOut(@{$ants_[0]}),shift(@ants_)
		while ($#ants_ >= 0);
}'; die("antsReCompile: $@\n") if ($@);			# re-compile functions

} # of antsReCompile()

&antsReCompile();								# compile

#----------------------------------------------------------------------

sub antsSetR_($$$)								# set field in any rec
{ my($r,$f,$v) = @_;
	$antsBufNFields = $f+1						# auto extension
		if ($antsBufNFields-1 < $f);
	while ($#{$ants_[$r]} < $f-1) {	
		push(@{$ants_[$r]},nan);
	}
	$ants_[$r][$f] = $v;
}

sub antsSet_($$)								# set field in current rec
{ &antsSetR_($ants_,$_[0],$_[1]); }

#----------------------------------------------------------------------

{ my(%sExprs); # multiple layouts -> multiple compiled -S exprs

sub antsFileIn()								# read from a file
{ 	my($f) = @_;

	REDO:
		return () unless ($_ = <$f>);			# get next record (return EOF)

		goto REDO if /^#/;						# skip comments
		goto REDO if /^\s*$/;					# skip empty lines
		s/^\s+//;								# remove leading spaces
		s/#.*$//;								# remove trailing comments

		local(@in) = split($opt_I);				# needs to be local for -S 

		if (defined($opt_S)) {					# -S)elect
			$sExprs{$f} = &antsCompileAddrExpr($opt_S,'$in')
				unless defined($sExprs{$f});
			goto REDO unless (&{$sExprs{$f}});
		}

		if (@antsNFNames) {						# handle -N)ums
			for (my($i)=0; $i<=$#antsNFNames; $i++) {
				if ($antsNFNames[$i] =~ /^%/) {
					croak("$0: illegal -N option ($antsNFNames[$i] undefined)\n")
						unless (defined($P{$'}));
					goto REDO unless (numberp($P{$'}));
				} else {
					$antsNfnr[$i] = &fnr($antsNFNames[$i]);
					goto REDO unless (numberp($in[$antsNfnr[$i]]));
				}
	        }
		}

		return @in;
}

} # static scope

#======================================================================
# Utilities
#======================================================================

sub antsPrintHeaders($@)						# handle headers
{
	return if ($antsHeadersPrinted);			# do only once
    $antsHeadersPrinted = 1;
	local(*fh,@newLayout) = @_;

	if (@newLayout) {							# check for duplicate field names
		my(%fn);
		for (my($i)=0; $i<=$#newLayout; $i++) {
			next unless defined($newLayout[$i]) && $newLayout[$i] ne '';
			if ($fn{$newLayout[$i]}) {
				&antsInfo("duplicate output field <$newLayout[$i]> changed to <$newLayout[$i]_>");
				$newLayout[$i] .= '_';
				again;
			}
			$fn{$newLayout[$i]} = 1;
		}
	}

	return if ($opt_Q);							# suppress

	if (defined($antsActiveHeader)) {			# activate file
		chmod(0777&~umask,*fh);
		print(fh $antsActiveHeader);
	}
	
	print(fh $antsOldHeaders);					# old headers

	print(fh $antsCurHeader) unless ($opt_X);	# new headers
	print(fh $antsCurParams);
	print(fh $antsCurDeps) unless ($opt_X);
	if (@newLayout) {
		print(fh "#ANTS#FIELDS# ");				
		for (my($i)=0; $i<=$#newLayout; $i++) {
			print(fh "{$newLayout[$i]} ");
		}
		print(fh "\n");
	}
	

}

sub antsExit()
{
	&antsPrintHeaders(STDOUT,@antsNewLayout);
	exit(0);
}

#----------------------------------------------------------------------

# NB: to use antsInfo in expressions, a return value of 1
#	  has been assumed!!!

sub antsInfo(@)									# add info to header & STDERR
{
	return 1 if ($opt_Q);
	my($fmt,@args) = @_;						# can't do it directly!!!
	my($msg) = sprintf($fmt,@args);
	$antsCurHeader .= "#ANTS# $0: $msg\n";
	print(STDERR "$0: $msg\n");
	return 1;
}

#----------------------------------------------------------------------
# %PARAM-related stuff
#----------------------------------------------------------------------

sub antsAddParams(@)							# add params
{
	my($i);	

	$antsCurParams .= "#ANTS#PARAMS#";			# first, create new param spec
	for ($i=0; $i<$#_; $i+=2) {
		my($v) = $_[$i+1];
		$v =~ s/\n/\\n/g;
		$antsCurParams .= " $_[$i]\{$v\}";
	}
	$antsCurParams .= "\n";

	for ($i=0; $i<$#_; $i+=2) {					# then, set (overwrite) param vals
		my($v) = $_[$i+1];
		$v =~ s/\n/\\n/g;
		$P{$_[$i]} = $v;
	}
}

sub antsFileParams()							# get params from file
{
	my($f) = @_;
	my(%P);

	while ($_ = <$f>) {							# get next record
		if (/^#ANTS#PARAMS# ([^\{]+)\{([^\}]*)\}/) {
			do {
				$P{$1} = $2;
				$P{$1} =~ s/^\s*//;				# ensure non-null
			} while ($' =~ m/ ([^\{]+)\{([^\}]*)\}/);
		}
	}
	seek($f,0,0) || croak("$0: $@\n");
	return %P;
}

# antsFileScanParam() only scans the 1st header!!!!
#	empty lines are ok, though

sub antsFileScanParam()							# find param in file
{
	my($f,$pn) = @_;
	my($v1,$v2);

	$pn = $' if ($pn =~ /^%/);					# strip optional leading %

	while ($_ = <$f>) {							# get next record
		last unless (/^#/ || /^\s*$/);
		next unless (/^#ANTS#PARAMS# /);
		$v1 = $1 if (/ $pn\{([^\}]*)\}/);
		$v2 = $1 if (/::$pn\{([^\}]*)\}/);
	}
	seek($f,0,0) || croak("$0: $@\n");
	return defined($v1) ? $v1 : $v2;
}

#----------------------------------------------------------------------
# Layout-related stuff
#----------------------------------------------------------------------

sub antsFileLayout($)							# return layout
{ 	my($f) = @_;
	my(@lo);

	while ($_ = <$f>) {							# get next record
		next unless (/^#ANTS#FIELDS# /);
		@lo = split(' ',$');
	}
	seek($f,0,0) || croak("$0: $@\n");
	for (my($i)=0; $i<=$#lo; $i++) {
		$lo[$i] =~ s/^\{(.*)\}$/$1/;
	}
	return @lo;
}

sub antsFileScanFnr($$)							# find fnr in file
{ 	my($f,$fn) = @_;
	my(@lo) = &antsFileLayout($f);

	for (my($f)=0; $f<=$#lo; $f++) {
		return $f if ($fn eq $lo[$f]);
	}
	return undef;
}

#----------------------------------------------------------------------
# Deps-related stuff
#----------------------------------------------------------------------

sub antsAddDeps(@)								# add Deps
{
	my(@deps) = @_;
	return if $opt_D || (@deps==1 && ($deps[0] eq '-' || $deps[0] eq ''));	# STDIN
	
	$antsCurDeps .= '#ANTS#DEPS#';
	for (my($i)=0; $i<=$#deps; $i++) {
		next if (length($deps[$i]) == 0);
		$antsCurDeps .= " \{$deps[$i]\}";
	}
	$antsCurDeps .= "\n";
}

#======================================================================

1;
