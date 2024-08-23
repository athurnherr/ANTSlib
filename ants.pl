#!/usr/bin/perl
#======================================================================
#                    A N T S . P L 
#                    doc: Fri Jun 19 14:01:06 1998
#                    dlm: Fri Aug 23 12:37:30 2024
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 37 21 NIL 0 0 72 2 2 4 NIL ofnI
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
#  Mar 17, 2016: - updated to V6.5
#  Mar 29, 2016: - updated to V6.6
#  Aug  5, 2016: - updated to V6.7
#  Mar 12, 2017: - updated to V6.8 (for LADCP_w 1.3 release)
#  Nov 20, 2017: - updated to V6.9 (for DT KVH software)
#  Dec  8, 2017: - updated to V7.0 (to avoid absolute-path symlink)
#  Nov 27, 2018: - updated to V7.1 (for LADCP_w 1.4 release)
#  Apr 13, 2020: - updated to V7.2 (for MIMP_tools)
#  Jul  1, 2021: - updated to V7.3 because of a bug
#  Jul  6, 2022: - updated to V7.4 because of libIMP improvements
#  Dec  6, 2022: - updated to V7.5 for release of LADCP_w V2.2
#  Aug 23, 2024: - updated to V7.6 for GitHUB release

exec($ENV{ANTS_PERL},$0,@ARGV),die("$ENV{ANTS_PERL}: $!")
    if (defined($ENV{ANTS_PERL}) && $^X ne $ENV{ANTS_PERL});

$antsLibVersion = 7.6;

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
