#======================================================================
#                    L I B I M P . P L 
#                    doc: Tue Nov 26 21:59:40 2013
#                    dlm: Thu Jul 14 19:19:47 2022
#                    (c) 2017 A.M. Thurnherr
#                    uE-Info: 72 79 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov 26, 2013: - created
#	Dec  1, 2013: - removed HDG_ROT
#				  - added support for IMP data gaps
#	Mar  4, 2014: - added support for DATA_SOURCE_ID
#	May 22, 2014: - use +/-2deg to assess quality of heading offset
#	May 23, 2014: - added $dhist_binsize, $dhist_min_pirom
#	Jul 27, 2016: - updated variable names for consistency
#	Jul 28, 2016: - major re-write if merging routines
#	Jul 29, 2016: - cosmetics
#				  - increased heading-offset resolution from 2 to 1 degrees
#				  - BUG: inconsistent heading definition used (from old IMP with
#						 confused coordinates)
#				  - modified initial timelag guess (there was a bug and it is 
#				    likely more robust based on end time rather than start time)
#	Aug  5, 2016: - BUG: weird statement accessing LADCP_begin-1
#				  - BUG: DSID of first ensemble was not left original
#	Aug 22, 2016: - major changes to timelagging
#	Aug 23, 2016: - changed semantics for removing ensembles with bad attitudes:
#					instead of setting attitude to undef (or large pitch/roll),
#					clearEns() is used
#	Aug 24, 2016: - overhauled time-lagging
#	Aug 25, 2016: - significant code cleanup
#	Aug 26, 2016: - added _hdg_err.ps output plot
#	Oct 13, 2016: - made hdg nan for invalid records (BUG with current versions of IMP+LADCP, IMPatchPD0)
#	Nov 22, 2016: - added heading-offset plot
#				  - added sensor info to plots
#	Nov 29, 2016: - added stats to compass error plot
#	Dec 29, 2016: - improved histogram plot
#	Nov 16, 2017: - adapted rot_vecs() to KVM coordinates
#				  - made sensor information optional in
#	Nov 20, 2017: - major code cleanup
#	Nov 22, 2017: - replaced "IMP" output in routines used by KVH by "IMU"
#	Dec  8, 2017: - replaced remaing "IMP" output (e.g. in plot) by "IMU"
#	May 22, 2018: - added data trimming to rot_vec
#	May 23, 2018: - added horizontal field strength to mag calib plot
#				  - added support for S/N 8 board inside UL WH300 (neg_piro == 2)
#	May 24, 2018: - continued working (coord_trans == 2)
#	May 25, 2018: - continued working
#	May 30, 2018: - BUG: trimming did not re-calculate elapsed time
#	Jun  5, 2018: - BUG: on -c main magnetometer and accelerometer vectors were
#						 modified twice
#	Jun  7, 2018: - relaxed definition of -e
#	Jun  9, 2018: - BUG: some "edge" data (beyond the valid profile) were bogus (does
#						 not matter in practice)
#	Jun 30, 2019: - renamed -s in IMP+LADCP to -o (option not used in KVH+LADCP)
#				  - changed semantics so that offset histogram is plotted even on -o
#				  - made create_merge_plots return errors
#	Jul  1, 2019: - BUG: pre-deployment output cleared IMU pitch/roll fields (1 record
#						 affected)
#				  - modified output of pre-/post-cast records to include all LADCP
#				    but no IMU data
#				  - BUG: GIMBAL_PITCH had not only been defined for in-water records
#	Jun  9, 2018: - BUG: some "edge" data (beyond the valid profile) were bogus (does not matter in practice)
#	Apr 12, 2020: - modified rot_vecs to pass all records with non-numerical elapsed 
#	Apr 13, 2020: - added prep_piro_ADCP
#				  - BUG: dhist_binsize != 1 did not work
#				  - BUG: dhist agreement % was not rounded
#	Apr 14, 2020: - cosmetics
#	Jul 12, 2021: - improvements to histogram plot
#	Jul 24, 2021: - updated docu
#	Jul  6, 2022: - added support for $suppress_rot_acc_output, @copyFields
#	Jul 14, 2022: - BUG: unshift used instead of push
#				  - BUG: acc was rotated regardless of $suppress_rot_acc_output
# HISTORY END

#----------------------------------------------------------------------
# gRef() library
#----------------------------------------------------------------------

sub pl_mag_calib_begin($$$)															# initialize mag_calib plot
{
	my($pfn,$plotsize,$axlim) = @_;
	my($xmin,$xmax) = (-$axlim,$axlim);
	my($ymin,$ymax) = (-$axlim,$axlim);
	GMT_begin($pfn,"-JX${plotsize}","-R$xmin/$xmax/$ymin/$ymax",'-X6 -Y4 -P');
	GMT_psxy('-Sc0.05');
}

sub pl_mag_calib_plot($$$)															# plot data point
{
	my($valid,$magX,$magY) = @_;
	if ($valid)	{ print(GMT "> -Wred -Gred\n$magX $magY\n"); }
	else 		{ print(GMT "> -Wgreen -Ggreen\n$magX $magY\n"); }
}

