#======================================================================
#                    L F I T . P L 
#                    doc: Sat Jul 31 11:24:47 1999
#                    dlm: Thu Jan  5 12:53:11 2012
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 19 60 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# LFIT routine from Numerical Recipes adapted to ANTS

# HISTORY:
#	Jul 31, 1999: - manually converted from c-source
#	Aug 01, 1999: - changed funcs() interface
#	Sep 26, 1999: - made sure right version of covsrt is used
#	Jun 28, 2001: - re-added commented out code 'cause it's required
#					on some perl versions
#	Jan  5, 2012: - BUG: non-numeric x/y were not handled correctly;
#						 this was only easily apparent when the last
#						 record contained non-numeric values

# Notes:
#   - x,y,sig are field numbers for data in $ants_
#	- funcs is passed the current index & xfnr instead of the x-value
#   - if sig is a negative number, -sig is used as constant input stddev
#   - @a, @ia, @covar, &funcs passed as refs
#	- chi square is returned

require "$ANTS/nrutil.pl";
require "$ANTS/covsrt.pl";
require "$ANTS/gaussj.pl";

sub lfit($$$$$$$)
{
	my($xfnr,$yfnr,$sig,$aR,$iaR,$covarR,$funcsR) = @_;

	my($i,$j,$k,$l,$m,$mfit);			# int
	my($ym,$wt,$sum,$sig2i,$chisq);		# float
	my(@beta,@afunc);					# float[]

	&matrix(\@beta,1,$#{$aR},1,1);
	&vector(\@afunc,1,$#{$aR});
	for ($j=1; $j<=$#{$aR}; $j++) {
		$mfit++ if ($iaR->[$j]);
	}
	croak("lfit: no parameters to be fitted") if ($mfit == 0);
	for ($j=1; $j<=$mfit; $j++) {		# REQUIRED FOR SOME PERL VERSIONS!!!
		for ($k=1;$ k<=$mfit; $k++) {
			$covarR->[$j][$k] = 0;
		}
		$beta[$j][1] = 0;
	}
	for ($i=0; $i<=$#ants_; $i++) {
		next if ($antsFlagged[$i]);
		next unless numberp($ants_[$i][$xfnr]) && numberp($ants_[$i][$yfnr]);
		&$funcsR($i,$xfnr,\@afunc);
		$ym = $ants_[$i][$yfnr];
		if ($mfit < $#{$aR}) {
			for ($j=1; $j<=$#{$aR}; $j++) {
				$ym -= $aR->[$j]*$afunc[$j] if (!$iaR->[$j]);
			}
		}
        if ($sig > 0) {                                 # field number
            $sig2i = 1.0/($ants_[$i][$sig]*$ants_[$i][$sig]);
        } else {                                        # const value
            $sig2i = 1.0/($sig*$sig);
        }
		for ($j=0,$l=1; $l<=$#{$aR}; $l++) {
			if ($iaR->[$l]) {
				$wt = $afunc[$l]*$sig2i;
				for ($j++,$k=0,$m=1; $m<=$l; $m++) {
					$covarR->[$j][++$k] += $wt*$afunc[$m] if ($iaR->[$m]);
				}
				$beta[$j][1] += $ym*$wt;
			}
		}
	}
	for ($j=2; $j<=$mfit; $j++) {
		for ($k=1;$k<$j;$k++) {
			$covarR->[$k][$j] = $covarR->[$j][$k];
#			print(STDERR "covarR[$k][$j] = $covarR->[$k][$j]\n");
		}
	}
	&gaussj($covarR,\@beta);
	for ($j=0,$l=1;$l<=$#{$aR};$l++) {
		$aR->[$l]=$beta[++$j][1] if ($iaR->[$l]);
	}
	for ($i=0; $i<=$#ants_; $i++) {
		next if ($antsFlagged[$i]);
		next unless numberp($ants_[$i][$xfnr]) && numberp($ants_[$i][$yfnr]);
		&$funcsR($i,$xfnr,\@afunc);
		for ($sum=0,$j=1; $j<=$#{$aR}; $j++) {
			$sum += $aR->[$j]*$afunc[$j];
		}
		my($tmpval) = ($sig > 0) ?
			($ants_[$i][$yfnr] - $sum) / $ants_[$i][$sig] :
			($ants_[$i][$yfnr] - $sum) / -$sig;
		$chisq += $tmpval * $tmpval;
	}
	&covsrt($covarR,$iaR);
	return $chisq;
}

