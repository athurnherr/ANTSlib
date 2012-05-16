#======================================================================
#                    M R Q M I N . P L 
#                    doc: Wed Feb 24 15:10:22 1999
#                    dlm: Tue Aug 22 22:05:43 2006
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 15 67 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# MRQMIN routine from Numerical Recipes adapted to ANTS
# NB: based on 1st edtion of NR!!!!

# HISTORY:
#	Mar 11, 1999: - created
#	Sep 27, 1999: - adapted to allow for new version of covsrt.pl as well
#	Aug 22, 2006: - changed require from covsrt_old.pl to covsrt.pl

# Notes:
#	- x,y,sig are field numbers for data in $ants_
#	- if sig is a negative number, -sig is used as constant input stddev
#	- @A, @listA, @alpha, @covar, $chiSq, &funcs, $alamda passed as refs

require "$ANTS/mrqcof.pl";
require "$ANTS/gaussj.pl";
require "$ANTS/covsrt.pl";
require "$ANTS/nrutil.pl";

{													# static scope
	my(@da,@atry,@oneda,@beta,$oChiSq);

	sub mrqmin($$$$$$$$$$)
	{
		my($xfnr,$yfnr,$sig,$AR,$listAR,$covarR,
		   $alphaR,$chiSqR,$funcsR,$alamdaR) = @_;
	
		my($k,$kk,$j,$ihit);
	
		if ($$alamdaR < 0.0) {
			&matrix(\@oneda,1,$#{$AR},1,1);
			&vector(\@atry,1,$#{$AR});
			&vector(\@da,1,$#{$AR});
			&vector(\@beta,1,$#{$AR});
			$kk = $#{$listAR}+1;
			for ($j=1; $j<=$#{$AR}; $j++) {
				$ihit = 0;
				for ($k=1; $k<=$#{$listAR}; $k++) {
					if ($listAR->[$k] == $j) { $ihit++; }
				}
				if ($ihit == 0) {
					$listAR->[$kk++] = $j;
				} elsif ($ihit > 1) {
					croak("Bad listA permutation in MRQMIN-1");
				}
			}
			if ($kk != $#{$AR}+1) {
				for ($ei=1; $ei<=$#{$listAR}; $ei++) {
					print(STDERR "listA[$ei] = $listAR->[$ei]\n");
				}
				croak("Bad listA permutation in MRQMIN-2 " .
					"($kk != $#{$AR}+1)");
			}
			$$alamdaR = 0.001;
			&mrqcof($xfnr,$yfnr,$sig,$AR,$listAR,$alphaR,
					\@beta,$chiSqR,$funcsR);
			$oChiSq = $$chiSqR;
		}
		for ($j=1; $j<=$#{$listAR}; $j++) {
			for ($k=1; $k<=$#{$listAR}; $k++) {
				$covarR->[$j][$k] = $alphaR->[$j][$k];
#				print(STDERR "covar[$j][$k] = $covarR->[$j][$k]\n");
			}
			$covarR->[$j][$j] = $alphaR->[$j][$j]*(1.0+$$alamdaR);
			$oneda[$j][1] = $beta[$j];
		}
		&gaussj($covarR,\@oneda);
		for ($j=1; $j<=$#{$listAR}; $j++) {
			$da[$j] = $oneda[$j][1];
		}
		if ($$alamdaR == 0.0) {
			&covsrt($covarR,$listAR);
			return;
		}
		for ($j=1; $j<=$#{$AR}; $j++) { $atry[$j] = $AR->[$j]; }
		for ($j=1; $j<=$#{$listAR}; $j++) {
			$atry[$listAR->[$j]] = $AR->[$listAR->[$j]]+$da[$j];
		}
		&mrqcof($xfnr,$yfnr,$sig,\@atry,$listAR,$covarR,\@da,$chiSqR,$funcsR);
		if ($$chiSqR < $oChiSq) {
			$$alamdaR *= 0.1;
			$oChiSq = $$chiSqR;
			for ($j=1; $j<=$#{$listAR}; $j++) {
				for ($k=1; $k<=$#{$listAR}; $k++) {
					$alphaR->[$j][$k] = $covarR->[$j][$k];
				}
				$beta[$j] = $da[$j];
				$AR->[$listAR->[$j]] = $atry[$listAR->[$j]];
			}
		} else {
			$$alamdaR *= 10.0;
			$$chiSqR = $oChiSq;
		}
		return;
	}

} # end of static scope

1;
