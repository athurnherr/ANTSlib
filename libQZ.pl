#======================================================================
#                    L I B Q Z . P L 
#                    doc: Thu Mar 12 15:23:15 2015
#                    dlm: Sun Mar 15 19:26:50 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 14 27 NIL 0 0 72 10 2 4 NIL ofnI
#======================================================================

# adaptation of EISPACK routines
# www.netlib.org/eispack

# HISTORY:
# Mar 12, 2015: - created
# Mar 15, 2015: - debugging

use strict vars;

my($N);												# size of input matrices A & B

#----------------------------------------------------------------------
# eig(\@A,\@B,\@evRe,\@evIm,\@V)
#	- @ev{Re,Im} contain generalized eigenvalues
#	- @evec contains corresponding right eigenvectors
#	- A*V = B*V*D, where D is diagonal matrix of eigenvalues
#----------------------------------------------------------------------

sub eig($$$$$)
{
	my($aR,$bR,$erR,$eiR,$zR) = @_;					# args passed as refs
	my(@alphaR,@alphaI,@beta);						# intermediate data

	$N = scalar(@{$aR});
	croak(sprintf("eig(A,B): A(%dx%d) & B(%dx%d) must be matching square matrices\n",
						$N,scalar(@{$aR->[0]}),scalar(@{$bR}),scalar(@{$bR->[0]})))
		unless (@{$bR} == $N) && (@{$aR->[0]} == $N) && (@{$bR->[0]} == $N);

	QZhes($aR,$bR,$zR);								# reduce A/B to upper Hessenberg/triangular forms
	croak("QZit(): convergence failed\n")
		unless (QZit($aR,$bR,$zR) == 0);			# reduce Hess A to quasi-triangular form
	QZval($aR,$bR,$zR,\@alphaR,\@alphaI,\@beta);	# reduce A further
	QZvec($aR,$bR,$zR,\@alphaR,\@alphaI,\@beta);	# compute eigenvectors & eigenvalues

	for (my($i)=0; $i<$N; $i++) {
		if ($beta[$i]==0 && $alphaR[$i]==0) {
			$erR->[$i] = nan;
			$eiR->[$i] = nan;
		} else {
			$erR->[$i] = $alphaR[$i] / $beta[$i];
			$eiR->[$i] = $alphaI[$i] / $beta[$i];
#			print(STDERR "gev[$i] = $erR->[$i]\n");
		}
	}
}

#----------------------------------------------------------------------
# EISPACK routines
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# QZhes(\@A,\@B,\@Z)
#	- first step in QZ algorithm (Moler & Stewart, SIAM JNA, 1973)
#----------------------------------------------------------------------