sub pl_mag_calib_end($$)															# finish mag_calib plot
{
	my($axlim,$HF_mag,$sensor_info) = @_;
	
	GMT_psxy('-Sc0.1 -Gblue');														# calibration circle
	for (my($a)=0; $a<2*$pi; $a+=0.075) {
		printf(GMT "%f %f\n",$HF_mag*sin($a),$HF_mag*cos($a));
	}
	
	if ($axlim <= 0.1) {															# axes labels
		GMT_psbasemap('-Bg1a.04f.001:"X Magnetic Field [Gauss]":/g1a0.02f0.001:"Y Magnetic Field [Gauss]":WeSn');
	} else {
		GMT_psbasemap('-Bg1a.1f.01:"X Magnetic Field [Gauss]":/g1a0.1f0.01:"Y Magnetic Field [Gauss]":WeSn');
	}
    GMT_unitcoords();																# horizontal field strength
    GMT_pstext('-F+f12,Helvetica,blue+jTR -N');
   	printf(GMT "0.98 0.98 HF = %.2f Gauss\n",$HF_mag);
   	
   	printf(GMT "0.98 0.94 $sensor_info\n")											# sensor info
		if ($sensor_info ne '');

    GMT_pstext('-F+f14,Helvetica,blue+jTL -N');										# profile id
    printf(GMT "0.01 1.06 $P{profile_id}\n");
	GMT_end();
}

#-------------------------------------------------------------------------------------------
# global variables used:
#	@vecs						field number triplets of vector data
#	@piro						[chip id, pitch field, roll field] 
#	@bias						bias triples for vector data
#	$suppress_rot_acc_output	set to true to suppress output of rotated accelerometer data
#	@copyFields					field numbers to copy from input to output
#-------------------------------------------------------------------------------------------

sub rot_vecs(@) 																	# rotate & output IMU vector data 
{
	my($coord_trans,$min_elapsed,$max_elapsed,$plot_milapsed,$plot_malapsed) = @_;		# negate KVH pitch/roll data if first arg set to 1
	$min_elapsed = 0 unless defined($min_elapsed);
	$max_elapsed = 9e99 unless defined($max_elapsed);
	$plot_minlapsed = $min_elapsed unless defined($plot_milapsed);
	$plot_malapsed = $max_elapsed unless defined($plot_malapsed);

	while (&antsIn()) {
		next if numberp($ants_[0][$elapsedF]) && ($ants_[0][$elapsedF] < $min_elapsed);	# trim data
		last if numberp($ants_[0][$elapsedF]) && ($ants_[0][$elapsedF] > $max_elapsed);
		
		my($cpiro) = -1;															# current pitch/roll accelerometer
		my(@R); 																	# rotation matrix
		for (my($i)=0; $i<@vecs; $i++) {											# rotate vector data
			if ($piro[$i][0] != $cpiro) {											# next sensor chip
				$cpiro = $piro[$i][0];

				my($accX) = $ants_[0][$vecs[$cpiro][0]];
				my($accY) = $ants_[0][$vecs[$cpiro][1]];
				my($accZ) = $ants_[0][$vecs[$cpiro][2]];

				if ($coord_trans == 2) {											# S/N 8 inside UL WH300
					$accY *= -1; $accZ *= -1;
				}
				
				my($roll)  = atan2($accY,$accZ); 									# eqn 25 from Freescale AN3461
				my($pitch) = atan2($accX,sqrt($accY**2+$accZ**2));     				# eqn 26 from <Freescale AN3461
				if ($coord_trans == 1) {											# KVH
					$pitch *= -1;
					$roll  *= -1;
                }
				$ants_[0][$piro[$i][1]] = deg($pitch);								# add pitch/roll to data
				$ants_[0][$piro[$i][2]] = deg($roll);

				my($sp) = sin($pitch); my($cp) = cos($pitch);						# define rotation matrix
				my($sr) = sin($roll);  my($cr) = cos($roll);
				@R = ([ $cp,	 0,   -$sp	  ],
					  [-$sp*$sr, $cr, -$cp*$sr],
					  [ $sp*$cr, $sr,  $cp*$cr]);
			}
			my($xval) = $ants_[0][$vecs[$i][0]];
			my($yval) = $ants_[0][$vecs[$i][1]];
			my($zval) = $ants_[0][$vecs[$i][2]];
			
			if ($coord_trans == 2) {												# S/N 8 inside UL WH300
				$yval *= -1; $zval *= -1;
			}

			next if ($suppress_rot_acc_output && $i==$cpiro);
			
			$ants_[0][$vecs[$i][0]] = ($xval-$bias[$i][0]) * $R[0][0] +
									  ($yval-$bias[$i][1]) * $R[0][1] +
									  ($zval-$bias[$i][2]) * $R[0][2];
			$ants_[0][$vecs[$i][1]] = ($xval-$bias[$i][0]) * $R[1][0] +
			  						  ($yval-$bias[$i][1]) * $R[1][1] +
									  ($zval-$bias[$i][2]) * $R[1][2];
			$ants_[0][$vecs[$i][2]] = ($xval-$bias[$i][0]) * $R[2][0] +
									  ($yval-$bias[$i][1]) * $R[2][1] +
									  ($zval-$bias[$i][2]) * $R[2][2];
		}
	
		my($magX) = $ants_[0][$magXF];
		my($magY) = $ants_[0][$magYF];
		my($magZ) = $ants_[0][$magZF];
		my($accX) = $ants_[0][$accXF];
		my($accY) = $ants_[0][$accYF];
		my($accZ) = $ants_[0][$accZF];

		my($HF)   = sqrt($magX**2+$magY**2);
		my($valid)= ($HF >= $minfac*$HF_mag) && ($HF <= $maxfac*$HF_mag);
		my($hdg)  = $valid ? mag_heading($magX,$magY) : nan;

		@cpFields = ();
		foreach my $fnr (@copyFields) {
			push(@cpFields,$ants_[0][$fnr]);
        }

		if ($suppress_rot_acc_output) {
			&antsOut($ants_[0][$elapsedF]-$min_elapsed,$ants_[0][$tempF],
					 RDI_pitch($ants_[0][$pitchF],$ants_[0][$rollF]),$ants_[0][$rollF],
					 $hdg,$magX,$magY,$magZ,
	                 vel_u($HF,$hdg),vel_v($HF,$hdg),$valid,@cpFields);
        } else {
			&antsOut($ants_[0][$elapsedF]-$min_elapsed,$ants_[0][$tempF],
					 RDI_pitch($ants_[0][$pitchF],$ants_[0][$rollF]),$ants_[0][$rollF],
					 $hdg,$accX,$accY,$accZ,$magX,$magY,$magZ,
	                 vel_u($HF,$hdg),vel_v($HF,$hdg),$valid,@cpFields);
        }

		pl_mag_calib_plot($valid,$magX,$magY)
			if defined($P{profile_id}) &&
				(!numberp($ants_[0][$elapsedF]) ||
					($ants_[0][$elapsedF] >= $plot_milapsed) &&
					($ants_[0][$elapsedF] <= $plot_malapsed));
	}
}

