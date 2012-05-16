#======================================================================
#                    A M O E B A . P L 
#                    doc: Wed Aug 23 05:11:48 2006
#                    dlm: Wed Aug 23 23:52:12 2006
#                    (c) 2006 A.M. Thurnherr
#                    uE-Info: 88 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# perlified amoeba implementation of NR code

# NOTES:
#	- 0-based arrays
#	- amoeba returns undef if NMAX is exceeded and # of evals otherwise

use strict;

sub amotry($$$$$$)
{
	my($pR,$yR,$psumR,$funR,$ihi,$fac) = @_;
	my(@ptry);

	my($ndim) = scalar(@{$pR->[0]});
	my($fac1) = (1-$fac) / $ndim;
	my($fac2) = $fac1 - $fac;
	
	for (my($j)=0; $j<$ndim; $j++) {
		$ptry[$j] = $psumR->[$j]*$fac1 - $pR->[$ihi][$j]*$fac2;
	}
	my($ytry) = &$funR(@ptry);
	if ($ytry < $yR->[$ihi]) {
		$yR->[$ihi] = $ytry;
		for (my($j)=0; $j<$ndim; $j++) {
			$psumR->[$j] += $ptry[$j] - $pR->[$ihi][$j];
			$pR->[$ihi][$j] = $ptry[$j];
		}
	}
	return $ytry;
}

sub get_psum($$)
{
	my($pR,$psumR) = @_;

	for (my($j)=0; $j<@{$pR->[0]}; $j++) {
		my($sum);
		for ($sum=my($i)=0; $i<=@{$pR->[0]}; $i++) {
			$sum += $pR->[$i][$j];
		}
		$psumR->[$j] = $sum;
	}
}

sub amoeba($$$$)
{
	my($pR,$yR,$ftol,$funR,$NMAX) = @_;
	my($nfunk) = 0;
	my($ndim) = scalar(@{$pR->[0]});
	my(@psum);
	
	&get_psum($pR,\@psum);

	while (1) {
		my($i,$ihi,$inhi,$j);
		my($sum);
		
		my($ilo) = 0;
		if ($yR->[0] > $yR->[1]) {
			$ihi = 0; $inhi = 1;
		} else {
			$ihi = 1; $inhi = 0;
		}

		for ($i=0; $i<$ndim+1; $i++) {
			if ($yR->[$i] <= $yR->[$ilo]) {
				$ilo = $i;
			}
			if ($yR->[$i] > $yR->[$ihi]) {
				$inhi = $ihi;
				$ihi  = $i;
			} elsif ($yR->[$i] > $yR->[$inhi] && $i != $ihi) {
				$inhi = $i;
			}
		}
		print(STDERR "best = $yR->[$ilo]\n");

		my($rtol) = 2 * abs($yR->[$ihi] - $yR->[$ilo]) /
						(abs($yR->[$ihi]) + abs($yR->[$ilo]));
		if ($rtol < $ftol) {
			my($tmp) = $yR->[0]; $yR->[0] = $yR->[$ilo]; $yR->[$ilo] = $tmp;
			for ($i=0; $i<$ndim; $i++) {
				my($tmp) = $pR->[1][$i]; $pR->[1][$i] = $pR->[$ilo][$i];
				$pR->[$ilo][$i] = $tmp;
			}
			return $nfunk;
		}
		
		return undef if ($nfunk >= $NMAX);
		$nfunk += 2;
		
		my($ytry) = amotry($pR,$yR,\@psum,$funR,$ihi,-1);
		if ($ytry <= $yR->[$ilo]) {
			$ytry = amotry($pR,$yR,\@psum,$funR,$ihi,2);
		} elsif ($ytry >= $yR->[$inhi]) {
			my($ysave) = $yR->[$ihi];
			$ytry = amotry($pR,$yR,\@psum,$funR,$ihi,0.5);
			if ($ytry >= $ysave) {
				for ($i=0; $i<$ndim+1; $i++) {
					if ($i != $ilo) {
						for ($j=0; $j<$ndim; $j++) {
							$pR->[$i][$j] = $psum[$j] =
								0.5 * ($pR->[$i][$j] + $pR->[$ilo][$j]);
						}
						$yR->[$i] = &$funR(@psum);
					}
				}
				$nfunk += $ndim;
				&get_psum($pR,\@psum);
			}
		} else {
			--$nfunk;
		}
	}
}

1;
