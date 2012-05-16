#======================================================================
#                    S V D C M P . P L 
#                    doc: Sun Aug  1 09:51:37 1999
#                    dlm: Thu Jul 19 09:45:52 2001
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 184 18 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# SVDCMP routine from Numerical Recipes adapted to ANTS

# HISTORY:
#	Aug 01, 1999: - manually converted from c-source

# Notes:
#   - everything passed as refs

require "$ANTS/nrutil.pl";
require "$ANTS/pythag.pl";

sub svdcmp($$$)
{
	my($aR,$wR,$vR) = @_;							# params
	my($flag,$i,$its,$j,$jj,$k,$l,$nm);				# int 
	my($anorm,$c,$f,$g,$h,$s,$scale,$x,$y,$z);		# float
	my(@rv1);										# float[]

	vector(\@rv1,1,$#{$vR});
	for ($i=1; $i<=$#{$vR}; $i++) {
		$l = $i+1;
		$rv1[$i] = $scale*$g;
		$g = 0; $s = 0; $scale = 0;
		if ($i <= $#{$aR}) {
			for ($k=$i; $k<=$#{$aR}; $k++) {
				$scale += abs($aR->[$k][$i]);
			}
			if ($scale) {
				for ($k=$i; $k<=$#{$aR}; $k++) {
					$aR->[$k][$i] /= $scale;
					$s += $aR->[$k][$i]*$aR->[$k][$i];
				}
				$f = $aR->[$i][$i];
				$g = -&SIGN(sqrt($s),$f);
				$h = $f*$g-$s;
				$aR->[$i][$i] = $f-$g;
				for ($j=$l; $j<=$#{$vR}; $j++) {
					for ($s=0,$k=$i; $k<=$#{$aR}; $k++) {
						$s += $aR->[$k][$i]*$aR->[$k][$j];
					}
					$f = $s/$h;
					for ($k=$i; $k<=$#{$aR}; $k++) {
						$aR->[$k][$j] += $f*$aR->[$k][$i];
					}
				}
				for ($k=$i; $k<=$#{$aR}; $k++) {
					$aR->[$k][$i] *= $scale;
				}
			}
		}
		$wR->[$i] = $scale * $g;
		$g = 0; $s = 0; $scale = 0;
		if ($i <= $#{$aR} && $i != $#{$vR}) {
			for ($k=$l; $k<=$#{$vR}; $k++) {
				$scale += abs($aR->[$i][$k]);
			}
			if ($scale) {
				for ($k=$l; $k<=$#{$vR}; $k++) {
					$aR->[$i][$k] /= $scale;
					$s += $aR->[$i][$k]*$aR->[$i][$k];
				}
				$f = $aR->[$i][$l];
				$g = -&SIGN(sqrt($s),$f);
				$h = $f*$g-$s;
				$aR->[$i][$l] = $f-$g;
				for ($k=$l; $k<=$#{$vR}; $k++) {
					$rv1[$k] = $aR->[$i][$k]/$h;
				}
				for ($j=$l; $j<=$#{$aR}; $j++) {
					for ($s=0,$k=$l; $k<=$#{$vR}; $k++) {
						$s += $aR->[$j][$k]*$aR->[$i][$k];
					}
					for ($k=$l; $k<=$#{$vR}; $k++) {
						$aR->[$j][$k] += $s*$rv1[$k];
					}
				}
				for ($k=$l; $k<=$#{$vR}; $k++) {
					$aR->[$i][$k] *= $scale;
				}
			}
		}
		$anorm = &FMAX($anorm,(abs($wR->[$i])+abs($rv1[$i])));
	}
	for ($i=$#{$vR}; $i>=1; $i--) {
		if ($i < $#{$vR}) {
			if ($g) {
				for ($j=$l; $j<=$#{$vR}; $j++) {
					$vR->[$j][$i] = ($aR->[$i][$j]/$aR->[$i][$l])/$g;
				}
				for ($j=$l; $j<=$#{$vR}; $j++) {
					for ($s=0,$k=$l; $k<=$#{$vR}; $k++) {
						$s += $aR->[$i][$k]*$vR->[$k][$j];
					}
					for ($k=$l; $k<=$#{$vR}; $k++) {
						$vR->[$k][$j] += $s*$vR->[$k][$i];
					}
				}
			}
			for ($j=$l; $j<=$#{$vR; $j++) {
				$vR->[$i][$j] = 0; $vR->[$j][$i] = 0;
			}
		}
		$vR->[$i][$i] = 1;
		$g = $rv1[$i];
		$l = $i;
	}
	for ($i=IMIN($#{$aR},$#{$vR}); $i>=1; $i--) {
		$l = $i+1;
		$g = $wR->[$i];
		for ($j=$l; $j<=$#{$vR}; $j++) {
			$aR->[$i][$j] = 0;
		}
		if ($g) {
			$g = 1/$g;
			for ($j=$l; $j<=$#{$vR}; $j++) {
				for ($s=0,$k=$l; $k<=$#{$aR}; $k++) {
					$s += $aR->[$k][$i]*$aR->[$k][$j];
				}
				$f = ($s/$aR->[$i][$i])*$g;
				for ($k=$i; $k<=$#{$aR}; $k++) {
					$aR->[$k][$j] += $f*$aR->[$k][$i];
				}
			}
			for ($j=$i; $j<=$#{$aR}; $j++) {
				$aR->[$j][$i] *= $g;
			}
		} else {
			for ($j=$i; $j<=$#{$aR}; $j++) {
				$aR->[$j][$i] = 0;
			}
		}
		++$aR->[$i][$i];
	}
	for ($k=$#{$vR}; $k>=1; $k--) {
		for ($its=1; $its<=30; $its++) {
			$flag = 1;
			for ($l=$k; $l>=1; $l--) {
				$nm = $l-1;
				if ((abs($rv1[$l])+$anorm) == $anorm) {
					$flag = 0;
					break;
				}
				break if ((abs($wR->[$nm])+$anorm) == $anorm);
			}
			if ($flag) {
				$c = 0;
				$s = 1;
				for ($i=$l; $i<=$k; $i++) {
					$f = $s*$rv1[$i];
					$rv1[$i] = $c*$rv1[$i];
					break if ((abs($f)+$anorm) == $anorm);
					$g = $wR->[$i];
					$h = &pythag($f,$g);
					$wR->[$i] = $h;
					$h = 1/$h;
					$c = $g*$h;
					$s = -$f*$h;
					for ($j=1; $j<=$#{$aR}; $j++) {
						$y = $aR->[$j][$nm];
						$z = $aR->[$j][$i];
						$aR->[$j][$nm] = $y*$c+$z*$s;
						$aR->[$j][$i] = $z*$c-$y*$s;
					}
				}
			}
			$z = $wR->[$k];
			if ($l == $k) {
				if ($z < 0) {
					$wR->[$k] = -$z;
					for ($j=1; $j<=$#{$vR}; $j++) {
						$vR->[$j][$k] = -$vR->[$j][$k];
					}
				}
				break;
			}
			croak("no convergence in 30 svdcmp iterations\n") if ($its == 30);
			$x = $wR->[$l];
			$nm = $k-1;
			$y = $wR->[$nm];
			$g = $rv1[$nm];
			$h = $rv1[$k];
			$f = (($y-$z)*($y+$z)+($g-$h)*($g+$h))/(2.0*$h*$y);
			$g = &pythag($f,1);
			$f = (($x-$z)*($x+$z)+$h*(($y/($f+&SIGN($g,$f)))-$h))/$x;
			$c = 1; $s = 1;
			for ($j=$l; $j<=$nm; $j++) {
				$i = $j+1;
				$g = $rv1[$i];
				$y = $wR->[$i];
				$h = $s*$g;
				$g = $c*$g;
				$z = &pythag($f,$h);
				$rv1[$j] = $z;
				$c = $f/$z;
				$s = $h/$z;
				$f = $x*$c+$g*$s;
				$g = $g*$c-$x*$s;
				$h = $y*$s;
				$y *= $c;
				for ($jj=1; $jj<=$#{$vR}; $jj++) {
					$x = $vR->[$jj][$j];
					$z = $vR->[$jj][$i];
					$vR->[$jj][$j] = $x*$c+$z*$s;
					$vR->[$jj][$i] = $z*$c-$x*$s;
				}
				$z = &pythag($f,$h);
				$wR->[$j] = $z;
				if ($z) {
					$z = 1/$z;
					$c = $f*$z;
					$s = $h*$z;
				}
				$f = $c*$g+$s*$y;
				$x = $c*$y-$s*$g;
				for ($jj=1; $jj<=$#{$aR}; $jj++) {
					$y = $aR->[$jj][$j];
					$z = $aR->[$jj][$i];
					$aR->[$jj][$j] = $y*$c+$z*$s;
					$aR->[$jj][$i] = $z*$c-$y*$s;
				}
			}
			$rv1[$l] = 0;
			$rv1[$k] = $f;
			$wR->[$k] = $x;
		}
	}
}


