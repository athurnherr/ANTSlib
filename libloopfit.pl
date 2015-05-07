#======================================================================
#                    L I B L O O P F I T . P L 
#                    doc: Thu Mar 12 08:05:26 2015
#                    dlm: Sun Mar 15 19:46:49 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 47 22 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 12, 2015: - created
#	Mar 15, 2015: - added [libQZ.pl]

require "$ANTS/nrutil.pl";
require "$ANTS/libSVD.pl";										# for circular fit
require "$ANTS/libQZ.pl";										# for ellipse fit

#----------------------------------------------------------------------
# fitCircle(\@x,\@y) => ($r,$cx,$cy)
#	\@x,\@y		references to list of data values
#	$r			circle radius
#	$cx,$cy		circle center
#----------------------------------------------------------------------

sub fitCircle($$)
{
	my($xR,$yR) = @_;
	my(@A,@V,@W);
	my($nSamp) = scalar(@{$xR});
	my($nParam) = 3;
	
	matrix(\@A,1,$nSamp,1,$nParam); 							# rows, then columns
	matrix(\@V,1,$nParam,1,$nParam);							# 3x3 matrix for circle fitting
	vector(\@W,1,$nParam);										# diag matrix of singular values output as vector
	vector(\@b,1,$nSamp);										# rhs
	vector(\@coeff,1,$nParam);									# fit coefficients
	
	for ($r=1; $r<=$nSamp; $r++) {								# circle equation c1*x + c2*y + c3 = -(x^2 + y^2)
		$A[$r][1] = $xR->[$r-1];								#	r  = sqrt((c1^2 + c2^2)/4 - c3)
		$A[$r][2] = $yR->[$r-1];								#	cx = -c1/2
		$A[$r][3] = 1;											#	cy = -c2/2
		$b[$r] = -($xR->[$r-1]**2+$yR->[$r-1]**2);
	}
	
	svdcmp(\@A,\@W,\@V);										# solve Ax = b, with x == coeff
	svbksb(\@A,\@W,\@V,\@b,\@coeff);
	
	return ($coeff[1],$coeff[2],$coeff[3]);
	my($r)	= sqrt(($coeff[1]**2+$coeff[2]**2)/4-$coeff[3]);
	my($cx) = -0.5*$coeff[1];
	my($cy) = -0.5*$coeff[2];
	return ($r,$cx,$cy);
}

#----------------------------------------------------------------------
# fitEllipse(\@x,\@y) => ?
#	\@x,\@y		references to list of data values
#
#	Direct Least Square Fitting of Ellipses
#	Andrew Fitzgibbon, Maurizio Pilu, and Robert B. Fisher, MAY 1999
# 	IEEE transactions on pattern analysis and machine intelligence 21(5): 476-480
#----------------------------------------------------------------------

sub fitEllipse($$)
{
	my($xR,$yR) = @_;
	my($nSamp) = scalar(@{$xR});
	
	# design matrix D = [ x.*x x.*y y.*y x y ones(size(x)) ]; 
	my(@D);
	for (my($r)=0; $r<$nSamp; $r++) {
		$D[$r][0] = $xR->[$r]**2;
		$D[$r][1] = $xR->[$r] * $yR->[$r];
		$D[$r][2] = $yR->[$r]**2;
		$D[$r][3] = $xR->[$r];
		$D[$r][4] = $yR->[$r];
		$D[$r][5] = 1;
	}

	# scatter matrix S = D' * D;
	my(@S);
	for (my($i)=0; $i<6; $i++) {
		for (my($j)=0; $j<6; $j++) {
			for (my($k)=0; $k<$nSamp; $k++) {
				$S[$i][$j] += $D[$k][$j] * $D[$k][$i];
			}
		}
	}

	# 6x6 constraint matrix C
	my(@C);
	for (my($r)=0; $r<6; $r++) {
		for (my($c)=0; $c<6; $c++) {
			$C[$r][$c] = 0;
		}
	}
	$C[0][2] = -2; $C[1][1] = 1; $C[2][0] = -2;

	# solve generalized eigensystem
	my(@geRe,@geImg,@geVec);
	eig(\@S,\@C,\@geRe,\@geImg,\@geVec);

	# find only negative eigenvalue
	my($i);
	for ($i=0; $i<@geRe; $i++) {
		last if (numberp($geRe[$i]) && ($geRe[$i] < 0));
	}
	croak("internal error") unless ($geRe[$i] < 0);

	# get fitted parameters
	return @{$geVec[$i]};

}

1;
