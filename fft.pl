#======================================================================
#                    F F T . P L 
#                    doc: Fri Mar 12 09:20:33 1999
#                    dlm: Mon Jul 24 14:58:04 2006
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 241 36 NIL 0 0 72 66 2 4 NIL ofnI
#======================================================================

# Notes:
#	It was found when rotary-analysing the FLAME current meters that
#	the sign of the frequencies returned was wrong. When investigating
#	the problem it was found that there are two conventions, one called
#	the engineering convention which is followed by Bendat & Piersol
#	[1971], Gonella [1972], and Mooers [1973] but not Numerical Recipes.
#	For real-valued functions it does not matter because the power
#	of the positive and negative frequencies are summed. The engineering
#	convention appears more sensible, however, because it actually leads
#	to the anticlockwise component to be reported as positive frequencies
#	which is consistent with exp(i phi) = cos phi + i sin phi and the
#	usual axes orientations.

# HISTORY:
#	Mar 12, 1999: - adapted from NR
#	Mar 13, 1999: - ``perlified'' (0-relative arrays; return value)
#	Mar 14, 1999: - cosmetic changes
#	Mar 15, 1999: - pad initial/final NaN values with 0es
#	Dec 08, 1999: - adapted for complex FFT
#	Dec 09, 1999: - continued
#	Dec 10, 1999: - BUG: < replaced by <= (no difference)
#	Dec 11, 1999: - investigated wrong frequency sign
#	Dec 14, 1999: - changed one-sided spectra to get half of the f=0 power
#	Mar 04, 2000: - require mean-removal when zero-padding is used
#				  - BUG (cosmetic)
#	Mar 05: 2000: - BUG: died even if no padding was done
#	Mar 08, 2000: - removed opt_r hard-coding
#	May 02, 2001: - BUG: RMS was really standard deviation estimator
#	Aug 29, 2003: - BUG: &icFFT did not calc sigma correctly whenever
#						 infield == outfield (e.g. [fftfilt] w/o -f)
#	Mar 31, 2004: - added cFFT_bufR()
#	Feb  9, 2005: - added &phase_pos(), &phase_neg()
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#   Jul 24, 2006: - modified to use $PRACTICALLY_ZERO

#----------------------------------------------------------------------
# FOUR1 routine
#
# Notes:
#	- nan will abort FFT!
#	- added power of two assertions
#	- arrays are 0-relative
#	- isig should be set to -1 for FFT and to 1 for reverse FFT (see
#	  note above)
#
#----------------------------------------------------------------------

sub FOUR1($@) # ($isign, @data) => @fourier coefficients
{
	my($isign,@data) = @_;
	my($n,$mmax,$m,$j,$istep,$i);
	my($wtemp,$wr,$wpr,$wpi,$wi,$theta);
	my($tempr,$tempi);
	my($N) = @data / 2;

	$n = $N << 1;										# re-order input
	$j = 0;
	for ($i=0; $i<$n-1; $i+=2) {
		if ($j > $i) {
			$tempr = $data[$j];
			$tempi = $data[$j+1];
			$data[$j]   = $data[$i];
			$data[$j+1] = $data[$i+1];
			$data[$i]   = $tempr;
			$data[$i+1] = $tempi;
        }
        croak("$0 (fft.pl) $N is not a power of two\n")
        	if ($n % 2);
		$m = $n >> 1;
		while ($m >= 2 && $j >= $m) {
			$j -= $m;
			croak("$0 (fft.pl) $N is not a power of two\n")
	            if ($m % 2);
			$m >>= 1;
		}
		$j += $m;
	}

#	for ($i=0; $i<=$#data; $i+=2) {						# dump data
#		print(STDERR "$data[$i]$opt_O$data[$i+1]$opt_R")
#	}

	$mmax = 2;											# do FFT
	while ($n > $mmax) {
		$istep = $mmax << 1;
		$theta = $isign*(6.28318530717959/$mmax);
		$wtemp = sin(0.5*$theta);
		$wpr   = -2.0*$wtemp*$wtemp;
		$wpi   = sin($theta);
		$wr    = 1.0;
		$wi    = 0.0;
		for ($m=0; $m<$mmax-1; $m+=2) {
			for ($i=$m; $i<=$n-1; $i+=$istep) {
				$j     = $i + $mmax;
				$tempr = $wr*$data[$j]   - $wi*$data[$j+1];
				$tempi = $wr*$data[$j+1] + $wi*$data[$j];
				$data[$j]    = $data[$i]   - $tempr;
				$data[$j+1]  = $data[$i+1] - $tempi;
				$data[$i]   += $tempr;
				$data[$i+1] += $tempi;
			}
			$wtemp = $wr;
			$wr    = $wr*$wpr - $wi*$wpi    + $wr;
			$wi    = $wi*$wpr + $wtemp*$wpi + $wi;
		}
		$mmax = $istep;
	}

	return @data;
}

