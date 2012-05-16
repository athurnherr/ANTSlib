#!/usr/bin/perl
#======================================================================
#                    A N T S . P L 
#                    doc: Fri Jun 19 14:01:06 1998
#                    dlm: Wed Jul  5 15:37:12 2006
#                    (c) 1998 A.M. Thurnherr
#                    uE-Info: 18 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#  Jun 19, 1998: - apparently created
#  Jul  3, 2006: - added support for ANTS_PERL
#  Jul  5, 2006: - removed `basename`
#  Jul 19, 2006: - added error if exec($ANTS_PERL) fails

exec($ENV{ANTS_PERL},$0,@ARGV),die("$ENV{ANTS_PERL}: $!")
    if (defined($ENV{ANTS_PERL}) && $^X ne $ENV{ANTS_PERL});

($ANTS) = ($0 =~ m{^(.*)/[^/]*$}) unless defined($ANTS);
	
require "$ANTS/antsusage.pl";
require "$ANTS/antsio.pl";
require "$ANTS/antsutils.pl";
require "$ANTS/antsexprs.pl";

1;
