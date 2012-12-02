#======================================================================
#                    L I B S T A T S . P L 
#                    doc: Wed Mar 24 13:59:27 1999
#                    dlm: Mon Oct 15 10:34:21 2012
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 90 30 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 24, 1999: - created for the ANO paper
#	Mar 27, 1999: - extended
#	Sep 18, 1999: - argument typechecking
#	Sep 30, 1999: - added gauss()
#	Oct 04, 1999: - moved gauss() to [./libfuns.pl] (changed from specfuns)
#	Oct 20, 1999: - changed, 'cause I understand it better
#	Oct 21, 1999: - changed &Fishers_z to &r2z(); added &z2r()
#				  - added &sig_rr(), &sig_rrtrue
#	Jan 22, 2002: - added N(), avg(), stddev(), min(), max()
#	Feb 27, 2006: - adjusted median() for compat with NR (even # of points)
#				  - added medianF()
#	Jun 27, 2006: - added medianFNaN()
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#				  - made median respect nan based on perlfunc(1)
#	Apr 25, 2008: - added &bootstrap()
#	Oct 24, 2010: - replaced grep { $_ == $_ } by grep { numberp($_) } everywhere
#				  - added &fixLowSampStat()
#	Nov  5, 2010: - added std (stderr would have been better but that's used in libPOSIX.pl
#	Dec 18, 2010: - added stddev2, mad, mad2
#	Dec 31, 2010: - added rms()
#	Jul  2, 2011: - added mad2F()
#	Mar 10, 2012: - medianF() -> medianAnts_(); mad2F() -> mad2Ants_()
#				  - added sum()
#	Apr 26, 2012: - BUG: std() did not allow nan as stddev input
#	Oct 15, 2012: - added max_i(), min_i()

require "$ANTS/libfuns.pl";

#----------------------------------------------------------------------
# estimate stderr given stddev & degrees of freedom
#	- return nan for dof <= 0
#----------------------------------------------------------------------

sub std(@)
{
	my($sig,$dof) = 
		&antsFunUsage(2,".c","stddev, deg_of_freedom",@_);
	return nan unless ($dof > 0);
	return $sig / sqrt($dof);
}

#----------------------------------------------------------------------
# calc standard stats from vector of vals
#----------------------------------------------------------------------

sub min(@)
{
	my($min) = 9e99;
	for (my($i)=0; $i<=$#_; $i++) {
		$min = $_[$i] if (numberp($_[$i]) && $_[$i] < $min);
	}
	return $min<9e99 ? $min : nan;
}

sub min_i(@)
{
	my($min) = 9e99;
	my($min_i);
	
	for (my($i)=0; $i<=$#_; $i++) {
		$min_i=$i,$min=$_[$i] if (numberp($_[$i]) && $_[$i] < $min);
	}
	return $min<9e99 ? $min_i : nan;
}

sub max(@)
{
	my($max) = -9e99;
	for (my($i)=0; $i<=$#_; $i++) {
		$max = $_[$i] if (numberp($_[$i]) && $_[$i] > $max);
	}
	return $max>-9e99 ? $max : nan;
}

sub max_i(@)
{
	my($max) = -9e99;
	my($max_i);
	
	for (my($i)=0; $i<=$#_; $i++) {
		$max_i=$i,$max=$_[$i] if (numberp($_[$i]) && $_[$i] > $max);
	}
	return $max>-9e99 ? $max_i : nan;
}