#----------------------------------------------------------------------
# LADCP merging library
#----------------------------------------------------------------------

#-----------------------------------------------------
# Instrument Offset Estimation
#
#	1: resolution of histogram in deg
#		1 deg okay for good sensors
#		2 deg sometimes required (2016 P18 003 2nd sensor)
#	2: min tilt anom to consider for offset estimation
#		0.3 deg works even for calm casts
#		increased values improve histogram
#		2.0 deg is too high for quiet casts (2016 P18 003)
#	3: minimum fraction of hist mode required
#		10% default
#		decreasing histogram resolution is better than
#			decreasing this value, I think
#-----------------------------------------------------

#----------------------------------------------------------------------
# trim_out_of_water()
#	- attempt to remove out-of-water records from time-series of
#	  horizontal acceleration
#----------------------------------------------------------------------

sub trim_out_of_water($)
{
	my($verbose) = @_;

	#--------------------------------------------------------------------------
	# first-difference horizontal acceleration at full resolution to pass-filter
	# dangling motion
	#--------------------------------------------------------------------------

	$IMP{Ah}[0] 	= sqrt($ants_[0][$accXF]**2+$ants_[0][$accYF]**2);
	$IMP{dAhdt}[0]	= nan;
	for (my($r)=1; $r<@ants_; $r++) {
		$IMP{Ah}[$r] = sqrt($ants_[$r][$accXF]**2+$ants_[$r][$accYF]**2);
		$IMP{dAhdt}[$r] = ($IMP{Ah}[$r]-$IMP{Ah}[$r-1]) / ($ants_[$r][$elapsedF]-$ants_[$r-1][$elapsedF]);
	}

	#--------------------------------------------------------------------------------------
	# create 10-s binned time series to calculate rms values of this quantity (dAhdt), and
	# scale this with cos(sqrt($$pitch**2+$$roll**2)) to dampen underwater peaks (when the
	# instrument has a large tilt because it is being dragged)
	#	NB: dAhdt, pitch and roll are only set up to last full bin (not so, sum and n)
	#--------------------------------------------------------------------------------------

	my(@dAhdt,@pitch,@roll,@dAhdt_rms);
	my(@sum) = my(@sume) = my(@sump) = my(@sumr) = my(@n) = (0);
	
	my($bin_start) = $ants_[0][$elapsedF];
	for (my($r)=1; $r<@ants_; $r++) {   
	
		if ($ants_[$r][$elapsedF] - $bin_start <= 10) { 						# within 10-s bin
			$sum[$#sum] += $IMP{dAhdt}[$r]; 									# sums
			$sume[$#sume] += $ants_[$r][$elapsedF];
			$sump[$#sump] += $ants_[$r][$pitchF];
			$sumr[$#sumr] += $ants_[$r][$rollF];
			$n[$#n]++;
			next;
		}
	
		$dAhdt[$#sum] = $sum[$#sum] / $n[$#n];								# bin done => means
		$elapsed[$#sum] = $sume[$#sume] / $n[$#n];
		$pitch[$#sum] = $sump[$#sump] / $n[$#n];
		$roll[$#sum] = $sumr[$#sumr] / $n[$#n];
	
		my($sumsq) = 0; 													# sum of squares for rms(accel)
		for (my($rr)=$r-$n[$#n]; $rr<$r; $rr++) {
			$sumsq += ($IMP{dAhdt}[$rr] - $dAhdt[$#sum])**2;
		}
		$dAhdt_rms[$#sum] = sqrt($sumsq / $n[$#n]);
	    
		push(@sum,$IMP{dAhdt}[$r]); 										# begin next bin
		push(@sume,$ants_[$r][$elapsedF]);
		push(@sump,$ants_[$r][$pitchF]);
		push(@sumr,$ants_[$r][$rollF]);
		push(@n,1);
		$bin_start = $ants_[$r][$elapsedF];
	}

	#--------------------------------------------
	# trim beginning/end when IMP is out of water
	#--------------------------------------------

	my($i,$si);
	for ($i=int(@dAhdt_rms/2); $i>0; $i--) {
		last if ($dAhdt_rms[$i] * cos(rad(sqrt($pitch[$i]**2+$roll[$i]**2))) > 1.0);
	}
	if ($dAhdt_rms[$i] * cos(rad(sqrt($pitch[$i]**2+$roll[$i]**2))) > 1.0) {
		for ($si=0; $ants_[$si][$elapsedF]<=$elapsed[$i]; $si++) {}
		splice(@ants_,0,$si);
		printf(STDERR "\n\t\t%5d  leading out-of-water IMU records removed",$si)
			if ($si>0 && $verbose);
	} else {
		print(STDERR "\n\t\tWARNING: no leading out-of-water IMU records detected/removed") if $verbose;
	}
	
	for ($i=int(@dAhdt_rms/2); $i<@dAhdt_rms; $i++) {
		last if ($dAhdt_rms[$i] * cos(rad(sqrt($pitch[$i]**2+$roll[$i]**2))) > 1.0);
	}
	if ($dAhdt_rms[$i] * cos(rad(sqrt($pitch[$i]**2+$roll[$i]**2))) > 1.0) {
		for ($si=$#ants_; $ants_[$si][$elapsedF]>=$elapsed[$i]; $si--) {}
		my($rem) = @ants_ - $si;
		splice(@ants_,$si);
		printf(STDERR "\n\t\t%5d trailing out-of-water IMU records removed",$rem)
			if ($rem>0 && $verbose);
	} else {
		print(STDERR "\n\t\tWARNING: no trailing out-of-water IMU records detected/removed") if $verbose;
	}
	
	printf(STDERR "\n\t\tcast duration		  : %.1f min",
		($ants_[$#ants_][$elapsedF] - $ants_[0][$elapsedF]) / 60)
	        if $verbose;
}

#--------------------------------------------------------------------------------
# prep_piro_IMP()
# 	- calculate pitch/roll offsets & tilt azimuth for IMP
#	- if first_rec and last_rec are provided, the mean calculation will 
#	  be restricted to this range (TILT_AZIM, _ANOM calculated for all recs)
#	- during an attempt to improve time lagging for the 2015 IOPAS data set,
#	  it was noticed that one particular instrument, WHM300#12973 maxes out
#	  pitch at 27.36 degrees, whereas the roll may not be maxed out at 28.76 deg,
#	  the max observed during the cruise.
#	- therefore, IMP{TILT_AZIM} and IMP{TILT_ANOM} are calculated here, first,
#	  with a pitch/roll cutoff value of 29 degrees
#	- after the time lagging, when the LADCP start and end times are known,
#	  the TILT values are re-calculated without the pitch/roll limit, and
#	  using only the correct time range
#---------------------------------------------------------------------------------

sub prep_piro_IMP($@)
{
	my($verbose,$first_rec,$last_rec) = @_;
	my($RDI_max_tilt) = 29; 
	my($IMP_pitch_mean,$IMP_roll_mean,$nPR) = (0,0,0);

	$first_rec = 0 			unless defined($first_rec);
	$last_rec  = $#ants_	unless defined($last_rec);
	
	for (my($r)=$first_rec; $r<=$last_rec; $r++) {
		next unless numbersp($ants_[$r][$pitchF],$ants_[$r][$rollF]);
		$nPR++;
		$IMP_pitch_mean += min($ants_[$r][$pitchF],$RDI_max_tilt);
		$IMP_roll_mean	+= min($ants_[$r][$rollF],$RDI_max_tilt);
	}
	$IMP_pitch_mean /= $nPR;
	$IMP_roll_mean /= $nPR;
	printf(STDERR "\n\t\tIMU mean pitch/roll	  : %.1f/%.1f deg",$IMP_pitch_mean,$IMP_roll_mean)
			if $verbose;
	
	for (my($r)=0; $r<@ants_; $r++) {
		next unless numbersp($ants_[$r][$pitchF],$ants_[$r][$rollF]);
		$IMP{TILT_AZIMUTH}[$r] = tilt_azimuth(min($ants_[$r][$pitchF],$RDI_max_tilt)-$IMP_pitch_mean,
											  min($ants_[$r][$rollF],$RDI_max_tilt) -$IMP_roll_mean);
		$IMP{TILT_ANOM}[$r] = angle_from_vertical(min($ants_[$r][$pitchF],$RDI_max_tilt)-$IMP_pitch_mean,
												  min($ants_[$r][$rollF],$RDI_max_tilt) -$IMP_roll_mean);
	}
	return ($IMP_pitch_mean,$IMP_roll_mean);
}

#----------------------------------------------------------------------
# prep_piro_LADCP()
#	- calculate pitch/roll offsets & tilt azimuth of LADCP
#----------------------------------------------------------------------

sub prep_piro_LADCP($)
{
	my($verbose) = @_;

	$first_ens = 0 			unless defined($first_ens);
	$last_ens  = $#ants_	unless defined($last_ens);

	my($LADCP_pitch_mean,$LADCP_roll_mean) = (0,0);
	for (my($ens)=0; $ens<=$#{$LADCP{ENSEMBLE}}; $ens++) {
		$LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH} =
			gimbal_pitch($LADCP{ENSEMBLE}[$ens]->{PITCH},$LADCP{ENSEMBLE}[$ens]->{ROLL});
	}
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		$LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH} =
			gimbal_pitch($LADCP{ENSEMBLE}[$ens]->{PITCH},$LADCP{ENSEMBLE}[$ens]->{ROLL});
		$LADCP_pitch_mean += $LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH};
		$LADCP_roll_mean  += $LADCP{ENSEMBLE}[$ens]->{ROLL};
	}
	$LADCP_pitch_mean /= ($LADCP_end-$LADCP_begin+1);
	$LADCP_roll_mean  /= ($LADCP_end-$LADCP_begin+1);
	printf(STDERR "\n\t\tLADCP mean pitch/roll	  : %.1f/%.1f deg",$LADCP_pitch_mean,$LADCP_roll_mean)
			if $verbose;
	
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		$LADCP{ENSEMBLE}[$ens]->{TILT_AZIMUTH} =
			tilt_azimuth($LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH}-$LADCP_pitch_mean,
						 $LADCP{ENSEMBLE}[$ens]->{ROLL}-$LADCP_roll_mean);
		$LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} =
			angle_from_vertical($LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH}-$LADCP_pitch_mean,
								$LADCP{ENSEMBLE}[$ens]->{ROLL}-$LADCP_roll_mean);
	}
	
	print(STDERR "\n") if $verbose;
	return ($LADCP_pitch_mean,$LADCP_roll_mean);
}

#----------------------------------------------------------------------
# prep_piro_ADCP()
#	- calculate pitch/roll offsets & tilt azimuth of moored ADCP
#	- very similar to prep_piro_LADCP() but using windowing as in
#	  prep_piro_IMP()
#	- window ens are indices, not ensemble numbers
#----------------------------------------------------------------------

sub prep_piro_ADCP($@)
{
	my($verbose,$window_first_ens,$window_last_ens) = @_;

	$window_first_ens = 0 					unless defined($window_first_ens);
	$window_last_ens  = $#{$ADCP{ENSEMBLE}}	unless defined($window_last_ens);

	for (my($ens)=0; $ens<=$#{$ADCP{ENSEMBLE}}; $ens++) {
		$ADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH} =
			gimbal_pitch($ADCP{ENSEMBLE}[$ens]->{PITCH},$ADCP{ENSEMBLE}[$ens]->{ROLL});
	}

	my($ADCP_pitch_mean,$ADCP_roll_mean) = (0,0);
	for (my($ens)=$window_first_ens; $ens<=$window_last_ens; $ens++) {
		$ADCP_pitch_mean += $ADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH};
		$ADCP_roll_mean  += $ADCP{ENSEMBLE}[$ens]->{ROLL};
	}
	$ADCP_pitch_mean /= ($window_last_ens-$window_first_ens+1);
	$ADCP_roll_mean  /= ($window_last_ens-$window_first_ens+1);
	printf(STDERR "\n\t\tADCP mean pitch/roll       : %.1f/%.1f deg",$ADCP_pitch_mean,$ADCP_roll_mean)
			if $verbose;
	
	for (my($ens)=0; $ens<=$#{$ADCP{ENSEMBLE}}; $ens++) {
		$ADCP{ENSEMBLE}[$ens]->{TILT_AZIMUTH} =
			tilt_azimuth($ADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH}-$ADCP_pitch_mean,
						 $ADCP{ENSEMBLE}[$ens]->{ROLL}-$ADCP_roll_mean);
		$ADCP{ENSEMBLE}[$ens]->{TILT_ANOM} =
			angle_from_vertical($ADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH}-$ADCP_pitch_mean,
								$ADCP{ENSEMBLE}[$ens]->{ROLL}-$ADCP_roll_mean);
	}
	
	print(STDERR "\n") if $verbose;
	return ($ADCP_pitch_mean,$ADCP_roll_mean);
}

#------------------------------------------------------------------
# sub calc_hdg_offset()
#	- estimate heading offset from tilt time series
#	- returns heading offset and updated IMP mean tilts
#	- also creates diagnostic plot with pl_hdg_offset()
#------------------------------------------------------------------

sub pl_hdg_offset($@)
{
	my($dhist_binsize,$modefrac,@dhist) = @_;
	
	my($plotsize) = '13c';
	my($xmin,$xmax) = (-180.5,180.5);
	my($ymin) = 0;
	my($ymax) = 0;

	for (my($i)=0; $i<@dhist; $i++) {
		$ymax = $dhist[$i] if ($dhist[$i] > $ymax);
    }
	$ymax = 1.05 * $ymax;
	    
	GMT_begin("$P{profile_id}${opt_a}_hdg_offset.ps","-JX${plotsize}","-R$xmin/$xmax/$ymin/$ymax",'-X6 -Y4 -P');
	if (defined($opt_o)) {
		GMT_psxy("-W2,red");
		printf(GMT "%f %f\n%f %f\n",$opt_o,0,$opt_o,$ymax);
    }
	GMT_psxy("-Sb${dhist_binsize}u -GCornFlowerBlue");
	for (my($i)=0; $i<@dhist; $i++) {
		next unless $dhist[$i];
		printf(GMT "%f $dhist[$i]\n",$i*$dhist_binsize>180 ? $i*$dhist_binsize-360 : $i*$dhist_binsize);
	}
	GMT_psbasemap('-Bg45a90f15:"IMU Heading Offset [\260]":/ga100f10:"Frequency":WeSn');
	GMT_unitcoords();
	GMT_pstext('-F+f14,Helvetica,CornFlowerBlue+jTR -N');
	if (defined($opt_o)) {
		printf(GMT "0.99 1.06 -o %g\260 offset (%d%% agreement)\n",angle($HDG_offset),round(100*$modefrac));
	} else {
		printf(GMT "0.99 1.06 %g\260 offset (%d%% agreement)\n",angle($HDG_offset),round(100*$modefrac));
	}
	GMT_pstext('-F+f14,Helvetica,blue+jTL -N');
	printf(GMT "0.01 1.06 $P{profile_id} $opt_a\n");
    GMT_end();
}

sub calc_hdg_offset($)
{
	my($verbose) = @_;

	print(STDERR "\n\tRe-calculating IMU pitch/roll anomalies") if $verbose;
	($IMP_pitch_mean,$IMP_roll_mean,$nPR) = (0,0,0);
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
		if ($r < 0 && $ens == $LADCP_begin) {
			$r = int(($LADCP{ENSEMBLE}[++$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT})
				while ($r < 0);
			printf(STDERR "\n\tIMU data begin with instrument already in water => skipping %ds of LADCP data",
				$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_begin]->{ELAPSED_TIME})
					if ($verbose);
			$LADCP_begin = $ens;
		}
		if ($r > $#ants_) {
			printf(STDERR "\n\tIMU data end while instrument is still in water => truncating %ds of LADCP data",
				$LADCP{ENSEMBLE}[$LADCP_end]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME})
					if ($verbose);
			$LADCP_end = $ens - 1;
			last;
		}
		next unless numberp($IMP{TILT_AZIMUTH}[$r]);
		$nPR++;
		$IMP_pitch_mean += $ants_[$r][$pitchF];
		$IMP_roll_mean	+= $ants_[$r][$rollF];
	}
	$IMP_pitch_mean /= $nPR;
	$IMP_roll_mean /= $nPR;

	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
		next unless numberp($IMP{TILT_AZIMUTH}[$r]);
		$LADCP{ENSEMBLE}[$ens]->{IMP_TILT_AZIMUTH} =
			$IMP{TILT_AZIMUTH}[$r] = tilt_azimuth($ants_[$r][$pitchF]-$IMP_pitch_mean,
												  $ants_[$r][$rollF] -$IMP_roll_mean);
		$LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM} =
			$IMP{TILT_ANOM}[$r] = angle_from_vertical($ants_[$r][$pitchF]-$IMP_pitch_mean,
													  $ants_[$r][$rollF] -$IMP_roll_mean);
	}
	
	printf(STDERR "\n\t\tIMU mean pitch/roll: %.1f/%.1f deg",$IMP_pitch_mean,$IMP_roll_mean)
			if $verbose;
	
	my($dhist_binsize,$dhist_min_pirom,$dhist_min_mfrac) = split(/,/,$opt_e);
	croak("$0: cannot decode -e $opt_e\n")
		unless ($dhist_binsize > 0 && $dhist_min_pirom > 0 && $dhist_min_mfrac >= 0);
	
	my(@dhist); my($nhist) = my($modeFreq) = 0;
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
		next unless numberp($IMP{TILT_AZIMUTH}[$r]);
		next unless (abs($ants_[$r][$pitchF]-$IMP_pitch_mean) >= $dhist_min_pirom &&
					 abs($ants_[$r][$rollF] -$IMP_roll_mean) >= $dhist_min_pirom);
		$dhist[int(angle_pos($LADCP{ENSEMBLE}[$ens]->{TILT_AZIMUTH}-$IMP{TILT_AZIMUTH}[$r])/$dhist_binsize+0.5)]++;
		$nhist++;
	}
	croak("$0: empty histogram\n")
		unless ($nhist);
	
	if (defined($opt_o)) {												# set heading offset, either with -o
		$HDG_offset = $opt_o;
		$dhist_binsize = 1;
	} else {															# or from the data
		$HDG_offset = 0;
		for (my($i)=1; $i<@dhist-1; $i++) { 							# make sure mode is not on edge
			$HDG_offset = $i if ($dhist[$i] >= $dhist[$HDG_offset]);
		}
		$HDG_offset *= $dhist_binsize;
	}

	my($modefrac) = ($dhist[$HDG_offset/$dhist_binsize]+$dhist[$HDG_offset/$dhist_binsize-1]+$dhist[$HDG_offset/$dhist_binsize+1]) / $nhist;
	pl_hdg_offset($dhist_binsize,$modefrac,@dhist);

	unless (defined($opt_o)) {	    									# make sure data are consistent (unless -o is used)
		if ($opt_f) {
			printf(STDERR "\n\nIGNORED WARNING (-f): Cannot determine reliable heading offset; $HDG_offset+/-$dhist_binsize deg accounts for only %f%% of total\n",$modefrac*100)
				if ($modefrac < $dhist_min_mfrac);
		} else {
			croak(sprintf("\n$0: Cannot determine reliable heading offset; $HDG_offset+/-$dhist_binsize deg accounts for only %f%% of total\n",$modefrac*100))
				if ($modefrac < $dhist_min_mfrac);
		}
	}
	
	printf(STDERR "\n\t") if $verbose;
	if ($opt_o) {
		printf(STDERR "IMU heading offset = -o %g deg (%d%% agreement)\n",angle($HDG_offset),round(100*$modefrac))
			if $verbose;
	} else {
		printf(STDERR "IMU heading offset = %g deg (%d%% agreement)\n",angle($HDG_offset),round(100*$modefrac))
			if $verbose;
	}

	return ($HDG_offset,$IMP_pitch_mean,$IMP_roll_mean);
}

