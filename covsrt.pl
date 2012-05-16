#======================================================================
#                    C O V S R T . P L 
#                    doc: Sun Sep 26 18:44:11 1999
#                    dlm: Sun Sep 26 18:56:56 1999
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 46 2 NIL 0 0 72 2 2 4 ofnI
#======================================================================

# 2nd edition covsrt.c adapted to ANTS

# HISTORY:
#	Sep 26, 1999: - created after confusion about old version [covsrt_old.pl]

sub covsrt($$)
{
	my($covarR,$iaR) = @_;
	my($ma) = $#{$covarR};
	my($mfit) = $#{$iaR};
	my($i,$j,$k);
	my($swap);

	for ($i=$mfit+1;$i<=$ma;$i++) {
		for ($j=1;$j<=$i;$j++) {
			$covarR->[$i][$j] = 0;
			$covarR->[$j][$i] = 0;
		}
	}
	$k=$mfit;
	for ($j=$ma;$j>=1;$j--) {
		if ($iaR->[$j]) {
			for ($i=1;$i<=$ma;$i++) {
				$swap = $covarR->[$i][$k];
				$covarR->[$i][$k] = $covarR->[$i][$j];
				$covarR->[$i][$j] = $swap;
			}
			for ($i=1;$i<=$ma;$i++) {
				$swap = $covarR->[$k][$i];
				$covarR->[$k][$i] = $covarR->[$j][$i];
				$covarR->[$j][$i] = $swap;
			}
			$k--;
		}
	}
}

1;
