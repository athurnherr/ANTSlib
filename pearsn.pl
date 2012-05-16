#======================================================================
#                    P E A R S N . P L 
#                    doc: Wed Mar 24 11:23:29 1999
#                    dlm: Mon Jul 24 15:02:14 2006
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 26 0 NIL 0 0 72 66 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 24, 1999: - created from NR c-version
#	Mar 26, 1999: - cosmetic changes
#	May 23, 1999: - allowed for N==2
#	Oct 04, 1999: - changed from specfuns to funs
#	Oct 13, 1999: - BUG: had to change TINY from 1e-20 to 1e-19
#	Nov 11, 1999: - BUG: had to change TINY from to 1e-16
#	Dec 11, 2001: - BUG: NaNs had not been handled correctly
#	Dec 12, 2001: - BUG: croak() had been used (this produces
#						 a pipe #ERROR# output which is wrong
#						 if pearsn is called within eval as in [fit])
#	Jan  9, 2006: - removed @antsFlagged

require "$ANTS/libfuns.pl";

{											# static scope

my($TINY) = 1e-16;							# for complete correlation

# get correlation coefficient (retval); N (ref); significance level at which 
# null hypothesis of zero correlation is disproved (ref; small value
# indicates significant correlation); and Fisher's z (ref). Missing refs
# indicate values are not returned. Adapted for ANTS.

sub pearsn(@)
{
	my($xfnr,$yfnr,$NR,$pR,$zR) = @_;
	my($n,$r);
	my($j);
	my($yt,$xt,$t,$df);
	my($syy,$sxy,$sxx,$ay,$ax);

	for ($j=0; $j<=$#ants_; $j++) {
		next unless (numberp($ants_[$j][$xfnr]) && numberp($ants_[$j][$yfnr]));
		$n++;
		$ax += $ants_[$j][$xfnr];
		$ay += $ants_[$j][$yfnr];
	}
	die("$0 (pearsn.pl): no data\n") unless ($n >= 2);
	$ax /= $n;
	$ay /= $n;
	for ($j=0; $j<=$#ants_; $j++) {
		next unless (numberp($ants_[$j][$xfnr]) && numberp($ants_[$j][$yfnr]));
		$xt = $ants_[$j][$xfnr] - $ax;
		$yt = $ants_[$j][$yfnr] - $ay;
		$sxx += $xt * $xt;
		$syy += $yt * $yt;
		$sxy += $xt * $yt;
	}
	$r   = $sxy/(sqrt($sxx * $syy) + $TINY);
	$df  = $n - 2;
	$t   = $r * sqrt($df/((1-$r+$TINY) * (1+$r+$TINY)));
	$$NR = $n if (defined($NR));
	$$pR = ($n == 2) ? 0 : &betai(0.5*$df,0.5,$df/($df+$t*$t))
		if (defined($pR));
	$$zR = 0.5 * log((1+$r+$TINY) / (1-$r+$TINY))
		if (defined($zR));
	return $r;
}

}													# end of static scope
