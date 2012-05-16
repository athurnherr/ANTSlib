#======================================================================
#                    G A U S S J . P L 
#                    doc: Wed Feb 24 17:06:55 1999
#                    dlm: Fri Jan  6 10:23:44 2012
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 46 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# GAUSSJ routine from Numerical Recipes adapted to ANTS

# Notes:
#	- both @A and @B passed by ref

# HISTORY:
#	Feb 24, 1999: - apparently created
#	Jul 19, 2001: - apparently fiddled
#	Jan  6, 2011: - added code to check for numericity of input

sub gaussj($$)
{
	my($AR,$BR) = @_;
	my($n) = $#{$AR};
	my($m) = $#{$BR->[1]};
	my(@indxc,@indxr,@ipiv);
	my($i,$icol,$irow,$j,$k,$l,$ll);
	my($big,$dum,$pivinv);
	my($temp);

#	print(STDERR "n = $n, m = $m\n");
#	for ($i=1; $i<=$n; $i++) {
#		for ($j=1; $j<=$n; $j++) {
#			print(STDERR "A[$i][$j] = $AR->[$i][$j]\n");
#		}
#	}

	&vector(\@indxc,1,$n);
	&vector(\@indxr,1,$n);
	&vector(\@ipiv, 1,$n);
	for ($j=1; $j<=$n; $j++) { $ipiv[$j] = 0; }
	for ($i=1; $i<=$n; $i++) {
		$big = 0.0;
		for ($j=1; $j<=$n; $j++) {
			if ($ipiv[$j] != 1) {
				for ($k=1; $k<=$n; $k++) {
					if ($ipiv[$k] == 0) {
						croak("GAUSSJ: non-numeric A[$j][$k]\n")
							unless numberp($AR->[$j][$k]);
						if (abs($AR->[$j][$k]) >= $big) {
							$big = abs($AR->[$j][$k]);
							$irow = $j;
							$icol = $k;
						}
					} elsif ($ipiv[$k] > 1) {
						croak("GAUSSJ: Singular Matrix-1");
					}
				}
			}
		}
		++($ipiv[$icol]);
		if ($irow != $icol) {
			for ($l=1; $l<=$n; $l++) {
				$temp = $AR->[$irow][$l];
				$AR->[$irow][$l] = $AR->[$icol][$l];
				$AR->[$icol][$l] = $temp;
			}
			for ($l=1; $l<=$m; $l++) {
				croak("GAUSSJ: non-numeric B[$irow][$l]\n")
						unless numberp($BR->[$irow][$l]);
				croak("GAUSSJ: non-numeric B[$icol][$l]\n")
						unless numberp($BR->[$icol][$l]);
				$temp = $BR->[$irow][$l];
				$BR->[$irow][$l] = $BR->[$icol][$l];
				$BR->[$icol][$l] = $temp;
			}
		}
		$indxr[$i] = $irow;
		$indxc[$i] = $icol;
		if ($AR->[$icol][$icol] == 0.0) {
			croak("GAUSSJ: Singular Matrix-2");
		}
		$pivinv = 1.0/$AR->[$icol][$icol];
		$AR->[$icol][$icol] = 1.0;
		for ($l=1; $l<=$n; $l++) {
			$AR->[$icol][$l] *= $pivinv;
		}
		for ($l=1; $l<=$m; $l++) {
			$BR->[$icol][$l] *= $pivinv;
		}
		for ($ll=1; $ll<=$n; $ll++) {
			if ($ll != $icol) {
				$dum = $AR->[$ll][$icol];
				$AR->[$ll][$icol] = 0.0;
				for ($l=1; $l<=$n; $l++) {
					$AR->[$ll][$l] -= $AR->[$icol][$l]*$dum;
				}
				for ($l=1; $l<=$m; $l++) {
					$BR->[$ll][$l] -= $BR->[$icol][$l]*$dum;
				}
			}
		}
	}
	for ($l=$n; $l>=1; $l--) {
		if ($indxr[$l] != $indxc[$l]) {
			for ($k=1; $k<=$n; $k++) {
				$temp = $AR->[$k][$indxr[$l]];
				$AR->[$k][$indxr[$l]] = $AR->[$k][$indxc[$l]];
				$AR->[$k][$indxc[$l]] = $temp;
			}
		}
	}
}

1;