sub N(@)
{
	my($N) = 0;
	for (my($i)=0; $i<=$#_; $i++) { $N++ if (numberp($_[$i])); }
	return $N;
}

sub sum(@)
{
	my($N) = my($sum) = 0;
	for (my($i)=0; $i<=$#_; $i++) { $N++,$sum+=$_[$i] if (numberp($_[$i])); }
	return ($N>0)?$sum:nan;
}

sub avg(@)
{
	my($N) = my($sum) = 0;
	for (my($i)=0; $i<=$#_; $i++) { $N++,$sum+=$_[$i] if (numberp($_[$i])); }
	return ($N>0)?$sum/$N:nan;
}

sub stddev2(@)		# avg, val, val, val, ...
{
	my($N) = my($sum) = 0;
	for (my($i)=1; $i<=$#_; $i++) {
		$N++,$sum+=($_[0]-$_[$i])**2 if (numberp($_[$i]));
	}
	return ($N>1)?sqrt($sum/($N-1)):nan;
}

sub stddev(@)
{
	my($avg) = &avg(@_);
	return numberp($avg) ? stddev2($avg,@_) : nan;
}

sub rms(@)
{
	my($N) = my($sum) = 0;
	for (my($i)=0; $i<=$#_; $i++) { $N++,$sum+=$_[$i]**2 if (numberp($_[$i])); }
	return ($N>0)?sqrt($sum/$N):nan;
}

sub median(@)
{
	my(@svals) = sort {$a <=> $b} grep { numberp($_) } @_;
	return nan if (@svals == 0);
	return (@svals & 1) ?
				$svals[$#svals/2] :
				0.5 * ($svals[$#svals/2] + $svals[$#svals/2+1]);
}

sub medianAnts_($)
{
	my($fnr) = @_;
	my(@svals) = sort {@{$a}[$fnr] <=> @{$b}[$fnr]} grep { numberp(@{$_}[$fnr]) } @ants_;
	return nan if (@svals == 0);
	return (@svals & 1) ?
				$svals[$#svals/2][$fnr] :
				0.5 * ($svals[$#svals/2][$fnr] + $svals[$#svals/2+1][$fnr]);
}

sub mad2(@)		# avg, val, val, val, ...
{
	my($N) = my($sum) = 0;
	for (my($i)=1; $i<=$#_; $i++) {
		$N++,$sum+=abs($_[0]-$_[$i]) if (numberp($_[$i]));
	}
	return ($N>0)?sqrt($sum/$N):nan;
}

sub mad(@)
{
	my($median) = &median(@_);
	return numberp($median) ? mad2($median,@_) : nan;
}

sub mad2Ants_($$)
{
	my($median,$fnr) = @_;
	my($sum,$n);

	for (my($r)=0; $r<@ants_; $r++) {
		next unless numberp($ants_[$r][$fnr]);
		$sum += abs($median - $ants_[$r][$fnr]);
		$n++
	}
	return ($n>0) ? $sum/$n : nan;
}

#----------------------------------------------------------------------
# &bootstrap(nDraw,cLim,statFun,val[,...])
#		nDraw		number of synthetic samples to draw
#		cLim		confidence limit (e.g. 0.95)
#		statFun		pointer to stats function
#		val[,...]	data values
#
# e.g.  bootstrap(1000,.5,\&avg,1,2,1000)
#----------------------------------------------------------------------

sub bootstrap($$$@)
{
	my($nDraw,$cLim,$statFun,@vals) = @_;
	my(@sv,@stats);

	for (my($s)=0; $s<$nDraw; $s++) {
		for (my($i)=0; $i<@vals; $i++) {
			$sv[$i] = $vals[int(rand(@vals))];
		}
		$stats[$s] = &$statFun(@sv);
	}
	@stats = sort {$a <=> $b} grep { numberp($_) } @stats;
	my($cli) = int($nDraw*(1-$cLim)/2);
	return ($stats[$cli],$stats[$#stats-$cli]);
}

#----------------------------------------------------------------------
# &fixLowSampStat(statRef,nsamp[])
#	- replace stat (variance, stddev, stderr) based on small (<10) samples
#	  with median calculated from all stats
#	- median of all stats is chosen to allow routine to work even if all
#	  stats are based on small samples
#----------------------------------------------------------------------

sub fixLowSampStat($@)
{
	my($statR,@nsamp) = @_;
	
	my($medStat) = median(@{$statR});
	for (my($i)=0; $i<@{$statR}; $i++) {
		$statR->[$i] = $medStat
			unless ($nsamp[$i]>=10 || !defined($statR->[$i]) || $statR->[$i]>$medStat);
	}
}

#----------------------------------------------------------------------
# significance of difference of means (NR, 2nd ed, 14.2)
#----------------------------------------------------------------------

sub Students_t(@)
{
	my($mu1,$sig1,$N1,$mu2,$sig2,$N2) =
		&antsFunUsage(6,"ffcffc","mu1, sigma1, N1, mu2, sigma2, N2",@_);
	my($var1) = $sig1 * $sig1;
	my($var2) = $sig2 * $sig2;
	my($sd) = sqrt($var1 + $var2 / ($N1+$N2-2) * (1/$N1 + 1/$N2));
	return ($mu1-$mu2) / $sd;
}

sub slevel_mudiff1(@)
{
	my($mu1,$sig1,$N1,$mu2,$sig2,$N2) =
		&antsFunUsage(6,"ffcffc","mean1, sqrt(var1), N1, mean2, sqrt(var2), N2",@_);
	my($df) = $N1 + $N2 - 2;
	return &betai(0.5*$df,0.5,
		$df/($df + &Students_t(mu1,$sig1,$N1,$mu2,$sig2,$N2)**2));
}

#----------------------------------------------------------------------
# significance of correlation coefficient (NR, 2nd ed, 14.5)
#----------------------------------------------------------------------

sub slevel_r(@)
{
	my($r,$N) = &antsFunUsage(2,"fc","r, N",@_);
	return &erfcc(abs($r) * sqrt($N/2));
}

#----------------------------------------------------------------------
# significance of difference btw two measured correlation coeffs
# using Fisher's z (from NR, 2nd ed, 14.5). NB: averaging correlation
# coefficients is done using [avgr]
# NB: significance level is only good if correlated variables form
#	  a binormal distribution
#----------------------------------------------------------------------

sub r2z(@)
{
	my($r) = &antsFunUsage(1,"f","<r>",@_);
	return 0.5 * log((1+$r)/(1-$r));
}

sub z2r(@)
{
	my($z) = &antsFunUsage(1,"f","<z>",@_);
	my($e) = exp(2*$z);
	return ($e-1) / ($e+1);
}

sub slevel_rrtrue(@)
{
	my($r,$N,$rtrue) = &antsFunUsage(3,"fcf","r, N, r_true",@_);
	croak("$0 (libstats.pl): N (=$N) < 10 in &slevel_rrtrue()\n")
		if ($N < 10);
	return &erfcc(abs(&r2z($r) - (&r2z($rtrue) + $rtrue/(2*$N-2))) *
				sqrt($N - 3) / sqrt(2));
}

sub slevel_zz(@)
{
	my($z1,$N1,$z2,$N2) = &antsFunUsage(4,"fcfc","z1, N1, z2, N2",@_);
	croak("$0 (libstats.pl): N (=$N1,$N2) < 10 in &slevel_zz()\n")
		if ($N1 < 10 || $N2 < 10);
	return &erfcc(abs($z1-$z2) / sqrt(2/($N1-3) + 2/($N2-3)));
}

sub slevel_rr(@)
{
	my($r1,$N1,$r2,$N2) = &antsFunUsage(4,"fcfc","r1, N1, r2, N2",@_);
	return &slevel_zz(&r2z($r1),$N1,&r2z($r2),$N2);
}

#----------------------------------------------------------------------
# significance of difference btw two measured correlation coeffs
# from brookes+dick63, p.216f
# NB: result is returned as ratio of difference in Fisher's z to
#	  standard error of Fisher's z; values >> 1 indicate that difference
#	  is significant
#----------------------------------------------------------------------

sub sig_rrtrue(@)
{
	my($r,$N,$rtrue) = &antsFunUsage(3,"fcf","r, N, r_true",@_);
	return abs(&r2z($r) - &r2z($rtrue)) * sqrt($N-3);

}

sub sig_rr(@)
{
	my($r1,$N1,$r2,$N2) = &antsFunUsage(4,"fcfc","r1, N1, r2, N2",@_);
	return abs(&r2z($r1) - &r2z($r2)) / (1/sqrt($N1-3)+1/sqrt($N2-3));
}

#----------------------------------------------------------------------

1;

