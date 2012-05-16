#======================================================================
#                    C O V S R T _ O L D . P L 
#                    doc: Wed Feb 24 17:35:07 1999
#                    dlm: Sun Sep 26 18:42:48 1999
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 12 0 NIL 0 0 72 2 2 4 ofnI
#======================================================================

# COVSRT routine from Numerical Recipes adapted to ANTS
# NB: this is the 1st edition version using listA!!!!

# Notes:
#	- both @covar and @listA passed by ref

sub covsrt($$)
{
	my($covarR,$listAR) = @_;
	my($ma) = $#{$covarR};
	my($mfit) = $#{$listAR};
	my($i,$j);
	my($swap);

	for ($j=1; $j<$ma; $j++) {
		for ($i=$j+1; $i<=$ma; $i++) { $covarR->[$i][$j] = 0.0; }
	}
	for ($i=1; $i<$mfit; $i++) {
		for ($j=$i+1; $j<=$mfit; $j++) {
			if ($listAR->[$j] > $listAR->[$i]) {
				$covarR->[$listAR->[$j]][$listAR->[$i]] = $covarR->[$i][$j];
			} else {
				$covarR->[$listAR->[$i]][$listAR->[$j]] = $covarR->[$i][$j];
			}
		}
	}
	$swap = $covarR->[1][1];
	for ($j=1; $j<=$ma; $j++) {
		$covarR->[1][$j]  = $covarR->[$j][$j];
		$covarR->[$j][$j] = 0.0;
	}
	$covarR->[$listAR->[1]][$listAR->[1]] = $swap;
	for ($j=2; $j<=$mfit; $j++) {
		$covarR->[$listAR->[$j]][$listAR->[$j]] = $covarR->[1][$j];
	}
	for ($j=2; $j<=$ma; $j++) {
		for ($i=1; $i<=$j-1; $i++) {
			$covarR->[$i][$j] = $covarR->[$j][$i];
		}
	}
}

1;
