#======================================================================
#                    A N T S F I L T E R S . P L 
#                    doc: Sun Mar 14 15:17:29 1999
#                    dlm: Wed Jan  5 23:34:57 2011
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 15 48 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 14, 1999: - created for filters
#	Dec 11, 1999: - made &antsXCheck() return mean dx
#				  - BUG: dx was calculated independently of from val
#	Mar 31, 2004: - added $fac optional param
#	Jul  1, 2006: - Version 3.3 [HISTORY]
#	Jan  5, 2011: - BUG: did not work for -ve dx

# Implement commonly used fuctions for filters (but not worth including
# into [./antsutils.pl] because of efficiency considerations)

{ my($dx) = 0;										# static vars

sub antsXCheck($$$) # ($xfnr,$from,$to,$fac) -> mean dx	# sanity check on @ants_
{
	my($xfnr,$from,$to,$fac) = @_;
	my($cdx,$r,$sdx);

	$fac = 2 unless defined($fac);

	unless ($dx) {									# find goal dx
		croak("$0: can't handle nan (x field)\n")
			unless (numberp($ants_[0][$xfnr]) && numberp($ants_[1][$xfnr]));
		$dx = $ants_[$from+1][$xfnr] - $ants_[$from][$xfnr];
	}
	for ($r=$from+1; $r <= $to; $r++) {
		croak("$0: can't handle $ants_[$r][$xfnr] (x field)\n")
			unless (numberp($ants_[$r][$xfnr]));
		$cdx = $ants_[$r][$xfnr] - $ants_[$r-1][$xfnr];
		croak("$0: input badly non-uniformly spaced " .
			"(rec# $r is $ants_[$r][$xfnr]; previous is $ants_[$r-1][$xfnr];" .
			" target difference is $dx)\n")
			if (($dx > 0) && ($cdx > $fac*$dx || $cdx < $dx/$fac)) ||
			   (($dx < 0) && ($cdx < $fac*$dx || $cdx > $dx/$fac));
		$sdx += $cdx;
	}
	return $sdx/($to-$from);
}

} # end of $dx static scope

1;