sub QZhes($$$)
{
	my($aR,$bR,$zR) = @_;
	my($i,$j,$k,$l,$l1,$lb,$nk1);	
	my($r,$s,$t,$u1,$u2,$v1,$v2,$rho);

	croak("QZhes: need at least 3x3 matrices\n")
		unless ($N >= 2);

	for ($j=0; $j<$N; $j++) {						# init Z to identity matrix
		for ($i=0; $i<$N; $i++) {
			$zR->[$i][$j] = 0;
		}
		$zR->[$j][$j] = 1;
    }

	for ($l=0; $l<$N-1; $l++) {
		$l1 = $l + 1;
		for ($s=0,$i=$l1; $i<$N; $i++) {
			$s += abs($bR->[$i][$l]);
		}
		next if ($s == 0);
		$s += abs($bR->[$l][$l]);

		for ($r=0,$i=$l; $i<$N; $i++)
		{
			$bR->[$i][$l] /= $s;
			$r += $bR->[$i][$l]**2;
		}
	
		$r = SIGN(sqrt($r),$bR->[$l][$l]);
		$bR->[$l][$l] += $r;
		$rho = $r * $bR->[$l][$l];
	
		for ($j=$l1; $j<$N; $j++) {
			for ($t=0,$i=$l; $i<$N; $i++) {
				$t += $bR->[$i][$l] * $bR->[$i][$j];
			}
			$t = -$t / $rho;
			for ($i=$l; $i<$N; $i++) {
				$bR->[$i][$j] += $t * $bR->[$i][$l];
			}
		}
	
		for ($j=0; $j<$N; $j++) {
			for ($t=0,$i=$l; $i<$N; $i++) {
				$t += $bR->[$i][$l] * $aR->[$i][$j];
			}
			$t = -$t / $rho;
			for ($i=$l; $i<$N; $i++) {
				$aR->[$i][$j] += $t * $bR->[$i][$l];
			}
		}
	
		$bR->[$l][$l] = -$s * $r;
		for ($i=$l1; $i<$N; $i++) {
			$bR->[$i][$l] = 0;
		}
	}

	for ($k=0; $k<$N-2; $k++) {
		$nk1 = $N - 2 - $k;

		for ($lb=0; $lb<$nk1; $lb++) {
			$l = $N - $lb - 2;
			$l1 = $l + 1;

			$s = (abs($aR->[$l][$k])) + (abs($aR->[$l1][$k]));
			next if ($s == 0);
			
			$u1 = $aR->[$l][$k] / $s;
			$u2 = $aR->[$l1][$k] / $s;
			$r = SIGN(sqrt($u1**2+$u2**2),$u1);
			$v1 = -($u1 + $r) / $r;
			$v2 = -$u2 / $r;
			$u2 = $v2 / $v1;
	
			for ($j=$k; $j<$N; $j++) {
				$t = $aR->[$l][$j] + $u2 * $aR->[$l1][$j];
				$aR->[$l][$j] += $t * $v1;
				$aR->[$l1][$j] += $t * $v2;
			}
	
			$aR->[$l1][$k] = 0;
	
			for ($j=$l; $j<$N; $j++) {
				$t = $bR->[$l][$j] + $u2 * $bR->[$l1][$j];
				$bR->[$l][$j] += $t * $v1;
				$bR->[$l1][$j] += $t * $v2;
			}
	
			$s = (abs($bR->[$l1][$l1])) + (abs($bR->[$l1][$l]));
			next if ($s == 0);
			
			$u1 = $bR->[$l1][$l1] / $s;
			$u2 = $bR->[$l1][$l] / $s;
			$r = SIGN(sqrt($u1**2 + $u2**2),$u1);
			$v1 = -($u1 + $r) / $r;
			$v2 = -$u2 / $r;
			$u2 = $v2 / $v1;
	
			for ($i=0; $i<=$l1; $i++) {						# overwrite B with upper triangular form
				$t = $bR->[$i][$l1] + $u2 * $bR->[$i][$l];
				$bR->[$i][$l1] += $t * $v1;
				$bR->[$i][$l] += $t * $v2;
			}
			$bR->[$l1][$l] = 0;
	
			for ($i=0; $i<$N; $i++) {						# overwrite A with upper Hessenberg form
				$t = $aR->[$i][$l1] + $u2 * $aR->[$i][$l];
				$aR->[$i][$l1] += $t * $v1;
				$aR->[$i][$l] += $t * $v2;
			}
	
			for ($i=0; $i<$N; $i++) {						# define matrix Z, used for eigenvectors
				$t = $zR->[$i][$l1] + $u2 * $zR->[$i][$l];
				$zR->[$i][$l1] += $t * $v1;
				$zR->[$i][$l] += $t * $v2;
			}
		} # for ($lb=0; $lb<$nk1; $lb++)
	} # for ($k=0; $k<$N-2; $k++)
}

#----------------------------------------------------------------------
# QZit(\@A,\@B,\@Z)
#	- second step in QZ algorithm (Moler & Stewart, SIAM JNA, 1973)
#	- !0 return value indicates that convergence failed
#----------------------------------------------------------------------

