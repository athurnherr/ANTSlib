#======================================================================
#                    . / S V D F I T . P L 
#                    doc: Sat Jul 31 22:09:25 1999
#                    dlm: Sat Jul 31 22:45:40 1999
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 61 36 NIL 0 0 72 2 2 4 ofnI
#======================================================================

# SVDFIT routine from Numerical Recipes adapted to ANTS

# HISTORY:
#	Jul 31, 1999: - manually converted from c-source

# Notes:
#   - x,y,sig are field numbers for data in $ants_
#   - if sig is a negative number, -sig is used as constant input stddev
#   - @a, @u, @v, @w, &funcs passed as refs
#	- chi square is returned

require "$ANTS/nrutil.pl";
require "$ANTS/svbksb.pl";
require "$ANTS/svdcmp.pl";

{ # BEGIN static scope

my($TOL) = 1.0e-5;

sub svdfit($$$$$$$$)
{
	my($xfnr,$yfnr,$sig,$aR,$uR,$vR,$wR,$funcsR) = @_;
	my($j,$i);										# int
	my($chisq,$wmax,$tmp,$thresh,$sum);					# float
	my(@b,@afunc);									# float[]

	&vector(\@b,1,$#ants_);
	&vector(\@afunc,1,$#{$aR});
	for ($i=0; $i<=$#ants_; $i++) {
		next if ($antsFlagged[$i]);
		&$funcsR($ants_[$i][$xfnr],\@afunc);
		$tmp = 1.0 / (($sig > 0) ? $ants_[$i][$sig] : -$sig);
		for ($j=1; $j<=$#{$aR}; $j++) {
			$uR->[$i][$j] = $afunc[$j]*$tmp;
		}
		$b[$i] = $ants_[$i][$yfnr]*$tmp;
	}
	&svdcmp($uR,$wR,$vR);
	for ($j=1; $j<=$#{$aR}; $j++) {
		$wmax = $wR->[$j] if ($wR->[$j] > $wmax);
	}
	$thresh = $TOL*$wmax;
	for ($j=1; $j<=$#{$aR}; $j++) {
		$wR->[$j] = 0 if ($wR->[$j] < $thresh);
	}
	&svbksb($uR,$wR,$vR,\@b,$aR);
	for ($i=0; $i<=$#ants_; $i++) {
		next if ($antsFlagged[$i]);
		&$funcsR($ants_[$i][$xfnr],\@afunc);
		for ($j=1; $j<=$#{$aR}; $j++) {
			$sum += $aR->[$j]*$afunc[$j];
		}
		$tmp = ($ants_[$i][$yfnr] - $sum) /
				(($sig > 0) ? $ants_[$i][$sig] : -$sig);
		$chisq += $tmp * $tmp;
	}
	return $chisq;
}

} # END static scope