#----------------------------------------------------------------------
# TWOFFT routine
#
# Notes:
#	- arrays are 0-relative
#	- array references are used throughout; input arrays are 
#     in $ants_[][] style; ouput are simple arrays
#	- isign convention of NR is used here!!!
#----------------------------------------------------------------------

sub TWOFFT($$$$$$)
{
	my($data1R,$fnr1,$data2R,$fnr2,$fft1R,$fft2R) = @_;
	my($nn3,$nn2,$jj,$j);
	my($rep,$rem,$aip,$aim);
	my($n) = scalar(@{$data1R});

	$nn3 = 1 + ($nn2 = 2 + $n + $n);
	for ($j=1,$jj=2; $j<=$n; $j++,$jj+=2) {
		$fft1R->[$jj-2] = $data1R->[$j-1][$fnr1];
		$fft1R->[$jj-1] = $data2R->[$j-1][$fnr2];
	}
	@{$fft1R} = FOUR1(1,@{$fft1R});
	$fft2R->[0] = $fft1R->[1];
	$fft1R->[1] = $fft2R->[1] = 0;
	for ($j=3; $j<=$n+1; $j+=2) {
		$rep = 0.5 * ($fft1R->[$j-1] + $fft1R->[$nn2-$j-1]);
		$rem = 0.5 * ($fft1R->[$j-1] - $fft1R->[$nn2-$j-1]);
		$aip = 0.5 * ($fft1R->[$j] + $fft1R->[$nn3-$j-1]);
		$aim = 0.5 * ($fft1R->[$j] - $fft1R->[$nn3-$j-1]);
		$fft1R->[$j-1] = $rep;
		$fft1R->[$j]   = $aim;
		$fft1R->[$nn2-$j-1] =  $rep;
		$fft1R->[$nn3-$j-1] = -$aim;
		$fft2R->[$j-1] =  $aip;
		$fft2R->[$j]   = -$rem;
		$fft2R->[$nn2-$j-1] = $aip;
		$fft2R->[$nn3-$j-1] = $rem;
	}
}

#----------------------------------------------------------------------
# Interface to @ants_
#
# Notes:
#	- N (number of complex samples) calculated as next larger pwr-of-two
#	  if set to 0 on calling; otherwise set is used
#	- @ants_ padded with 0es to $N (deprecated in Hamming [1989])
#	- ditto initial and final missing values
#	- set ifnr to nan if input is purely real
#
#----------------------------------------------------------------------

sub cFFT($$$) { return cFFT_bufR(\@ants_,@_); }

