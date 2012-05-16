#======================================================================
#                    M R Q C O F . P L 
#                    doc: Wed Feb 24 15:14:39 1999
#                    dlm: Thu Feb 27 09:40:41 2003
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 30 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# MRQCOF routine from Numerical Recipes adapted for ANTS

# Notes:
#	- data which has $antsFlagged[] TRUE is ignored
#	- x,y,sig are field numbers for data in $ants_
#	- if sig is a negative number, -sig is used as constant input stddev
#	- @A, @listA, @alpha, @beta, $chisq, &funcs are passed as references

# HISTORY:
# 	- Feb 24, 1999: - ported from c-source
#	- Jul 31, 1999: - BUG: first elt in $ants_ was ignored!

require "$ANTS/nrutil.pl";

sub mrqcof($$$$$$$$$)
{
	my($xfnr,$yfnr,$sig,$AR,$listAR,$alphaR,$betaR,$chiSqR,$funcsR) = @_;

	my($k,$j,$i);
	my($ymod,$wt,$sig2i,$dy,@dyda);

	&vector(\@dyda,1,$#{$AR});
	for ($j=1; $j<=$#{$listAR}; $j++) {
		for ($k=1; $k<=$j; $k++) { $alphaR->[$j][$k] = 0.0; }
		$betaR->[$j] = 0.0;
	}
	$$chiSqR = 0.0;
	for ($i=0; $i<=$#ants_; $i++) {
		next if ($antsFlagged[$i]);
	    $ymod = &$funcsR($ants_[$i][$xfnr],$AR,\@dyda);
	    if ($sig > 0) {									# field number
			$sig2i = 1.0/($ants_[$i][$sig]*$ants_[$i][$sig]);
		} else {										# const value
			$sig2i = 1.0/($sig*$sig);
		}
		$dy = $ants_[$i][$yfnr] - $ymod;
		for ($j=1; $j<=$#{$listAR}; $j++) {
			$wt = $dyda[$listAR->[$j]]*$sig2i;
			for ($k=1; $k<=$j; $k++) {
				$alphaR->[$j][$k] += $wt*$dyda[$listAR->[$k]];
#				print(STDERR "alpha[$j][$k] = $alphaR->[$j][$k]\n");
#				print(STDERR "$wt,$dyda[$listAR->[$k]]\n");
			}
			$betaR->[$j] += $dy*$wt;
		}
		$$chiSqR += $dy*$dy*$sig2i;
	}
	for ($j=2; $j<=$#{$listAR}; $j++) {
		for ($k=1; $k<=$j-1; $k++) {
			$alphaR->[$k][$j] = $alphaR->[$j][$k];
		}
	}
}

1;
