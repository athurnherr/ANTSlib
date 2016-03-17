#!/usr/bin/perl
#======================================================================
#                    A N T S . P L 
#                    doc: Fri Jun 19 14:01:06 1998
#                    dlm: Wed Mar 16 14:08:12 2016
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 20 56 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#  Jun 19, 1998: - apparently created
#  Jul  3, 2006: - added support for ANTS_PERL
#  Jul  5, 2006: - removed `basename`
#  Jul 19, 2006: - added error if exec($ANTS_PERL) fails
#  Sep 24, 2012: - added support for $ANTSLIB
#  Oct 29, 2014: - added $antsLibVersion with compile-time version check (V6.0)
#  May 17, 2015: - updated to V6.1
#  Oct 12, 2015: - updated to V6.2 (for LADCP_w 1.0)
#  Mar  8, 2016: - updated to V6.3 (for LADCP_w 1.2beta)
#  Mar 16, 2016: - updated to V6.4 (for LADCP_w 1.2beta5)

exec($ENV{ANTS_PERL},$0,@ARGV),die("$ENV{ANTS_PERL}: $!")
    if (defined($ENV{ANTS_PERL}) && $^X ne $ENV{ANTS_PERL});

$antsLibVersion = 6.4;

die(sprintf("$0: obsolete library V%.1f; V%.1f required\n",
	$antsLibVersion,$antsMinLibVersion))
		if (!defined($antsMinLibVersion) || $antsMinLibVersion>$antsLibVersion);

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
