#======================================================================
#                    P O L I N T . P L 
#                    doc: Thu Nov 23 20:38:46 2000
#                    dlm: Tue Aug  5 14:06:31 2008
#                    (c) 2000 A.M. Thurnherr
#                    uE-Info: 17 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# 2nd edition NR polint.c adapted to ANTS

# HISTORY:
#	Nov 23, 2000: - created for [.interp.poly]
#	Jan 12, 2006: - BUG: higher-order polynomials could not be used
#						 to interpolate linear function
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#	Jul 28, 2006: - cosmetics
#	Aug  5, 2008: - BUG: [.interp.poly] takes data from ref, not @ants_

# NOTES:
#	- &vector()-allocated arrays are numbered from 1
#	- (nan,nan) is returned on non-numeric required @ants_ values
#	- in contrast to the NR routine, the error value returned is +ve

require "$ANTS/nrutil.pl";

sub polint($$$$$$)								# ($y,$dy) = &polint(...)
{
	my($dR,$xf,$xv,$ti,$n,$yf) = @_;
	my($y,$dy);

	my($i,$m); my($ns) = 1;
	my($den,$dif,$dift,$ho,$hp,$w);
	my(@c,@d);

	for ($i=0; $i<$n; $i++) {					# check for nans
		return (nan,nan)
			unless (numberp($dR->[$ti+$i][$xf]) &&
					numberp($dR->[$ti+$i][$yf]));
	}

	$dif = abs($xv - $dR->[$ti][$xf]);
	&vector(\@c,1,$n);
	&vector(\@d,1,$n);
	for ($i=1; $i<=$n; $i++) {
		$dift = abs($xv - $dR->[$ti+$i-1][$xf]);
		if ($dift < $dif) {
			$ns  = $i;
			$dif = $dift;
		}
		$c[$i] = $dR->[$ti+$i-1][$yf];
		$d[$i] = $dR->[$ti+$i-1][$yf];
	}
	$y = $dR->[$ti+$ns---1][$yf];				# WHAT A CONSTRUCT :-)
	for ($m=1; $m<$n; $m++) {
		for ($i=1; $i<=$n-$m; $i++) {
			$ho  = $dR->[$ti+$i-1][$xf] - $xv;
			$hp  = $dR->[$ti+$i+$m-1][$xf] - $xv;
			$w   = $c[$i+1] - $d[$i];
			$den = $ho - $hp;
### The following two lines of code are the original, which makes polint
### fail when interpolating a linear function with a higher-order polynomial,
### as is done in [ubtest/resample.TF]. 
###			croak("$0 (polint.pl): ERROR!") if ($den == 0);
###			$den   = $w / $den;
### The following line of code is the replacement that solves the bug.
			$den   = $w / $den unless ($den == 0);
			$d[$i] = $hp * $den;
			$c[$i] = $ho * $den;
		}
		$dy = (2*$ns < ($n-$m)) ? $c[$ns+1] : $d[$ns--];
		$y += $dy;
	}
	return ($y,abs($dy));
}

1;
