#======================================================================
#                    L I B F U N S . P L 
#                    doc: Wed Mar 24 11:49:13 1999
#                    dlm: Thu Jun  4 17:56:37 2015
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 306 13 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 24, 1999: - copied from the c-version of NR
#	Mar 26, 1999: - added stuff for better [./fit]
#	Sep 18, 1999: - argument typechecking
#	Oct 04, 1999: - added gauss(), normal()
#	Jan 25, 2001: - added f(), sgn()
#	Apr 16, 2010: - added sinc()
#	Sep  7, 2012: - added acosh()
#	Jun  4, 2015: - added gaussRand()
#			 	  - made normal() more efficient

require	"$ANTS/libvec.pl";								# rad()

#----------------------------------------------------------------------
# gaussians/normal distribution
#----------------------------------------------------------------------

sub gauss(@)
{
	my($x,$peak,$mean,$efs) = &antsFunUsage(4,"ffff","x, peak, mean, e-folding scale",@_);
	return $peak * exp( -(($x-$mean) / $efs)**2);
}

sub normal(@)
{
	my($x,$area,$mean,$sigma) = &antsFunUsage(4,"ffff","x, area, mean, stddev",@_);
	my($sqrt2pi) = 2.506628274631;
	return $area/($sqrt2pi*$sigma) * exp(-((($x-$mean) / $sigma)**2)/2);
}

#----------------------------------------------------------------------
# &f(lat)			calculate coriolis param
#----------------------------------------------------------------------

sub f(@)
{
	my($lat) = &antsFunUsage(1,"f","lat",@_);
	my($Omega) = 7.292e-5;								# Gill (1982)

	return 2 * $Omega * sin(rad($lat));
}

#----------------------------------------------------------------------
# &sgn(v)			return -1/0/+1
#----------------------------------------------------------------------

sub sgn(@)
{
	my($val) = &antsFunUsage(1,"f","val",@_);
	return 0 if ($val == 0);
	return ($val < 0) ? -1 : 1;
}

#======================================================================

# rest of library cooked up from the diverse special function routines of NR
# Chapter 6. No attempt to clean up the code has been made.

#----------------------------------------------------------------------
# 6.1 Gamma Function et al
#----------------------------------------------------------------------

sub gammln(@)
{
	my($xx) = &antsFunUsage(1,"f","xx",@_);
	my($x,$y,$tmp,$ser);
	my(@cof) = (76.18009172947146, 	   -86.50532032941677,
				24.01409824083091,     -1.231739572450155,
				0.1208650973866179e-2, -0.5395239384953e-5);
	my($j);

	$x    = $xx;
	$y    = $x;
	$tmp  = $x + 5.5;
	$tmp -= ($x+0.5) * log($tmp);
	$ser  = 1.000000000190015;
	for ($j=0; $j<=5; $j++) {
		$ser += $cof[$j] / ++$y;
    }
	return -$tmp + log(2.5066282746310005*$ser/$x);
}

#----------------------------------------------------------------------
# 6.2. Incomplete Gamma Function, Error Function et al
#----------------------------------------------------------------------

{ my($ITMAX)=100; my($EPS)=3.0e-7;						# static vars

sub gser(@)
{
	my($a,$x,$glnR) =  &antsFunUsage(-2,"ff","a,x[,ref to gln]",@_);
	my($gln);
	my($n);
	my($sum,$del,$ap);

	$gln = &gammln($a);
	$$glnR = $gln if (defined($glnR));

	return 0 if ($x == 0);
	croak("$0 (libspecfuns.pl): x<0 ($x) in &gser()\n")
		if ($x < 0);

	$ap  = $a;
	$sum = 1 / $a;
	$del = $sum;
	for ($n=1; $n<=$ITMAX; $n++) {
		++$ap;
		$del *= $x/$ap;
		$sum += $del;
		return $sum * exp(-$x+$a*log($x)-$gln)
			if (abs($del) < abs($sum)*$EPS);
	}
	croak("$0 (libspecfuns.pl): a ($a) too large, " .
		"ITMAX ($ITMAX) too small in &gser()\n");
}

} # end of static scope

{ my($ITMAX)=100; my($EPS)=3.0e-7; my($FPMIN)=1.0e-30;	# static

sub gcf(@)
{
	my($a,$x,$glnR) =  &antsFunUsage(-2,"ff","a,x[,ref to gln]",@_);
	my($gln);
	my($i);
	my($an,$b,$c,$d,$del,$h);

	$gln = &gammln($a);
	$$glnR = $gln if (defined($glnR));

	$b = $x + 1 - $a;
	croak("$0 (libspecfuns.pl): illegal params (a = x + 1) in &gcf()\n")
		unless ($b);
	$c = 1 / $FPMIN;
	$d = 1 / $b;
	$h = $d;
	for ($i=1; $i<=$ITMAX; $i++) {
		$an = -$i * ($i - $a);
		$b += 2.0;
		$d  = $an * $d + $b;
		$d  = $FPMIN if (abs($d) < $FPMIN);
		$c  = $b + $an/$c;
		$c  = $FPMIN if (abs($c) < $FPMIN);
		$d  = 1 / $d;
		$del= $d * $c;
		$h *= $del;
		last if (abs($del-1) < $EPS);
	}
	croak("$0 (libspecfuns.pl): a ($a) too large," .
		" ITMAX ($ITMAX) too small in &gcf()\n")
		if ($i > $ITMAX);
	return exp(-$x + $a*log($x) - $gln) * $h;
}

} # end of static scope

