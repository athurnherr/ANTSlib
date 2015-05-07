#======================================================================
#                    L I B S V D . P L 
#                    doc: Sat Jul 31 22:47:03 1999
#                    dlm: Fri Mar 13 20:53:26 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 305 1 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jul 31, 1999: - created
#	Jul 19, 2001: - done *something* (message only?)
#	Mar 11, 2015: - fixed syntax errors (code had never been used before)
#	Mar 13, 2015: - combined from [sbbksb.pl] [svdcmp.pl] [pythag.pl] [svdfit.pl]

require "$ANTS/nrutil.pl";
use strict;

#----------------------------------------------------------------------
# SVBKSB routine from Numerical Recipes adapted to ANTS
#
#	solves Ax = b for x, given b
#
#	Notes:
#		- A = U W V' as done in [svdcmp.pl]
#----------------------------------------------------------------------

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
			$s += $vR->[$j][$jj] * $tmp[$jj];
		}
		$xR->[$j] = $s;
	}
}

#----------------------------------------------------------------------
# PYTHAG routine
#----------------------------------------------------------------------

sub pythag($$)
{
	my($a,$b) = @_;							# params
	my($absa,$absb);						# float 

	$absa = abs($a);
	$absb = abs($b);
	return $absa*sqrt(1.0+SQR($absb/$absa))
		if ($absa > $absb);
	return ($absb == 0 ? 0 : $absb*sqrt(1+$absa*$absa/$absb/$absb));
}


#----------------------------------------------------------------------
# SVDCMP routine from Numerical Recipes adapted to ANTS
#----------------------------------------------------------------------

sub svdcmp($$$)
{	
	my($aR,$wR,$vR) = @_;							# params
	my($flag,$i,$its,$j,$jj,$k,$l,$nm);				# int 
	my($anorm,$c,$f,$g,$h,$s,$scale,$x,$y,$z);		# float
	my(@rv1);										# float[]

	vector(\@rv1,1,$#{$vR});
	$g = $scale = $anorm = 0;
	for ($i=1; $i<=$#{$vR}; $i++) {
		$l = $i+1;
		$rv1[$i] = $scale*$g;
		$g = $s = $scale = 0;
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
		$anorm = MAX($anorm,(abs($wR->[$i])+abs($rv1[$i])));
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
			for ($j=$l; $j<=$#{$vR}; $j++) {
				$vR->[$i][$j] = 0; $vR->[$j][$i] = 0;
			}
		}
		$vR->[$i][$i] = 1;
		$g = $rv1[$i];
		$l = $i;
	}
	for ($i=MIN($#{$aR},$#{$vR}); $i>=1; $i--) {
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
					last;
				}
				last if ($nm == 0) || ((abs($wR->[$nm])+$anorm) == $anorm);	## $nm == 0 test not in original code
			}
			if ($flag) {
				$c = 0;
				$s = 1;
				for ($i=$l; $i<=$k; $i++) {
					$f = $s*$rv1[$i];
					$rv1[$i] = $c*$rv1[$i];
					last if ((abs($f)+$anorm) == $anorm);
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
#				print(STDERR "its($k) = $its\n");
				last;
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

#----------------------------------------------------------------------
# SVDFIT routine from Numerical Recipes adapted to ANTS
#
# UNTESTED CODE!!!!!
#
# Notes:
#   - x,y,sig are field numbers for data in $ants_
#   - if sig is a negative number, -sig is used as constant input stddev
#   - @a, @u, @v, @w, &funcs passed as refs
#	- chi square is returned
#----------------------------------------------------------------------
#
#{ # BEGIN static scope
#
#my($TOL) = 1.0e-5;
#
#sub svdfit($$$$$$$$)
#{
#	die("untested code");
#	my($xfnr,$yfnr,$sig,$aR,$uR,$vR,$wR,$funcsR) = @_;
#	my($j,$i);										# int
#	my($chisq,$wmax,$tmp,$thresh,$sum);					# float
#	my(@b,@afunc);									# float[]
#
#	&vector(\@b,1,$#ants_);
#	&vector(\@afunc,1,$#{$aR});
#	for ($i=0; $i<=$#ants_; $i++) {
#		next if ($antsFlagged[$i]);
#		&$funcsR($ants_[$i][$xfnr],\@afunc);
#		$tmp = 1.0 / (($sig > 0) ? $ants_[$i][$sig] : -$sig);
#		for ($j=1; $j<=$#{$aR}; $j++) {
#			$uR->[$i][$j] = $afunc[$j]*$tmp;
#		}
#		$b[$i] = $ants_[$i][$yfnr]*$tmp;
#	}
#	&svdcmp($uR,$wR,$vR);
#	for ($j=1; $j<=$#{$aR}; $j++) {
#		$wmax = $wR->[$j] if ($wR->[$j] > $wmax);
#	}
#	$thresh = $TOL*$wmax;
#	for ($j=1; $j<=$#{$aR}; $j++) {
#		$wR->[$j] = 0 if ($wR->[$j] < $thresh);
#	}
#	&svbksb($uR,$wR,$vR,\@b,$aR);
#	for ($i=0; $i<=$#ants_; $i++) {
#		next if ($antsFlagged[$i]);
#		&$funcsR($ants_[$i][$xfnr],\@afunc);
#		for ($j=1; $j<=$#{$aR}; $j++) {
#			$sum += $aR->[$j]*$afunc[$j];
#		}
#		$tmp = ($ants_[$i][$yfnr] - $sum) /
#				(($sig > 0) ? $ants_[$i][$sig] : -$sig);
#		$chisq += $tmp * $tmp;
#	}
#	return $chisq;
#}
#
#} # END static scope

1;