sub QZit($$$$)
{
	my($aR,$bR,$zR) = @_;

	my($i,$j,$k);
	my($r,$s,$t,$a1,$a2);
	my($k1,$k2,$l1,$ll);
	my($u1,$u2,$u3);
	my($v1,$v2,$v3);
	my($a11,$a12,$a21,$a22,$a33,$a34,$a43,$a44);
	my($b11,$b12,$b22,$b33,$b34,$b44);
	my($na,$en,$ld);
	my($ep,$km1,$ani,$bni);
	my($ish,$itn,$its,$enm2,$lor1,$epsa,$epsb,$enorn,$notlas);
	my($l,$a3,$sh,$lm1,$anorm,$bnorm) = (0,0,0,0,0,0);

	for ($i=0; $i<$N; $i++) {
		$ani = $bni = 0;
		$ani = abs($aR->[$i][$i-1])
			unless ($i == 0);
		for ($j=$i; $j<$N; $j++) {
			$ani += abs($aR->[$i][$j]);
			$bni += abs($bR->[$i][$j]);
		}
		$anorm = $ani if ($ani > $anorm);
		$bnorm = $bni if ($bni > $bnorm);
	}
	$anorm = 1 if ($anorm == 0);
	$bnorm = 1 if ($bnorm == 0);

	$ep = 1.11022302462516e-16;	# $EPS=1; $EPS /= 2 while 0.5 + $EPS/2 > 0.5;
	$epsa = $ep * $anorm;
	$epsb = $ep * $bnorm;

	$lor1 = 0;
	$enorn = $N;
	$en = $N - 1;
	$itn = $N * 30;

L60:
	goto L1001 if ($en <= 1);
	$its = 0;
	$na = $en - 1;
	$enm2 = $na;

L70:
	$ish = 2;
	for ($ll=0; $ll<=$en; $ll++) {
		$lm1 = $en - $ll - 1;
		$l = $lm1 + 1;
		goto L95 if ($l == 0);
		last if ((abs($aR->[$l][$lm1])) <= $epsa)
	}

L90:
	$aR->[$l][$lm1] = 0;
	goto L95 if ($l < $na);
	$en = $lm1;
	goto L60;

L95:
	$ld = $l;

L100:
	$l1 = $l + 1;
	$b11 = $bR->[$l][$l];
	goto L120 if (abs($b11) > $epsb);
	$bR->[$l][$l] = 0;
	$s = (abs($aR->[$l][$l]) + abs($aR->[$l1][$l]));
	$u1 = $aR->[$l][$l] / $s;
	$u2 = $aR->[$l1][$l] / $s;
	$r = SIGN(sqrt($u1**2 + $u2**2),$u1);
	$v1 = -($u1 + $r) / $r;
	$v2 = -$u2 / $r;
	$u2 = $v2 / $v1;

	for ($j=$l; $j<$enorn; $j++) {
		$t = $aR->[$l][$j] + $u2 * $aR->[$l1][$j];
		$aR->[$l][$j] += $t * $v1;
		$aR->[$l1][$j] += $t * $v2;

		$t = $bR->[$l][$j] + $u2 * $bR->[$l1][$j];
		$bR->[$l][$j] += $t * $v1;
		$bR->[$l1][$j] += $t * $v2;
	}
	$aR->[$l][$lm1] = -$aR->[$l][$lm1]
		if ($l != 0);
		
	$lm1 = $l;
	$l = $l1;
	goto L90;

L120:
	$a11 = $aR->[$l][$l] / $b11;
	$a21 = $aR->[$l1][$l] / $b11;

	goto L140 	if ($ish == 1);
	goto L1000 	if ($itn == 0);
	goto L155 	if ($its == 10);

	$b22 = $bR->[$l1][$l1];
	$b22 = $epsb if (abs($b22) < $epsb);
	$b33 = $bR->[$na][$na];
	$b33 = $epsb if (abs($b33) < $epsb);
	$b44 = $bR->[$en][$en];
	$b44 = $epsb if (abs($b44) < $epsb);
	
	$a33 = $aR->[$na][$na] / $b33;
	$a34 = $aR->[$na][$en] / $b44;
	$a43 = $aR->[$en][$na] / $b33;
	$a44 = $aR->[$en][$en] / $b44;
	$b34 = $bR->[$na][$en] / $b44;
	
	$t = ($a43 * $b34 - $a33 - $a44) / 2;
	$r = $t * $t + $a34 * $a43 - $a33 * $a44;
	goto L150 if ($r < 0);

	$ish = 1;
	$r = sqrt($r);
	$sh = -$t + $r;
	$s = -$t - $r;
	$sh = $s if (abs($s-$a44) < abs($sh-$a44));

	for ($ll=$ld; $ll<$enm2; $ll++) {
		$l = $enm2 + $ld - $ll - 1;
		goto L140 if ($l == $ld);
		$lm1 = $l - 1;
		$l1 = $l + 1;
		$t = $aR->[$l+1][$l+1];
		$t -= $sh * $bR->[$l][$l] if (abs($bR->[$l][$l]) > $epsb);
		goto L100 if (abs($aR->[$l][$lm1]) <= (abs($t / $aR->[$l1][$l])) * $epsa);
	}

L140:
	$a1 = $a11 - $sh;
	$a2 = $a21;
	$aR->[$l][$lm1] = -$aR->[$l][$lm1] if ($l != $ld);
	goto L160;

L150:
	$a12 = $aR->[$l][$l1] / $b22;
	$a22 = $aR->[$l1][$l1] / $b22;
	$b12 = $bR->[$l][$l1] / $b22;
	$a1 = (($a33 - $a11) * ($a44 - $a11) - $a34 * $a43 + $a43 * $b34 * $a11) / $a21 + $a12 - $a11 * $b12;
	$a2 = $a22 - $a11 - $a21 * $b12 - ($a33 - $a11) - ($a44 - $a11) + $a43 * $b34;
	$a3 = $aR->[$l1+1][$l] / $b22;
	goto L160;

L155:
	$a1 = 0;
	$a2 = 1;
	$a3 = 1.1605;

L160:
	$its++;
	$itn--;
	$lor1 = $ld;
	for ($k=$l; $k<=$na; $k++) {

		$notlas = ($k!=$na) && ($ish==2);
		$k1 = $k + 1;
		$k2 = $k + 2;
		$km1 = MAX($k,$l+1)-1;
		$ll = MIN($en,$k1+$ish);
		goto L190 if ($notlas);

		if ($k != $l) {
			$a1 = $aR->[$k,$km1];
			$a2 = $aR->[$k1,$km1];
		}

		$s = abs($a1) + abs($a2);
		goto L70 if ($s == 0);
		$u1 = $a1 / $s;
		$u2 = $a2 / $s;
		$r = SIGN(sqrt($u1**2 + $u2**2), $u1);
		$v1 = -($u1 + $r) / $r;
		$v2 = -$u2 / $r;
		$u2 = $v2 / $v1;

		for ($j=$km1; $j<$enorn; $j++) {
			$t = $aR->[$k][$j] + $u2 * $aR->[$k1][$j];
			$aR->[$k][$j] += $t * $v1;
			$aR->[$k1][$j] += $t * $v2;
			$t = $bR->[$k][$j] + $u2 * $bR->[$k1][$j];
			$bR->[$k][$j] += $t * $v1;
			$bR->[$k1][$j] += $t * $v2;
		}

		$aR->[$k1,$km1] = 0 if ($k != $l);
		goto L240;

	L190:
		goto L200 if ($k == $l);
		$a1 = $aR->[$k,$km1];
		$a2 = $aR->[$k1,$km1];
		$a3 = $aR->[$k2][$km1];

	L200:
		$s = abs($a1) + abs($a2) + abs($a3);
		next if ($s == 0);
		$u1 = $a1 / $s;
		$u2 = $a2 / $s;
		$u3 = $a3 / $s;
		$r = SIGN(sqrt($u1**2 + $u2**2 + $u3**2), $u1);
		$v1 = -($u1 + $r) / $r;
		$v2 = -$u2 / $r;
		$v3 = -$u3 / $r;
		$u2 = $v2 / $v1;
		$u3 = $v3 / $v1;

		for ($j=$km1; $j<$enorn; $j++) {
			$t = $aR->[$k][$j] + $u2 * $aR->[$k1][$j] + $u3 * $aR->[$k2][$j];
			$aR->[$k][$j] += $t * $v1;
			$aR->[$k1][$j] += $t * $v2;
			$aR->[$k2][$j] += $t * $v3;

			$t = $bR->[$k][$j] + $u2 * $bR->[$k1][$j] + $u3 * $bR->[$k2][$j];
			$bR->[$k][$j] += $t * $v1;
			$bR->[$k1][$j] += $t * $v2;
			$bR->[$k2][$j] += $t * $v3;
		}

		goto L220 if ($k == $l);
		$aR->[$k1,$km1] = $aR->[$k2][$km1] = 0;

	L220:
		$s = (abs($bR->[$k2][$k2])) + (abs($bR->[$k2][$k1])) + (abs($bR->[$k2][$k]));
		goto L240 if ($s == 0);
		$u1 = $bR->[$k2][$k2] / $s;
		$u2 = $bR->[$k2][$k1] / $s;
		$u3 = $bR->[$k2][$k] / $s;
		$r = SIGN(sqrt($u1**2 + $u2**2 + $u3**2), $u1);
		$v1 = -($u1 + $r) / $r;
		$v2 = -$u2 / $r;
		$v3 = -$u3 / $r;
		$u2 = $v2 / $v1;
		$u3 = $v3 / $v1;

		for ($i=$lor1; $i<$ll+1; $i++) {
			$t = $aR->[$i][$k2] + $u2 * $aR->[$i][$k1] + $u3 * $aR->[$i][$k];
			$aR->[$i][$k2] += $t * $v1;
			$aR->[$i][$k1] += $t * $v2;
			$aR->[$i][$k] += $t * $v3;
			$t = $bR->[$i][$k2] + $u2 * $bR->[$i][$k1] + $u3 * $bR->[$i][$k];
			$bR->[$i][$k2] += $t * $v1;
			$bR->[$i][$k1] += $t * $v2;
			$bR->[$i][$k] += $t * $v3;
		}

		$bR->[$k2][$k] = $bR->[$k2][$k1] = 0;

		for ($i=0; $i<$N; $i++) {
			$t = $zR->[$i][$k2] + $u2 * $zR->[$i][$k1] + $u3 * $zR->[$i][$k];
			$zR->[$i][$k2] += $t * $v1;
			$zR->[$i][$k1] += $t * $v2;
			$zR->[$i][$k] += $t * $v3;
		}

	L240:
		$s = (abs($bR->[$k1][$k1])) + (abs($bR->[$k1][$k]));
		next if ($s == 0);
		$u1 = $bR->[$k1][$k1] / $s;
		$u2 = $bR->[$k1][$k] / $s;
		$r = SIGN(sqrt($u1**2 + $u2**2), $u1);
		$v1 = -($u1 + $r) / $r;
		$v2 = -$u2 / $r;
		$u2 = $v2 / $v1;

		for ($i=$lor1; $i<$ll+1; $i++) {
			$t = $aR->[$i][$k1] + $u2 * $aR->[$i][$k];
			$aR->[$i][$k1] += $t * $v1;
			$aR->[$i][$k] += $t * $v2;
			$t = $bR->[$i][$k1] + $u2 * $bR->[$i][$k];
			$bR->[$i][$k1] += $t * $v1;
			$bR->[$i][$k] += $t * $v2;
		}

		$bR->[$k1][$k] = 0;

		for ($i=0; $i<$N; $i++) {
			$t = $zR->[$i][$k1] + $u2 * $zR->[$i][$k];
			$zR->[$i][$k1] += $t * $v1;
			$zR->[$i][$k] += $t * $v2;
		}

	} # for loop beginning at L160

	goto L70; # End QZ step

L1000:										# convergence failure
	$bR->[$N-1][0] = $epsb;
	return($en + 1);

L1001:										# convergance okay
	$bR->[$N-1][0] = $epsb;
	return 0;
}