sub gammq(@)
{
	my($a,$x) = &antsFunUsage(2,"ff","a,x",@_);
	croak("$0 (libspecfuns.pl): Invalid arguments in &gammq()\n")
		if ($x < 0 || $a <= 0);
	return ($x < ($a+1)) ?
		   1 - &gser($a,$x) :
		   &gcf($a,$x);
}

#----------------------------------------------------------------------

sub erfcc(@)
{
	my($x) = &antsFunUsage(1,"f","x",@_);
	my($t,$z,$ans);

	$z = abs($x);
	$t = 1/(1+0.5*$z);
	$ans = $t*exp(-$z*$z-1.26551223+$t*(1.00002368+$t*(0.37409196+$t*(0.09678418+
		   $t*(-0.18628806+$t*(0.27886807+$t*(-1.13520398+$t*(1.48851587+
		   $t*(-0.82215223+$t*0.17087277)))))))));
	return $x >= 0 ? $ans : 2.0-$ans;
}

{ my($warned) = 0; # static
	
sub erf(@)
{
	my($x) = &antsFunUsage(1,"f","x",@_);
	&antsInfo("(libspecfuns.pl) WARNING: using approximate erf()"),$warned=1
		unless ($warned);
	return 1-&erfcc($x);
}

}

#----------------------------------------------------------------------
# 6.3. Incomplete Beta Function et al
#----------------------------------------------------------------------

sub betai(@)
{
	my($a,$b,$x) = &antsFunUsage(3,"fff","a,b,x",@_);
	my($bt);

	croak("$0 (liberrf.pl): x (=$x) out of range in betai()\n")
		if ($x < 0 || $x > 1);
	if ($x == 0 || $x == 1) {
		$bt = 0;
	} else {
		$bt = exp(gammln($a+$b)-gammln($a)-gammln($b)+$a*log($x)+$b*log(1-$x));
	}
	if ($x < ($a+1)/($a+$b+2)) {
		return $bt * betacf($a,$b,$x) / $a;
	} else {
		return 1 - $bt*betacf($b,$a,1-$x) / $b;
	}
}

#----------------------------------------------------------------------

{ # static scope

	my($MAXIT) = 100;
	my($EPS)   = 3.0e-7;
	my($FPMIN) = 1.0e-30;

sub betacf(@)
{
	my($a,$b,$x) = &antsFunUsage(3,"fff","a,b,x",@_);
	my($m,$m2);
	my($aa,$c,$d,$del,$h,$qab,$qam,$qap);

	$qab = $a + $b;
	$qap = $a + 1;
	$qam = $a - 1;
	$c   = 1;
	$d   = 1 - $qab*$x/$qap;
	$d   = $FPMIN if (abs($d) < $FPMIN);
	$d   = 1 / $d;
	$h	 = $d;
	for ($m=1; $m<=$MAXIT; $m++) {
		$m2 = 2 * $m;
		$aa = $m*($b-$m)*$x / (($qam+$m2)*($a+$m2));
		$d  = 1 + $aa*$d;
		$d  = $FPMIN if (abs($d) < $FPMIN);
		$c	= 1 + $aa/$c;
		$c  = $FPMIN if (abs($c) < $FPMIN);
		$d  = 1 / $d;
		$h *= $d * $c;
		$aa = -($a+$m)*($qab+$m)*$x / (($a+$m2)*($qap+$m2));
		$d	= 1 + $aa*$d;
		$d  = $FPMIN if (abs($d) < $FPMIN);
		$c  = 1 + $aa/$c;
		$c  = $FPMIN if (abs($c) < $FPMIN);
		$d	= 1 / $d;
		$del= $d * $c;
		$h *= $del;
		last if (abs($del-1) < $EPS);
	}
	croak("$0 (liberrf.pl): a or b too big, or MAXIT too small in betacf")
		if ($m > $MAXIT);
	return $h;
}

} # end of static scope

#----------------------------------------------------------------------
# normalized cardinal sine as used, e.g., in JAOT/polzin02
#----------------------------------------------------------------------

sub sinc($)
{
	my($piX) = 3.14159265358979 * $_[0];
	return $piX==0 ? 1 : sin($piX)/$piX;
}

#----------------------------------------------------------------------
# inverse hyperbolic cosine; mathworld
#	- requires argument >= 1
#----------------------------------------------------------------------

sub acosh($)
{
	return log($_[0] + sqrt($_[0]**2-1));
}

#----------------------------------------------------------------------
# Gaussian random numbers
#	- optional argument is seed
#	- http://www.design.caltech.edu/erik/Misc/Gaussian.html
#	- algorithm generates 2 random numbers
#	- validated with plot '<count -o samp 1-100000 | list -Lfuns -c x=gaussRand() | Hist -cs 0.05 x',100000.0*0.05/sqrt(2*3.14159265358979)*exp(-x**2/2) wi li
#----------------------------------------------------------------------

{ my($y2);
  my($srand_called);

sub gaussRand(@)
{
	if (@_ && !$srand_called) {
		srand(@_);
		$srand_called = 1;
	}
	
	if (defined($y2)) {
		my($temp) = $y2;
		undef($y2);
		return $temp;
	}
	
	my($x1,$x2,$w);
	do {
		$x1 = 2 * rand() - 1;
		$x2 = 2 * rand() - 1;
		$w = $x1**2 + $x2**2;
	} while ($w >= 1);
	
	$w = sqrt((-2 * log($w)) / $w);
	$y2 = $x2 * $w;
	return $x1 * $w;
}

}

#----------------------------------------------------------------------

1;
