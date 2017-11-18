#======================================================================
#                    L I B R A N D . P L 
#                    doc: Thu Nov 19 14:27:19 2015
#                    dlm: Wed Sep  6 10:18:42 2017
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 17 61 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov 19, 2015: - created
#	Sep  6, 2017: - finally implemented gauss_rand()

#----------------------------------------------------------------------------------------------------
# From info found at [http://www.design.caltech.edu/erik/Misc/Gaussian.html]
#
# verified with:
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=gauss_rand() | Hist  r
#----------------------------------------------------------------------------------------------------

{ my($cached);	# NB: cached values is normalized

sub gauss_rand(@)
{
	my($mu,$sigma) = &antsFunUsage(-1,'ff','[mu[,sigma]]',@_)
		if (@_);
	$sigma = 1 unless defined($sigma);
	$mu	   = 0 unless defined($mu);

	if (defined($cached)) {
		my($Y) = $cached * $sigma + $mu;
		undef($cached);
		return $Y;
	}

	my($X1,$X2,,$w);
	do {
		$X1 = 2*rand() - 1;
		$X2 = 2*rand() - 1;
		$w  = $X1**2 + $X2**2;
	} while ($w >= 1);
	$w = sqrt((-2 * log($w)) / $w);
	my($cached) = $X2 * $w;	
	return $X1 * $w * $sigma + $mu;
}

}

#----------------------------------------------------------------------------------------------------
# From info found at [http://www.mathworks.com/matlabcentral/newsreader/view_thread/301276]
#
# verified with:
#   plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(-2) | Hist -s 100 r | Cat -S $2>2' lt 3,x**-2*1e7
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(-3) | Hist r',x**-3*7e3
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(0) | Hist -s 0.01 r'
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(1) | Hist -s 0.01 r'
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(2) | Hist -s 0.01 r'
#----------------------------------------------------------------------------------------------------

sub pwrlaw_rand($)		
{
	my($p) = &antsFunUsage(1,'f','exponent',@_);
	return rand() ** (1/($p+1));
}

1;