sub cFFT_bufR($$$) # ($bufR, $rfnr, $ifnr, [$N]) => @coeff
{
	my($bufR,$fnr,$ifnr,$N) = @_;
	my(@data,$i,$lastSet);

	unless ($N) {									# $N not set
		for ($N=1; $N <= $#ants_; $N <<= 1) {}		# next greater pwroftwo
		&antsInfo("(fft.pl) N set to $N")
			unless ($N == $#ants_+1);
	}
	for ($i=0; $i<$N && $i<=$#ants_; $i++) {		# PAD
		last if (numberp($bufR->[$i][$fnr]) &&
				 (isnan($ifnr) || numberp($bufR->[$i][$ifnr])));
		$data[2*$i]   = 0;
		$data[2*$i+1] = 0;
	}
	$lastSet = $i - 1;
	&antsInfo("(fft.pl) WARNING: $i initial non-numbers padded with 0es!!!"),
		$padded=1 if ($i);
	while ($i<$N && $i<=$#ants_) {					# fill
		$i++,next unless (numberp($bufR->[$i][$fnr]) &&	# skip non-numbers 
				          (isnan($ifnr) || numberp($bufR->[$i][$ifnr])));
		croak("$0: (fft.pl) $lastSet, $i can't handle missing values ($bufR->[$lastSet+1][$fnr])!\n")
			if ($lastSet != $i-1);					# missing values
		$data[2*$i]   = $bufR->[$i][$fnr];			# real
		$data[2*$i+1] = isnan($ifnr) ? 0 : $bufR->[$i][$ifnr];	# imag
		$lastSet = $i;
		$i++;
	}
	&antsInfo("(fft.pl) WARNING: %d final non-numbers padded with 0es!!!",$i-$lastSet-1),
		$padded=1 if ($i > $lastSet+1);
	&antsInfo("(fft.pl) WARNING: padded with %d 0es to next pwr-of-two!!!",$N-$i),
		$padded=1 if ($i < $N);
	croak("$0: (fft.pl) refusing to pad with zeroes unless mean is removed (sorry)\n")
		if ($padded && !$FFT_ALLOW_ZERO_PADDING);
	$i = $lastSet + 1;
	while ($i < $N) {								# PAD
		$data[2*$i]   = 0;
		$data[2*$i+1] = 0;
		$i++;
	}
	return &FOUR1(-1,@data);
}

sub icFFT($$@) # ($ofnr, $tfnr, @coeff) => sigma
{
	my($ofnr,$tfnr,@coeff) = @_;
	my($N) = ($#coeff+1)/2;
	my(@val) = &FOUR1(1,@coeff);
	my($i);
	my($n) = 0;
	my($sumsq) = 0;
	my($mai) = 0;

	for ($i=0; $i<$N && $i<=$#ants_ ; $i++) {		# fill
		my($oldval) = $ants_[$i][$ofnr];
		push(@{$ants_[$i]},nan)						# pad empty fields
			while ($#{$ants_[$i]} < $tfnr);
		$ants_[$i][$tfnr] = $val[2*$i]/$N;			# real
		$mai = abs($val[2*$i+1])					# imag
			if (abs($val[2*$i+1]) > $mai);
		next unless (numberp($oldval));	# sigma
		$sumsq += ($oldval - $ants_[$i][$tfnr])**2;
		$n++;
	}
	&antsInfo("(fft.pl) WARNING: imaginary exponents (abs <= $mai) ignored")
		if ($mai > $PRACTICALLY_ZERO);
	&antsInfo("(fft.pl) WARNING: reducing data (%d -> %d)",$#ants_+1,$N)
		if ($i <= $#ants_);
	while ($i <= $#ants_) {
		$ants_[$i][$fnr] = nan;
		$i++;
    }
    return ($n > 1) ? sqrt($sumsq/($n-1)) : nan;
}

#----------------------------------------------------------------------
# Periodogram (p.421; (12.7.5) -- (12.7.6))
#----------------------------------------------------------------------

# Miscellaneous Notes:
#
# - there are N/2 + 1 values in the (unbinned) PSD (see NR)

# Notes regarding the effects of zero padding:
#
# - using zero-padding on a time series where the mean is not removed
#	can result in TOTALLY DIFFERENT RESULTS, try it e.g. with
#	temperatures!!! (A moment's thought will reveal why)
#
# - Because the total power is normalized to the mean squared amplitude
#	0-padded values depress the power; this was taken care of below by
#	normalizing the power by multiplying it with nrm=(nData+nZeroes)/nData;
#
# - this was checked using `avg -m' (in case of complex input the total
#	power is given by sqrt(Re**2+Im**2));
#
# - if zero-padding is used sqrt(nrm*P[0]) is mean value (done in [pgram])

# Notes on interpreting the power spectrum (Hamming [1989] & NR):
#
# - the frequency spectrum encompasses the frequencies between 0 (the
#	mean value) and the Nyquist frequency (1 / (2 x sampling interval))
#
# - higher frequencies are aliased into the power spectrum in a mirrored
#   way (e.g. noise tends to (linearly?) approach zero as f goes to inft;
#   the downsloping spectrum `hits' the Nyquist frequency, turns around
#   and continues falling towards the zero frequency, where it gets mirrored
# 	again => spectrum flattens towards Nyquist frequency
#
# - the sum over all P's (total power) is equal to the mean square value;
#	when one-sided spectra are used, P[0] and P[N/2] are counted doubly
#	and must be subtracted from the total; NB: the total power is reduced
#	if data are padded with 0es
#   
# - sqrt(P[0]) is an estimate for the mean value which is only accurate
#   if no zero-padding is perfomed; removing the mean will
#	strongly change the spectrum near the origin which might
#   or might not be a good thing, depending on the physics behind it (e.g.
#	it makes sense to remove the mean if a power spectrum from a temperature
#	record is calculated but not if flow velocity is used).
#   Removing higher order trends will also affect the spectrum but not
#   in such a simple fashion. Note that the problem is mainly restricted
#   to cases where the signal is in the low frequency and thus affected
#	by the strong changes in the spectrum there.

# Notes on the two-sided spectra:
# - the power of the mean flow (sqrt(P[0])) is non-rotary. To have the sum
#	of both one-sided spectra equal the two-sided one, each one-sided
#	spectrum gets half of the total value.
# - the same is true for the highest frequency; at the Nyquist frequency
#	every rotation is sampled exactly twice => polarization cannot be
#	determined (imagine a wheel with one spoke...)


sub pgram_onesided(@) # $nData,@C -> return @P
{
	my($nData,@C) = @_;
	my($N)    = ($#C+1) / 2;				# number of fourier comps
	my($Pfac) = $N**(-2) * $N/$nData;		# normalized to mean-sq amp
	my($k,@P);

	$P[0] = $Pfac * ($C[0]**2 + $C[1]**2);	# calc periodogram
	for ($k=1; $k<=$N/2-1; $k++) {
		$P[$k] = $Pfac * ($C[2*$k]**2 + $C[2*$k+1]**2 +
						  $C[2*($N-$k)]**2 + $C[2*($N-$k)+1]**2);
	}
	$P[$N/2] = $Pfac * ($C[2*($N/2)]**2 + $C[2*($N/2)+1]**2);
	return @P;
}

sub pgram_pos(@) # $nData,@C -> return @P
{
	my($nData,@C) = @_;
	my($N)    = ($#C+1) / 2;				# number of fourier comps
	my($Pfac) = $N**(-2) * $N/$nData;		# normalized to mean-sq amp
	my($k,@P);

	$P[0] = 0.5 * $Pfac * ($C[0]**2 + $C[1]**2);	# calc periodogram
	for ($k=1; $k<=$N/2-1; $k++) {
		$P[$k] = $Pfac * ($C[2*$k]**2 + $C[2*$k+1]**2);
	}
	$P[$N/2] = 0.5 * $Pfac * ($C[2*($N/2)]**2 + $C[2*($N/2)+1]**2);
	return @P;
}

sub pgram_neg(@) # $nData,@C -> return @P
{
	my($nData,@C) = @_;
	my($N)    = ($#C+1) / 2;				# number of fourier comps
	my($Pfac) = $N**(-2) * $N/$nData;		# normalized to mean-sq amp
	my($k,@P);

	$P[0] = 0.5 * $Pfac * ($C[0]**2 + $C[1]**2);	# calc periodogram
	for ($k=1; $k<=$N/2-1; $k++) {
		$P[$k] = $Pfac * ($C[2*($N-$k)]**2 + $C[2*($N-$k)+1]**2);
	}
	$P[$N/2] = 0.5 * $Pfac * ($C[2*($N/2)]**2 + $C[2*($N/2)+1]**2);
	return @P;
}

#------------------------------------------------------------------------
# Current Ellipses (Emery and Thomson, 5.6.4.2 (Rotary Component Spectra)
#------------------------------------------------------------------------

# Notes on phase (ellipsis inclination) calculations:
#	- comparing equations 5.6.42 and 5.6.43 in E+T shows a sign
#	  sign change of one of the terms (U_2k - V_1k in eqn 5.6.42a)
#	- for reasons of symmetry, this is unlikely to be correct
#	- in order to test this, I compared the M2 ellipses inclinations of
#	  a tidal analysis of BBTRE instruments #1 & #3 with the output
#	  and found that changing the sign in 5.6.43a brought the values
#	  into agreement (#1: tidal analysis 155+-3, pgram -25; #3: 136+-5,
#	  pgram -44)
#	- the changes are marked in the code by a (superfluous) + sign
#	- the sign change was later found to be consistent with the
#	  tidal analysis package manual by MGG Foreman (p.11)

sub phase_pos(@) # @C -> return @eps
{
	my(@C) = @_;
	my($N) = ($#C+1) / 2;				# number of fourier comps
	my($k,@eps);

	$eps[0] = 180 / $PI * atan2(+$C[1],$C[0]);
	for ($k=1; $k<=$N/2-1; $k++) {
		$eps[$k] = 180 / $PI * atan2(+$C[2*$k+1],$C[2*$k]);
	}
	$eps[$N/2] = 180 / $PI * atan2(+$C[2*($N/2)+1],$C[2*($N/2)]);
	return @eps;
}

sub phase_neg(@) # @C -> return @P
{
	my(@C) = @_;
	my($N) = ($#C+1) / 2;				# number of fourier comps
	my($k,@P);

	$eps[0] = 180 / $PI * atan2(+$C[1],$C[0]);
	for ($k=1; $k<=$N/2-1; $k++) {
		$eps[$k] = 180 / $PI * atan2(+$C[2*($N-$k)+1],$C[2*($N-$k)]);
	}
	$eps[$N/2] = 180 / $PI * atan2(+$C[2*($N/2)+1],$C[2*($N/2)]);
	return @eps;
}

#----------------------------------------------------------------------

1;