#-----------------------------------------------------------
# rot_IMP()
# 	- rotate IMP Data Into LADCP Instrument Coords
#	- also replaced pitch/roll by corresponding anomalies!!!
#-----------------------------------------------------------

sub rot_IMP($)
{
	my($verbose) = @_;
	my($crho) = cos(rad($HDG_offset));
	my($srho) = sin(rad($HDG_offset));
	
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
	
		if (numbersp($ants_[$r][$pitchF],$ants_[$r][$rollF])) { 				# pitch/roll
			my($rot_p) = (($ants_[$r][$pitchF]-$IMP_pitch_mean)*$crho +
						  ($ants_[$r][$rollF]-$IMP_roll_mean)*$srho);
			my($rot_r) = (-($ants_[$r][$pitchF]-$IMP_pitch_mean)*$srho +
						   ($ants_[$r][$rollF]-$IMP_roll_mean)*$crho);
			$ants_[$r][$pitchF] = $rot_p;
			$ants_[$r][$rollF]	= $rot_r;
		}
	    
		$ants_[$r][$hdgF] = angle_pos($ants_[$r][$hdgF] - $HDG_offset)
			if numberp($ants_[$r][$hdgF]);
	}
	
	my($rot_p) =  $IMP_pitch_mean * $crho + $IMP_roll_mean * $srho; 			# mean pitch roll
	my($rot_r) = -$IMP_pitch_mean * $srho + $IMP_roll_mean * $crho;
	$IMP_pitch_mean = $rot_p;
	$IMP_roll_mean	= $rot_r;
	
	print(STDERR "\n") if $verbose;
	return ($IMP_pitch_mean,$IMP_roll_mean);
}

