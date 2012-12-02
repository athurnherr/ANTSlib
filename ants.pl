#!/usr/bin/perl
#======================================================================
#                    A N T S . P L 
#                    doc: Fri Jun 19 14:01:06 1998
#                    dlm: Mon Sep 24 12:41:50 2012
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 25 76 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#  Jun 19, 1998: - apparently created
#  Jul  3, 2006: - added support for ANTS_PERL
#  Jul  5, 2006: - removed `basename`
#  Jul 19, 2006: - added error if exec($ANTS_PERL) fails
#  Sep 24, 2012: - added support for $ANTSLIB

exec($ENV{ANTS_PERL},$0,@ARGV),die("$ENV{ANTS_PERL}: $!")
    if (defined($ENV{ANTS_PERL}) && $^X ne $ENV{ANTS_PERL});

if (defined($ANTSLIB)) {							# new style (V5)
	require "$ANTSLIB/antsusage.pl";
	require "$ANTSLIB/antsio.pl";
	require "$ANTSLIB/antsutils.pl";
	require "$ANTSLIB/antsexprs.pl";
	$ANTS = $ANTSLIB;								# backward compatibility
} elsif (defined($ANTS)) {							# old style
	require "$ANTS/antsusage.pl";
	require "$ANTS/antsio.pl";
	require "$ANTS/antsutils.pl";
	require "$ANTS/antsexprs.pl";
} else {
	die("neither \$ANTS nor \$ANTSLIB defined\n");
}

1;