#----------------------------------------------------------------------
# QZval(\@A,\@B,\@Z,\@alphaR,\@alphaI,\@beta);
#----------------------------------------------------------------------

sub QZval($$$$$$)
{
	my($aR,$bR,$zR,$alfrR,$alfiR,$betaR) = @_;
	my($i,$j,$na,$en,$nn,$c,$d,$r,$s,$t,$di,$ei);
	my($a1,$a2,$u1,$u2,$v1,$v2);
	my($a11,$a12,$a21,$a22,$b11,$b12,$b22);
	my($bn,$cq,$dr,$cz,$ti,$tr);
	my($a1i,$a2i,$a11i,$a12i,$a22i,$a11r,$a12r,$a22r);
	my($sqi,$ssi,$sqr,$szi,$ssr,$szr);
	my($an,$e,$isw) = (0,0,1);
	my($epsb) = $bR->[$N-1][0];

	for ($nn=0; $nn<$N; $nn++) {
		$en = $N - $nn - 1;
		$na = $en - 1;

		goto L505 if ($isw == 2);
		goto L410 if ($en == 0);
		goto L420 if ($aR->[$en][$na] != 0);

	L410:
		$alfrR->[$en] = ($bR->[$en][$en] < 0) ? -$alfrR->[$en] : $aR->[$en][$en];
		$betaR->[$en] = (abs($bR->[$en][$en]));
		$alfiR->[$en] = 0;
		next;

	L420:
		goto L455 if (abs($bR->[$na][$na]) <= $epsb);
		goto L430 if (abs($bR->[$en][$en]) > $epsb);
		$a1 = $aR->[$en][$en];
		$a2 = $aR->[$en][$na];
		$bn = 0;
		goto L435;

	L430:
		$an = abs($aR->[$na][$na]) + abs($aR->[$na][$en]) + abs($aR->[$en][$na]) + abs($aR->[$en][$en]);
		$bn = abs($bR->[$na][$na]) + abs($bR->[$na][$en]) + abs($bR->[$en][$en]);
		$a11 = $aR->[$na][$na] / $an;
		$a12 = $aR->[$na][$en] / $an;
		$a21 = $aR->[$en][$na] / $an;
		$a22 = $aR->[$en][$en] / $an;
		$b11 = $bR->[$na][$na] / $bn;
		$b12 = $bR->[$na][$en] / $bn;
		$b22 = $bR->[$en][$en] / $bn;
		$e = $a11 / $b11;
		$ei = $a22 / $b22;
		$s = $a21 / ($b11 * $b22);
		$t = ($a22 - $e * $b22) / $b22;

		goto L431 if (abs($e) <= abs($ei));
		$e = $ei;
		$t = ($a11 - $e * $b11) / $b11;

	L431:
		$c = ($t - $s * $b12) / 2;
		$d = $c**2 + $s * ($a12 - $e * $b12);
		goto L480 if ($d < 0);

		$e += $c + SIGN(sqrt($d),$c);
		$a11 -= $e * $b11;
		$a12 -= $e * $b12;
		$a22 -= $e * $b22;

		goto L432 if (abs($a11) + abs($a12) < abs($a21) + abs($a22));

		$a1 = $a12;
		$a2 = $a11;
		goto L435;

	L432:
		$a1 = $a22;
		$a2 = $a21;

	L435:
		$s = abs($a1) + abs($a2);
		$u1 = $a1 / $s;
		$u2 = $a2 / $s;
		$r = SIGN(sqrt($u1**2 + $u2**2),$u1);
		$v1 = -($u1 + $r) / $r;
		$v2 = -$u2 / $r;
		$u2 = $v2 / $v1;

		for ($i=0; $i<=$en; $i++) {
			$t = $aR->[$i][$en] + $u2 * $aR->[$i][$na];
			$aR->[$i][$en] += $t * $v1;
			$aR->[$i][$na] += $t * $v2;

			$t = $bR->[$i][$e] + $u2 * $bR->[$i][$na];
			$bR->[$i][$e] += $t * $v1;
			$bR->[$i][$na] += $t * $v2;
		}

		for ($i=0; $i<$N; $i++) {
			$t = $zR->[$i][$en] + $u2 * $zR->[$i][$na];
			$zR->[$i][$en] += $t * $v1;
			$zR->[$i][$na] += $t * $v2;
		}

		goto L475 if ($bn == 0);
		goto L455 if ($an < abs($e) * $bn);
		$a1 = $bR->[$na][$na];
		$a2 = $bR->[$en][$na];
		goto L460;

	L455:
		$a1 = $aR->[$na][$na];
		$a2 = $aR->[$en][$na];

	L460:
		$s = abs($a1) + abs($a2);
		goto L475 if ($s == 0);
		$u1 = $a1 / $s;
		$u2 = $a2 / $s;
		$r = SIGN(sqrt($u1**2 + $u2**2),$u1);
		$v1 = -($u1 + $r) / $r;
		$v2 = -$u2 / $r;
		$u2 = $v2 / $v1;

		for ($j=$na; $j<$N; $j++) {
			$t = $aR->[$na][$j] + $u2 * $aR->[$en][$j];
			$aR->[$na][$j] += $t * $v1;
			$aR->[$en][$j] += $t * $v2;
			$t = $bR->[$na][$j] + $u2 * $bR->[$en][$j];
			$bR->[$na][$j] += $t * $v1;
			$bR->[$en][$j] += $t * $v2;
		}

	L475:
		$aR->[$en][$na] = $bR->[$en][$na] = 0;
		$alfrR->[$na] = $aR->[$na][$na];
		$alfrR->[$en] = $aR->[$en][$en];
		$alfrR->[$na] = -$alfrR->[$na]
			if ($bR->[$na][$na] < 0);
		$alfrR->[$en] = -$alfrR->[$en]
			if ($bR->[$en][$en] < 0);
		$betaR->[$na] = (abs($bR->[$na][$na]));
		$betaR->[$en] = (abs($bR->[$en][$en]));
		$alfiR->[$en] = $alfiR->[$na] = 0;
		goto L505;

	L480:
		$e += $c;
		$ei = sqrt(-$d);
		$a11r = $a11 - $e * $b11;
		$a11i = $ei * $b11;
		$a12r = $a12 - $e * $b12;
		$a12i = $ei * $b12;
		$a22r = $a22 - $e * $b22;
		$a22i = $ei * $b22;

		goto L482
			if (abs($a11r) + abs($a11i) + abs($a12r) + abs($a12i) <
				abs($a21) + abs($a22r) + abs($a22i));

		$a1 = $a12r; 	$a1i = $a12i;
		$a2 = -$a11r;	$a2i = -$a11i;
		goto L485;

	L482:
		$a1 = $a22r;
		$a1i = $a22i;
		$a2 = -$a21;
		$a2i = 0;

	L485:
		$cz = sqrt($a1**2 + $a1i**2);
		goto L487 if ($cz == 0);
		$szr = ($a1 * $a2 + $a1i * $a2i) / $cz;
		$szi = ($a1 * $a2i - $a1i * $a2) / $cz;
		$r = sqrt($cz**2 + $szr**2 + $szi**2);
		$cz /= $r; $szr /= $r; $szi /= $r;
		goto L490;

	L487:
		$szr = 1;
		$szi = 0;

	L490:
		goto L492 if ($an < (abs($e) + $ei) * $bn);
		$a1 = $cz * $b11 + $szr * $b12;
		$a1i = $szi * $b12;
		$a2 = $szr * $b22;
		$a2i = $szi * $b22;
		goto L495;

	L492:
		$a1 = $cz * $a11 + $szr * $a12;
		$a1i = $szi * $a12;
		$a2 = $cz * $a21 + $szr * $a22;
		$a2i = $szi * $a22;

	L495:
		$cq = sqrt($a1**2 + $a1i**2);
		goto L497 if ($cq == 0);
		$sqr = ($a1 * $a2 + $a1i * $a2i) / $cq;
		$sqi = ($a1 * $a2i - $a1i * $a2) / $cq;
		$r = sqrt($cq**2 + $sqr**2 + $sqi**2);
		$cq /= $r;
		$sqr /= $r;
		$sqi /= $r;
		goto L500;

	L497:
		$sqr = 1;
		$sqi = 0;

	L500:
		$ssr = $sqr * $szr + $sqi * $szi;
		$ssi = $sqr * $szi - $sqi * $szr;
		$i = 0;
		$tr = $cq * $cz * $a11 + $cq * $szr * $a12 + $sqr * $cz * $a21 + $ssr * $a22;
   		$ti = $cq * $szi * $a12 - $sqi * $cz * $a21 + $ssi * $a22;
		$dr = $cq * $cz * $b11 + $cq * $szr * $b12 + $ssr * $b22;
		$di = $cq * $szi * $b12 + $ssi * $b22;
		goto L503;

	L502:
		$i = 1;
		$tr = $ssr * $a11 - $sqr * $cz * $a12 - $cq * $szr * $a21 + $cq * $cz * $a22;
		$ti = -$ssi * $a11 - $sqi * $cz * $a12 + $cq * $szi * $a21;
		$dr = $ssr * $b11 - $sqr * $cz * $b12 + $cq * $cz * $b22;
		$di = -$ssi * $b11 - $sqi * $cz * $b12;

	L503:
		$t = $ti * $dr - $tr * $di;
		$j = $na;
		$j = $en if ($t < 0);

		$r = sqrt($dr**2 + $di**2);
		$betaR->[$j] = $bn * $r;
		$alfrR->[$j] = $an * ($tr * $dr + $ti * $di) / $r;
		$alfiR->[$j] = $an * $t / $r;
		goto L502 if ($i == 0);

	L505:
		$isw = 3 - $isw;

	} # main for $nn loop

	$bR->[$N-1][0] = $epsb;
	return 0;
}