#----------------------------------------------------------------------
# create_merge_plots()
#   - tilt time series (*_time_lag.ps)
#	- heading errors (*_hdg_err.ps)
#----------------------------------------------------------------------

sub create_merge_plots($$$)
{
    my($basename,$plotsize,$verbose) = @_;

	#---------------------------------
	# Tilt Time Series (*_time_lag.ps)
	#---------------------------------

	my($mint,$maxt) = (99,-99);
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		if (($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_begin]->{ELAPSED_TIME} <= 180) ||
			($LADCP{ENSEMBLE}[$LADCP_end]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} <= 180)) {
				$mint = $LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM} if ($LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM} < $mint);
				$maxt = $LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM} if ($LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM} > $maxt);
				$mint = $LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} if ($LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} < $mint);
				$maxt = $LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} if ($LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} > $maxt);
		}
	}

	my($xmin,$xmax) = (-90,90);
	my($ymin) = round($mint-0.5);
	my($ymax) = round($maxt+0.5);
	
	GMT_begin("${basename}_time_lag.ps","-JX${plotsize}","-R$xmin/$xmax/$ymin/$ymax",'-X6 -Y4 -P');

	GMT_psxy('-W2,coral');
	for (my($ens) = $LADCP_begin + 5; 
		 $LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_begin]->{ELAPSED_TIME} <= 90;
		 $ens++) {
			printf(GMT "%f %f\n",$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_begin]->{ELAPSED_TIME},
								 $LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM});
	}
	GMT_psxy('-W1');
	for (my($ens) = $LADCP_begin + 5; 
		 $LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_begin]->{ELAPSED_TIME} <= 90;
		 $ens++) {
			printf(GMT "%f %f\n",$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_begin]->{ELAPSED_TIME},
								 $LADCP{ENSEMBLE}[$ens]->{TILT_ANOM});
	}
	GMT_psxy('-W2,SeaGreen');
	for (my($ens) = $LADCP_end - 5; 
		 $LADCP{ENSEMBLE}[$LADCP_end]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} <= 90;
		 $ens--) {
			printf(GMT "%f %f\n",$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_end]->{ELAPSED_TIME},
								 $LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM});
	}
	GMT_psxy('-W1');
	for (my($ens) = $LADCP_end - 5; 
		 $LADCP{ENSEMBLE}[$LADCP_end]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} <= 90;
		 $ens--) {
			printf(GMT "%f %f\n",$LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME}-$LADCP{ENSEMBLE}[$LADCP_end]->{ELAPSED_TIME},
								 $LADCP{ENSEMBLE}[$ens]->{TILT_ANOM});
	}

    GMT_psbasemap('-Bg30a30f10:"Elapsed Time [sec]":/g5a5f1:"Tilt Magnitude [\260]":WeSn');
	GMT_unitcoords();
    GMT_pstext('-F+f14,Helvetica,Coral+jTL');
	    printf(GMT "0.52 0.98 downcast\n");
    GMT_pstext('-F+f14,Helvetica,SeaGreen+jTR');
	    printf(GMT "0.48 0.98 upcast\n");	    
	GMT_psxy('-W4,LightSkyBlue');
		printf(GMT "0.5 0\n0.5 1\n");
    GMT_pstext('-F+f14,Helvetica,blue+jTL -N');
	    printf(GMT "0.01 1.06 $P{profile_id} $opt_a\n");
	GMT_end();

	#------------------------------
	# Heading Errors (*_hdg_err.ps)
	#------------------------------

	my(@err_binned,@err_nsamp);
	my($sumErr) = 0; my($nErr) = $LADCP_end - $LADCP_begin + 1;
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		next unless ($LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} < 10);
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
		my($bi) = int($ants_[$r][$hdgF]/5);
		my($err) = angle_diff($ants_[$r][$hdgF],$LADCP{ENSEMBLE}[$ens]->{HEADING});
		next unless numberp($err);
		$err_binned[$bi] += $err; $sumErr += $err;
		$err_nsamp[$bi]++;
	}
	for (my($bi)=0; $bi<@err_nsamp; $bi++) {
		$err_binned[$bi] = ($err_nsamp[$bi] >= 5)
						 ? $err_binned[$bi]/$err_nsamp[$bi]
						 : undef;
	}
	my(@err_dssq);
	for (my($ens)=$LADCP_begin; $ens<=$LADCP_end; $ens++) {
		next unless ($LADCP{ENSEMBLE}[$ens]->{TILT_ANOM} < 10);
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
		my($bi) = int($ants_[$r][$hdgF]/5);
		my($err) = angle_diff($ants_[$r][$hdgF],$LADCP{ENSEMBLE}[$ens]->{HEADING});
		next unless numberp($err);
		$err_dssq[$bi] += ($err-$err_binned[$bi])**2;
	}

	my($xmin,$xmax) = (0,360);
	my($ymin,$ymax) = (-45,45);
	GMT_begin("${basename}_hdg_err.ps","-JX${plotsize}","-R$xmin/$xmax/$ymin/$ymax",'-X6 -Y4 -P');
	GMT_psxy('-Ey/3,CornFlowerBlue');
	my($sumSq,$sumBe) = my($nSq,$nBe) = (0,0);
	for (my($bi)=0; $bi<@err_binned; $bi++) {
		next unless ($err_nsamp[$bi] >= 2);
		next unless numberp($err_binned[$bi]);
		$sumSq += $err_binned[$bi]**2; $nSq++;
		$sumBe += $err_binned[$bi]; $nBe++;
#		printf(GMT "%f %f\n",2.5+5*$bi,$err_binned[$bi]);
		printf(GMT "%f %f %f\n",2.5+5*$bi,$err_binned[$bi],sqrt($err_dssq[$bi]/($err_nsamp[$bi]-1)));
	}
    GMT_psbasemap('-Bg90a45f5:"ADCP Heading [\260]":/g15a15f5:"ADCP Compass Error [\260]":WeSn');
	GMT_unitcoords();
    GMT_pstext('-F+f12,Helvetica,CornFlowerBlue+jTR -Gwhite -C25%');
    printf(GMT "0.98 0.98 rms error = %7.1f\260\n",sqrt($sumSq/$nSq));
    printf(GMT "0.98 0.94 time-averaged error = %7.1f\260\n",$sumErr/$nErr);
    printf(GMT "0.98 0.90 heading-averaged error = %7.1f\260\n",$sumBe/$nBe);
    GMT_pstext('-F+f14,Helvetica,blue+jTL -N');
    printf(GMT "0.01 1.06 $P{profile_id} $opt_a\n");
    GMT_end();
	                        
	print(STDERR "\n") if $verbose;
	return (sqrt($sumSq/$nSq),$sumErr/$nErr,$sumBe/$nBe);
}

