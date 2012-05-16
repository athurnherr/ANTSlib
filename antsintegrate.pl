#!/usr/bin/perl
#======================================================================
#                    A N T S I N T E G R A T E . P L 
#                    doc: Fri Feb 28 22:54:04 1997
#                    dlm: Fri Oct 15 23:14:11 2010
#                    (c) 1997 Andreas Thurnherr
#                    uE-Info: 27 62 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# Integrator Library; used by [integrate] and [transport]
#	([transport] is deprecated...)

# HISTORY:
#	Nov 14, 2000: - divorced from [integrate]
#	Nov 16, 2000: - added $opt_i
#				  - BUG: $opt_c forgot to output last record
#				  - BUG: copying of buffer had not worked
#	Nov 17, 2000: - changed $opt_i to $opt_l
#	Nov 24, 2000: - aimless changes
#	Mar 10, 2002: - added $dx output if $dfnr defined
#	Mar 30, 2002: - cosmetics
#	May 24, 2002: - added -b)ox to -f
#	May 25, 2002: - BUG: -c did not output records with missing y values
#				  - changed to dying on missing x values
#	Dec 20, 2005: - BUG: -cf produced short 1st record (dfnr not set)
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#	Oct 15, 2010: - removed warning about integrand set to nan

# NOTES:
#
#	&integrate() can run in several moments:
#		0:	integral
#		1:	integral weighted by (signed) distance from zero
#		2:	integral weighted by square of distance from zero
#
#	&integrate() returns the single-value sum; without -f @sum is
#	set as a side-effect
#  
#	unless xmin,xmax are given as args, the integral is taken over the
#	entire data
#
#	records with missing y values have the integrand(s) set to NaN
#
#	because this routine was ones an integral part of [integrate] it
#	uses a number of global variables (ug-lee!):
#		$xfnr					y = f(x)
#		$opt_c					output sum after each step (cummulative)
#		$opt_f					integrate only given field
#		  $yfnr   (if $opt_f)	... this one
#		  $opt_b				use box rule
#		  $iScale (if $opt_f)	scale integrated values
#		  $opt_l  (if $opt_f)	output individual summands