#----------------------------------------------------------------------
# QZvec(\@A,\@B,\@Z,\@alphaR,\@alphaI,\@beta)
#----------------------------------------------------------------------

sub QZvec($$$$$$)
{
	my($aR,$bR,$zR,$alfrR,$alfiR,$betaR) = @_;
	my($i,$j,$k,$m,$na,$ii,$en,$jj,$nn,$enm2,$d,$q,$t,$w,$y,$t1,$t2,$w1,$di);
	my($ra,$dr,$sa,$ti,$rr,$tr,$alfm,$almi,$betm,$almr);
	my($r,$s,$x,$x1,$z1,$zz,$isw) = (0,0,0,0,0,0,1);
	my($epsb) = $bR->[$N-1][0];

	for ($nn=0; $nn<$N; $nn++) {
		$en = $N - $nn - 1;
		$na = $en - 1;
		goto L795 if ($isw == 2);
		goto L710 if ($alfiR->[$en] != 0);

		$m = $en;
		$bR->[$en][$en] = 1;
		next if ($na == -1);
		$alfm = $alfrR->[$m];
		$betm = $betaR->[$m];

		for ($ii=0; $ii<=$na; $ii++) {
			$i = $en - $ii - 1;
			$w = $betm * $aR->[$i][$i] - $alfm * $bR->[$i][$i];
			$r = 0;

			for ($j=$m; $j<=$en; $j++) {
				$r += ($betm * $aR->[$i][$j] - $alfm * $bR->[$i][$j]) * $bR->[$j][$en];
			}

			goto L630 if ($i == 0 || $isw == 2);
			goto L630 if ($betm * $aR->[$i,$i-1] == 0);

			$zz = $w;
			$s = $r;
			goto L690;

		L630:
			$m = $i;
			goto L640 if ($isw == 2);

			$t = $w;
			$t = $epsb if ($w == 0);

			$bR->[$i][$en] = -$r / $t;
			next;

		L640:
			$x = $betm * $aR->[$i][$i+1] - $alfm * $bR->[$i][$i+1];
			$y = $betm * $aR->[$i+1][$i];
			$q = $w * $zz - $x * $y;
			$t = ($x * $s - $zz * $r) / $q;
			$bR->[$i][$en] = $t;
			goto L650 if (abs($x) <= abs($zz));
			$bR->[$i+1][$en] = (-$r - $w * $t) / $x;
			goto L690;

		L650:
			$bR->[$i+1][$en] = (-$s - $y * $t) / $zz;

		L690:
			$isw = 3 - $isw;

		} # for ($ii inner loop
		next;

	L710:
		$m = $na;
		$almr = $alfrR->[$m];
		$almi = $alfiR->[$m];
		$betm = $betaR->[$m];

		$y = $betm * $aR->[$en][$na];
		$bR->[$na][$na] = -$almi * $bR->[$en][$en] / $y;
		$bR->[$na][$en] = ($almr * $bR->[$en][$en] - $betm * $aR->[$en][$en]) / $y;
		$bR->[$en][$na] = 0;
		$bR->[$en][$en] = 1;
		$enm2 = $na;
		goto L795 if ($enm2 == 0);

		for ($ii=0; $ii<$enm2; $ii++) {
			$i = $na - $ii - 1;
			$w = $betm * $aR->[$i][$i] - $almr * $bR->[$i][$i];
			$w1 = -$almi * $bR->[$i][$i];
			$ra = $sa = 0;

			for ($j=$m; j<=$en; $j++) {
				$x = $betm * $aR->[$i][$j] - $almr * $bR->[$i][$j];
				$x1 = -$almi * $bR->[$i][$j];
				$ra = $ra + $x * $bR->[$j][$na] - $x1 * $bR->[$j][$en];
				$sa = $sa + $x * $bR->[$j][$en] + $x1 * $bR->[$j][$na];
			}

			goto L770 if ($i == 0 || $isw == 2);
			goto L770 if ($betm * $aR->[$i,$i-1] == 0);

			$zz = $w; $z1 = $w1;
			$r = $ra; $s = $sa;
			$isw = 2;
			next;

		L770:
			$m = $i;
			goto L780 if ($isw == 2);
			$tr = -$ra; $ti = -$sa;

		L773:
			$dr = $w; $di = $w1;

		L775:
			goto L777 if (abs($di) > abs($dr));
			$rr = $di / $dr;
			$d = $dr + $di * $rr;
			$t1 = ($tr + $ti * $rr) / $d;
			$t2 = ($ti - $tr * $rr) / $d;
			if    ($isw == 1) { goto L787; }
			elsif ($isw == 2) { goto L782; }

		L777:
			$rr = $dr / $di;
			$d = $dr * $rr + $di;
			$t1 = ($tr * $rr + $ti) / $d;
			$t2 = ($ti * $rr - $tr) / $d;
			if    ($isw == 1) { goto L787; }
			elsif ($isw == 2) { goto L782; }

		L780:
			$x = $betm * $aR->[$i][$i+1] - $almr * $bR->[$i][$i+1];
			$x1 = -$almi * $bR->[$i][$i+1];
			$y = $betm * $aR->[$i+1][$i];
			$tr = $y * $ra - $w * $r + $w1 * $s;
			$ti = $y * $sa - $w * $s - $w1 * $r;
			$dr = $w * $zz - $w1 * $z1 - $x * $y;
			$di = $w * $z1 + $w1 * $zz - $x1 * $y;
			$dr = $epsb if ($dr == 0 && $di == 0);
			goto L775;

		L782:
			$bR->[$i+1][$na] = $t1;
			$bR->[$i+1][$en] = $t2;
			$isw = 1;
			goto L785 if (abs($y) > abs($w) + abs($w1));
			$tr = -$ra - $x * $bR->[$i+1][$na] + $x1 * $bR->[$i+1][$en];
			$ti = -$sa - $x * $bR->[$i+1][$en] - $x1 * $bR->[$i+1][$na];
			goto L773;

		L785:
			$t1 = (-$r - $zz * $bR->[$i+1][$na] + $z1 * $bR->[$i+1][$en]) / $y;
			$t2 = (-$s - $zz * $bR->[$i+1][$en] - $z1 * $bR->[$i+1][$na]) / $y;

		L787:
			$bR->[$i][$na] = $t1;
			$bR->[$i][$en] = $t2;

		} # for ($ii inner loop

	L795:
		$isw = 3 - $isw;

	} # for ($nn outer loop

	for ($jj=0; $jj<$N; $jj++) {
		$j = $N - $jj - 1;
		for ($i=0; $i<$N; $i++) {
			$zz = 0;
			for ($k=0; $k<=$j; $k++) {
				$zz += $zR->[$i][$k] * $bR->[$k][$j];
			}
			$zR->[$i][$j] = $zz;
		}
	}

	for ($j=0; $j<$N; $j++) {
		$d = 0;
		goto L920 if ($isw == 2);
		goto L945 if ($alfiR->[$j] != 0);
		for ($i=0; $i<$N; $i++) {
			$d = (abs($zR->[$i][$j])) if ((abs($zR->[$i][$j])) > $d);
		}
		for ($i=0; $i<$N; $i++) {
			$zR->[$i][$j] /= $d;
		}
		next;

	L920:
		for ($i=0; $i<$N; $i++) {
			$r = abs($zR->[$i][$j-1]) + abs($zR->[$i][$j]);
			if ($r != 0) {
				my($u1) = $zR->[$i][$j-1] / $r;
				my($u2) = $zR->[$i][$j] / $r;
				$r *= sqrt($u1**2 + $u2**2);
			}
			$d = $r if ($r > $d);
		}

		for ($i=0; $i<$N; $i++) {
			$zR->[$i][$j-1] /= $d;
			$zR->[$i][$j] /= $d;
		}

	L945:
		$isw = 3 - $isw;

	} # for ($j outer loop
}

1;