#----------------------------------------------------------------------
# output_merged()
#	- output merged data
#	- there must be exactly one record for each PD0 ensemble
#----------------------------------------------------------------------

sub output_merged($)
{
	my($verbose) = @_;
	
	my($tazimF)		= &antsNewField('tilt_azimuth');
	my($tanomF)		= &antsNewField('tilt_magnitude');
	my($L_tazimF) 	= &antsNewField('LADCP_tilt_azimuth');
	my($L_tanomF) 	= &antsNewField('LADCP_tilt_magnitude');
	my($L_elapsedF) = &antsNewField('LADCP_elapsed');
	my($L_ensF) 	= &antsNewField('LADCP_ens');
	my($L_depthF) 	= &antsNewField('LADCP_depth_estimate');
	my($L_pitchF)	= &antsNewField('LADCP_pitch');
	my($L_rollF)	= &antsNewField('LADCP_roll');
	my($L_hdgF)		= &antsNewField('LADCP_hdg');
	my($dcF)		= &antsNewField('downcast');

	for (my($ens)=0; $ens<=$#{$LADCP{ENSEMBLE}}; $ens++) {
		my($r) = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});
#		print(STDERR "$r\[$ens\,$LADCP{ENSEMBLE}[$ens]->{NUMBER}] = int(($LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG} - $ants_[0][$elapsedF]) / $IMP{DT});\n");
		if ($r<0 || $r>$#ants_) {												# ensemble beyond limits of IMU data
			my(@out);
			if ($ens >= $LADCP_begin && $ens <= $LADCP_end) {
				$out[$elapsedF] 	= $LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME} + $IMP{TIME_LAG};
				$out[$L_elapsedF] 	= $LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME};
			}
			$out[$L_ensF]			= $LADCP{ENSEMBLE}[$ens]->{NUMBER};
			$out[$dcF]				= ($ens <= $LADCP_bottom);
			&antsOut(@out);
		} elsif ($ens < $LADCP_begin || $ens > $LADCP_end) {					# pre deplyment or post recovery
			my(@out);															# correct IMP record NOT known
			$out[$L_elapsedF] 		= undef;
			$out[$L_ensF] 			= $LADCP{ENSEMBLE}[$ens]->{NUMBER};
			$out[$L_pitchF]			= $LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH} - $LADCP_pitch_mean;
			$out[$L_rollF]			= $LADCP{ENSEMBLE}[$ens]->{ROLL} - $LADCP_roll_mean;
			$out[$L_hdgF]			= $LADCP{ENSEMBLE}[$ens]->{HEADING};							    
			&antsOut(@out);
		} else {
			$ants_[$r][$tazimF] 	= angle($LADCP{ENSEMBLE}[$ens]->{IMP_TILT_AZIMUTH} + $HDG_offset);
			$ants_[$r][$tanomF] 	= $LADCP{ENSEMBLE}[$ens]->{IMP_TILT_ANOM};
			$ants_[$r][$L_tazimF]	= $LADCP{ENSEMBLE}[$ens]->{TILT_AZIMUTH};
			$ants_[$r][$L_tanomF]	= $LADCP{ENSEMBLE}[$ens]->{TILT_ANOM};
			$ants_[$r][$L_elapsedF] = $LADCP{ENSEMBLE}[$ens]->{ELAPSED_TIME};
			$ants_[$r][$L_ensF] 	= $LADCP{ENSEMBLE}[$ens]->{NUMBER};
			$ants_[$r][$L_depthF]	= $LADCP{ENSEMBLE}[$ens]->{DEPTH};
			$ants_[$r][$L_pitchF]	= $LADCP{ENSEMBLE}[$ens]->{GIMBAL_PITCH} - $LADCP_pitch_mean;
			$ants_[$r][$L_rollF]	= $LADCP{ENSEMBLE}[$ens]->{ROLL} - $LADCP_roll_mean;
			$ants_[$r][$L_hdgF] 	= $LADCP{ENSEMBLE}[$ens]->{HEADING};							    
			$ants_[$r][$dcF]        = ($ens <= $LADCP_bottom) ? 1 : 0;
			&antsOut(@{$ants_[$r]});
		}
	}
	
	print(STDERR "\n") if $verbose;
}

#----------------------------------------------------------------------

1; # return true for all the world to see