sub integrate ($@)										# ret integral, set $m
{
	my($moment,$zero,$xmin,$xmax) = @_;					# optional args
	my($lastx,$cur,$curwt,$sum,$cury);
	my($dx,$r,$f,@out,@nan,$warned);

	for ($f=0; $f<$antsBufNFields; $f++) {				# prep nan output
		$nan[$f] = nan;
	}

	for ($r=0; $r<=$#ants_; $r++) {
		croak("$0: can't handle non-numeric x values\n")
			unless (numberp($ants_[$r][$xfnr]));
	
#	1st, find a valid x value, and a y value on -f (one field only).
#	On -c, generate output: 0 on open limits, nan (only possible
#	if -f is set) otherwise
	
		unless (defined($lastx)) {
			if (defined($opt_f)) {
				if ($opt_c) {
					@out = @{$ants_[$r]};
					$out[$yfnr] = numberp($ants_[$r][$yfnr]) ? 0 : nan;
					$out[$dfnr] = nan if (defined($dfnr));
					&antsOut(@out);
				}
				next unless (numberp($ants_[$r][$yfnr]));
				$lastx = $ants_[$r][$xfnr];
				croak("$0: lower limit ($xmin) < first valid x-value ($lastx)\n")
					if (defined($xmin) && $lastx > $xmin);  
				$lasty = $ants_[$r][$yfnr];
				next;
			}
			$lastx = $ants_[$r][$xfnr];
			if ($opt_c) {
				for ($f=0; $f<$antsBufNFields; $f++) {
					$out[$f] = ($f == $xfnr) ? $ants_[$r][$f] :
									(numberp($ants_[$r][$f]) ? 0 : nan);
				}
				&antsOut(@out);
			}
			next;
		}
	
#	next, update x&y while below lower limit for later interpolation
#	NB: only possible on -f!
	
		if (defined($xmin) && $ants_[$r][$xfnr] < $xmin) {
			if (numberp($ants_[$r][$yfnr])) {
				$lastx = $ants_[$r][$xfnr];
				$lasty = $ants_[$r][$yfnr];
            }
			if ($opt_c) {
				$ants_[$r][$yfnr] = nan;
				&antsOut(@{$ants_[$r]});
            }
			next;
		}
	
#	we have an x-value > min; is it valid?
#	NB: xmin is undefined once lower limit is handled
	
		croak("$0: Error: no data within integration limits\n")
			if (defined($xmin) && defined($xmax) && $ants_[$r][$xfnr] > $xmax);
	
#	finally! we have a valid x-value; if it's the first, interpolate
#	y at xmin if that's defined
#	undefined xmin at end so this code is not executed again
#	NB: xmin can only be defined on -f!
	
		if (defined($xmin)) {
			unless (numberp($ants_[$r][$yfnr])) {
				if ($opt_c) {
					$ants_[$r][$yfnr] = nan;
					&antsOut(@{$ants_[$r]});
				}
				next;
			}
			$lasty += ($xmin-$lastx) / ($ants_[$r][$xfnr]-$lastx)
						* ($ants_[$r][$yfnr]-$lasty);
			$lastx = $xmin; undef($xmin);
		}
	
#	it is also possible (though not on the first time round), that we
#	have just passed the upper limit (xmax); simulate normal code but
#	using xmax (and interpolated y value) instead of real data
#	NB: xmax can only be defined on -f!
	
		if (defined($xmax) && $ants_[$r][$xfnr] >= $xmax) {
			unless (numberp($ants_[$r][$yfnr])) {
				if ($opt_c) {
					$ants_[$r][$yfnr] = nan;
					&antsOut(@{$ants_[$r]});
				}
				next;
			}
			$dx = $xmax - $lastx;
			$cury = $lasty + $dx / ($ants_[$r][$xfnr]-$lastx)
								* ($ants_[$r][$yfnr]-$lasty);
			croak("$0: x-field must be monotonically increasing [xmax=$xmax, lastx=$lastx]\n")
				if ($dx < 0);
			$cur  = ($cury+$lasty)/2 * $dx;
			$cur *= (($xmax+$lastx)/2-$zero)**$moment if ($moment);
			$sum += $cur*$iScale;
			if ($opt_c) {								# cummulative
				@out = @{$ants_[$r]};					# copy everything
				$out[$yfnr] = $sum;
				$out[$dfnr] = $dx if (defined($dfnr));
				&antsOut(@out);
			} elsif ($opt_l) {							# individual summands
				@out = @{$ants_[$r]};					# copy everything
				$out[$yfnr] = $cur*$iScale;
				$out[$dfnr] = $dx if (defined($dfnr));
				&antsOut(@out);
            }
            $lastx = $ants_[$r][$xfnr];
			last;
		}
	
#	phoar! we are finally handling the normal case  
	
		$dx = $ants_[$r][$xfnr] - $lastx;				# calc dx
		croak("$0: x-field must be monotonically increasing [curx=$ants_[$r][$xfnr], lastx=$lastx]\n")
			if ($dx < 0);
	
		if (defined($opt_f)) {							# integrate single field
			unless (numberp($ants_[$r][$yfnr])) {
				if ($opt_c) {
					$ants_[$r][$yfnr] = nan;
					&antsOut(@{$ants_[$r]});
				}
				next;
			}
			$cur = $opt_b ?
				$ants_[$r][$yfnr] * $dx :				# box rule
				($ants_[$r][$yfnr]+$lasty)/2 * $dx; 	# interpolate
			$cur *= (($ants_[$r][$xfnr]+$lastx)/2-$zero)**$moment
				if ($moment);
			$sum += $cur*$iScale;
			$lasty = $ants_[$r][$yfnr];
			if ($opt_c) {								# cummulative
				@out = @{$ants_[$r]};					# copy everything
				$out[$yfnr] = $sum;
			} elsif ($opt_l) {							# individual summands
				@out = @{$ants_[$r]};					# copy everything
				$out[$yfnr] = $cur*$iScale;
            }			
		} else {										# integrate all
			for ($f=0; $f<$antsBufNFields; $f++) {
				next if ($f == $xfnr);					# except x-field
				if (numberp($ants_[$r][$f]))	{		# val found
					$sum[$f] += $ants_[$r][$f] * $dx	# box-rule (no interp)
						unless isnan($sum[$f]);			# had missing vals
				} else {								# val missing 
					$sum[$f] = nan; 					# mark for later
#					unless ($warned) {					# warn user
#						&antsInfo("Warning: integrand(s) set to nan due to missing vals");
#						$warned = 1;
#					}
				}
				$out[$f] = $sum[$f] if ($opt_c);
			}
		}
		if ($opt_c || $opt_l) {
			$out[$xfnr] = $ants_[$r][$xfnr];
			$out[$dfnr] = $dx if (defined($dfnr));
			&antsOut(@out);
		}
		$lastx = $ants_[$r][$xfnr];						# last good x
	}
	croak("$0: empty input!\n")							# never initialized
	    unless (defined($lastx));
	croak("$0: upper limit > last valid x-value!\n")
	    if (defined($xmax) && $xmax>$lastx);

	return $sum;
}

1;
