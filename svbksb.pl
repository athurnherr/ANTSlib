#======================================================================
#                    . / S V B K S B . P L 
#                    doc: Sat Jul 31 22:47:03 1999
#                    dlm: Sat Jul 31 23:06:40 1999
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 30 32 NIL 0 0 72 2 2 4 ofnI
#======================================================================

# SVBKSB routine from Numerical Recipes adapted to ANTS

# HISTORY:
#	Jul 31, 1999: - manually converted from c-source

# Notes:
#   - everything passed as refs

require "$ANTS/nrutil.pl";

sub svbksb($$$$$)
{
	my($uR,$wR,$vR,$bR,$xR) = @_;
	my($jj,$j,$i);									# int
	my($s);										# float
	my(@tmp);									# float[]

	&vector(\@tmp,1,$#{$wR});
	for ($j=1; $j<=$#{$wR}; $j++) {
		$s = 0;
		if ($wR->[$j]) {
			for ($i=1; $i<=$#{$uR}; $i++) {
				$s += $uR->[$i][$j] * $bR->[$i];
			}
			$s /= $wR->[$j];
		}
		$tmp[$j]=$s;
	}
	for ($j=1; $j<=$#{$wR}; $j++) {
		$s = 0;
		for ($jj=1; $jj<=$#{$wR}; $jj++) {
			$s += $vR->[$j][$jj] * tmp[$jj];
		}
		$x->[$j] = $s;
	}
}


