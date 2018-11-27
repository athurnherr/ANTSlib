#======================================================================
#                    R D I _ C O O R D S . P L 
#                    doc: Sun Jan 19 17:57:53 2003
#                    dlm: Wed Mar 28 12:30:12 2018
#                    (c) 2003 A.M. Thurnherr
#                    uE-Info: 109 22 NIL 0 0 72 10 2 4 NIL ofnI
#======================================================================

# RDI Workhorse Coordinate Transformations

# HISTORY:
#	Jan 19, 2003: - written
#	Jan 21, 2003: - made it obey HEADING_BIAS (magnetic declination)
#	Jan 22, 3003: - corrected magnetic declination
#	Feb 16, 2003: - use pitch correction from RDI manual
#	Oct 11, 2003: - BUG: return value of atan() had been interpreted
#					     as degrees instead of radians
#	Feb 27, 2004: - added velApplyHdgBias()
#				  - changed non-zero HEADING_ALIGNMENT from error to warning
#	Sep 16, 2005: - added deg() for [mkprofile]
#	Aug 26, 2006: - BUG: incorrect transformation for uplookers
#	Nov 30, 2007: - optimized &velInstrumentToEarth(), velBeamToInstrument()
#				  - added support for 3-beam solutions
#	Feb 12, 2008: - added threeBeamFlag
#	Mar 18, 2009: - added &gimbal_pitch(), &angle_from_vertical()
#	May 19, 2009: - added &velBeamToVertical()
#	May 23, 2009: - debugged & renamed to &velBeamToBPEarth
#	May 23, 2010: - changed prototypes of rad() & deg() to conform to ANTS
#	Dec 20, 2010: - cosmetics
#	Dec 23, 2010: - added &velBeamToBPInstrument
#	Jan 22, 2011: - made velApplyHdgBias calculate sin/cos every time to allow
#				    per-ensemble corrections
#	Jan 15, 2012: - replaced defined(@...) by (@...) to get rid of warning
#	Aug  7, 2013: - BUG: &velBeamToBPInstrument did not return any val unless
#						 all beam velocities are defined
#	Nov 27, 2013: - added &RDI_pitch(), &tilt_azimuth()
#	Mar  4, 2014: - added support for ensembles with missing PITCH/ROLL/HEADING
#	May 29, 2014: - BUG: vertical velocity can be calculated even without
#						 heading
#				  - removed some old debug statements
#				  - removed unused code from &velBeamToBPInstrument
#	Jan  5, 2016: - added &velEarthToInstrument(@), &velInstrumentToBeam(@)
#	Jan  9, 2016: - added &velEarthToBeam(), &velBeamToEarth()
#	Feb 29, 2016: - debugged & verified velEarthToInstrument(), velInstrumentToBeam()
#				  - added velBeamToEarth()
#	May 19, 2016: - begin implemeting bin interpolation
#	May 25, 2016: - continued
#	May 26, 2016: - made it work
#	May 30, 2016: - begin implementing 2nd order attitude transformations
#	Jun  6, 2016: - toEarth transformation in beamToBPEarth was but crude approximation;
#					updated with transformation taken from Lohrman et al. (JAOT 1990)
#				  - BUG: v34 sign was inconsistent with RDI coord manual
#	Jun  8, 2016: - added $ens as arg to velInstrumentToBeam() for consistency
#	Jul  7, 2016: - added velEarthToBPw() with algorithm debugged and verified
#					by Paul Wanis from TRDI
#	Oct 12, 2017: - documentation
#	Nov 26, 2017: - BUG: velBeamtoBPEarth() did not respect missing values
#	Nov 27, 2017: - BUG: numbersp() from [antslib.pl] was used
#	Mar 28, 2018: - added &loadInstrumentTransformation()

use strict;
use POSIX;

my($PI) = 3.14159265358979;

sub rad(@) { return $_[0]/180 * $PI; }
sub deg(@) { return $_[0]/$PI * 180; }

#----------------------------------------------------------------------
# Tweakables
#----------------------------------------------------------------------

$RDI_Coords::minValidVels = 3;				# 3-beam solutions ok (velBeamToInstrument)
$RDI_Coords::binMapping = 'linterp';		# 'linterp' or 'none' (earthVels, BPearthVels)
$RDI_Coords::beamTransformation = 'LHR90';	# set to 'RDI' to use 1st order transformations from RDI manual

#----------------------------------------------------------------------
# beam to earth transformation
#	- loadInstrumentTransformation(filename) loads a file that contains the
#	  output from the PS3 command, which includes the instrument transformation
#	  matrix as follows:
#	Instrument Transformation Matrix (Down):    Q14:
#	  1.4689   -1.4682    0.0030   -0.0035       24067  -24055      49     -58
#	 -0.0036    0.0029   -1.4664    1.4673         -59      48  -24025   24041
#	  0.2658    0.2661    0.2661    0.2657        4355    4359    4359    4354
#	  1.0373    1.0382   -1.0385   -1.0373       16995   17010  -17015  -16995
#----------------------------------------------------------------------

$RDI_Coords::threeBeam_1 = 0;			# stats from velBeamToInstrument
$RDI_Coords::threeBeam_2 = 0;
$RDI_Coords::threeBeam_3 = 0;
$RDI_Coords::threeBeam_4 = 0;
$RDI_Coords::fourBeam    = 0;

$RDI_Coords::threeBeamFlag = 0;			# flag last transformation

{ # STATIC SCOPE
	my(@B2I);

	sub loadInstrumentTransformation($)
	{
		die("loadInstrumentTransformation(): B2I matrix already defined\n")
			if (@B2I);
		open(ITF,$_[0]) || die("$_[0]: $!\n");
		my($row) = 0;
		while (<ITF>) {
			if ($row == 0) {
				next unless m{^Instrument Transformation Matrix \(Down\):};
				$row = 1;
			} elsif ($row <= 4) {
				my(@vals) = split;
				die("$_[0]: cannot decode row #$row of Instrument Transformation Matrix\n")
					unless (@vals == 8);
				for (my($i)=0; $i<4; $i++) {
					die("$_[0]: cannot decode row #$row of Instrument Transformation Matrix\n")
						unless numberp($vals[$i]);
					$B2I[$row-1][$i] = $vals[$i];
				}
				$row++;
			} else {
				last;
			}
		}
		die("$_[0]: cannot decode Instrument Transformation Matrix (row = $row)\n")
			unless ($row == 5);
		close(ITF);
	}

	sub velBeamToInstrument(@)
	{
		my($ADCP,$ens,$v1,$v2,$v3,$v4) = @_;
		return undef unless (defined($v1) + defined($v2) +
					   		 defined($v3) + defined($v4)
								>= $RDI_Coords::minValidVels);

		unless (@B2I) {
			my($a) = 1 / (2 * sin(rad($ADCP->{BEAM_ANGLE})));
			my($b) = 1 / (4 * cos(rad($ADCP->{BEAM_ANGLE})));
			my($c) = $ADCP->{CONVEX_BEAM_PATTERN} ? 1 : -1;
			my($d) = $a / sqrt(2);
			@B2I = ([$c*$a,	-$c*$a,	0,		0	 ],
				    [0,		0,		-$c*$a,	$c*$a],
				    [$b,	$b,		$b,		$b	 ],
				    [$d,	$d,		-$d,	-$d	 ]);
		}

		if (!defined($v1)) {					# 3-beam solutions
			$RDI_Coords::threeBeamFlag = 1;
			$RDI_Coords::threeBeam_1++;
			$v1 = -($v2*$B2I[3][1]+$v3*$B2I[3][2]+$v4*$B2I[3][3])/$B2I[3][0];
		} elsif (!defined($v2)) {
			$RDI_Coords::threeBeamFlag = 1;
			$RDI_Coords::threeBeam_2++;
			$v2 = -($v1*$B2I[3][0]+$v3*$B2I[3][2]+$v4*$B2I[3][3])/$B2I[3][1];
		} elsif (!defined($v3)) {
			$RDI_Coords::threeBeamFlag = 1;
			$RDI_Coords::threeBeam_3++;
			$v3 = -($v1*$B2I[3][0]+$v2*$B2I[3][1]+$v4*$B2I[3][3])/$B2I[3][2];
		} elsif (!defined($v4)) {
			$RDI_Coords::threeBeamFlag = 1;
			$RDI_Coords::threeBeam_4++;
			$v4 = -($v1*$B2I[3][0]+$v2*$B2I[3][1]+$v3*$B2I[3][2])/$B2I[3][3];
		} else {
			$RDI_Coords::threeBeamFlag = 0;
			$RDI_Coords::fourBeam++;
		}
		
		return ($v1*$B2I[0][0]+$v2*$B2I[0][1],
				$v3*$B2I[1][2]+$v4*$B2I[1][3],
				$v1*$B2I[2][0]+$v2*$B2I[2][1]+$v3*$B2I[2][2]+$v4*$B2I[2][3],
				$v1*$B2I[3][0]+$v2*$B2I[3][1]+$v3*$B2I[3][2]+$v4*$B2I[3][3]);
	}
} # STATIC SCOPE

#--------------------------------------------------------------------------------------------------------------
# velInstrumentToEarth(\%ADCP,ens,v1,v2,v3,v4) => (u,v,w,e)
#	- $RDI_Coords::beamTransformation = 'LHR90'
#		- from Lohrmann, Hackett & Roet (J. Tech., 1990)
#		- eq A1 maps to RDI matrix M (sec 5.6) with
#			alpha = roll
#			beta = gimball_pitch
#			psi (pitch used for calculation) =  asin{sin(beta) cos(alpha) / sqrt[1- sin(alpha)^2 sin(beta)^2]}
#		- (I only checked for 0 heading, but this is sufficient)
#	- $RDI_Coords::beamTransformation = 'RDI'
#		- default prior to LADCP_w V1.3
#		- from RDI manual
#		- 99% accurate for p/r<8deg
#			=> 1cm/s error for 1m/s winch speed!
#--------------------------------------------------------------------------------------------------------------

{ # STATIC SCOPE
	my($hdg,$pitch,$roll,@I2E);

	sub velInstrumentToEarth(@)
	{
		my($ADCP,$ens,$v1,$v2,$v3,$v4) = @_;
		return undef unless (defined($v1) && defined($v2) &&
					   		 defined($v3) && defined($v4) &&
							 defined($ADCP->{ENSEMBLE}[$ens]->{PITCH}) &&
							 defined($ADCP->{ENSEMBLE}[$ens]->{ROLL}));
	
		unless (@I2E &&
				$pitch == $ADCP->{ENSEMBLE}[$ens]->{PITCH} &&
				$roll  == $ADCP->{ENSEMBLE}[$ens]->{ROLL}) {
			printf(STDERR "$0: warning HEADING_ALIGNMENT == %g ignored\n",
						  $ADCP->{HEADING_ALIGNMENT})
				if ($ADCP->{HEADING_ALIGNMENT});
			$hdg   = $ADCP->{ENSEMBLE}[$ens]->{HEADING} - $ADCP->{HEADING_BIAS}
				if defined($ADCP->{ENSEMBLE}[$ens]->{HEADING});
			$pitch = $ADCP->{ENSEMBLE}[$ens]->{PITCH};
			$roll  = $ADCP->{ENSEMBLE}[$ens]->{ROLL};
			my($rad_gimbal_pitch) = atan(tan(rad($pitch)) * cos(rad($roll)));
			my($rad_calc_pitch) = ($RDI_Coords::beamTransformation eq 'RDI') ? $rad_gimbal_pitch : 
								  asin(sin($rad_gimbal_pitch)*cos(rad($roll)) /
									   sqrt(1-sin(rad($roll))**2*sin($rad_gimbal_pitch)**2));
			my($sh,$ch) = (sin(rad($hdg)),cos(rad($hdg)))
				if defined($hdg);				
			my($sp,$cp) = (sin($rad_calc_pitch),cos($rad_calc_pitch));
			my($sr,$cr) = (sin(rad($roll)),	cos(rad($roll)));
			@I2E = $ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_UP}
				 ? (
					[-$ch*$cr-$sh*$sp*$sr,	$sh*$cp,-$ch*$sr+$sh*$sp*$cr],
					[-$ch*$sp*$sr+$sh*$cr,	$ch*$cp, $sh*$sr+$ch*$sp*$cr],
					[+$cp*$sr,				$sp,	-$cp*$cr,			],
				 ) : (
					[$ch*$cr+$sh*$sp*$sr,	$sh*$cp, $ch*$sr-$sh*$sp*$cr],
					[$ch*$sp*$sr-$sh*$cr,	$ch*$cp,-$sh*$sr-$ch*$sp*$cr],
					[-$cp*$sr,				$sp,	 $cp*$cr,			],
				 );
		}
		return defined($ADCP->{ENSEMBLE}[$ens]->{HEADING})
			   ? ($v1*$I2E[0][0]+$v2*$I2E[0][1]+$v3*$I2E[0][2],
				  $v1*$I2E[1][0]+$v2*$I2E[1][1]+$v3*$I2E[1][2],
				  $v1*$I2E[2][0]+$v2*$I2E[2][1]+$v3*$I2E[2][2],
				  $v4)
			   : (undef,undef,
				  $v1*$I2E[2][0]+$v2*$I2E[2][1]+$v3*$I2E[2][2],
				  $v4);
	}
} # STATIC SCOPE


sub velBeamToEarth(@)
{
	my($ADCP,$e,@v) = @_;
	return velInstrumentToEarth($ADCP,$e,velBeamToInstrument($ADCP,$e,@v));
}


#----------------------------------------------------------------------
# velEarthToInstrument() transforms earth to instrument coordinates
#	- based on manually inverted rotation matrix M (Sec 5.6 in coord-trans manual)
#		- Paul Wanis from TRDI pointed out that M is orthonormal, which
#		  implies that M^-1 = M' (where M' is the transpose), confirming
#		  the (unnecessary) derivation
#	- code was verified for both down- and uplookers
#	- missing heading data (IMP) causes undef beam velocities
#----------------------------------------------------------------------

{ # STATIC SCOPE
	my($hdg,$pitch,$roll,@E2I);

	sub velEarthToInstrument(@)
	{
		my($ADCP,$ens,$u,$v,$w,$ev) = @_;

		unless (@E2I &&
				$pitch == $ADCP->{ENSEMBLE}[$ens]->{PITCH} &&
				$roll  == $ADCP->{ENSEMBLE}[$ens]->{ROLL}) {
			$hdg = $ADCP->{ENSEMBLE}[$ens]->{HEADING} - $ADCP->{HEADING_BIAS} 
				if defined($ADCP->{ENSEMBLE}[$ens]->{HEADING});
			$pitch = $ADCP->{ENSEMBLE}[$ens]->{PITCH};
			$roll  = $ADCP->{ENSEMBLE}[$ens]->{ROLL};
			my($rad_gimbal_pitch) = atan(tan(rad($pitch)) * cos(rad($roll)));
			my($useRoll) = ($ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_UP}) ? $roll+180 : $roll;
			my($sh,$ch) = (sin(rad($hdg)),cos(rad($hdg)))
				if defined($hdg);				
			my($sp,$cp) = (sin($rad_gimbal_pitch),cos($rad_gimbal_pitch));
			my($sr,$cr) = (sin(rad($useRoll)),	  cos(rad($useRoll)));
			@E2I = ([$ch*$cr+$sh*$sp*$sr,	 $ch*$sp*$sr-$sh*$cr,	-$cp*$sr],		# M^-1 = R^-1 * P^-1 * R^-1
				    [$sh*$cp,				 $ch*$cp,				$sp	],
				    [$ch*$sr-$sh*$sp*$cr,	-$sh*$sr-$ch*$sp*$cr,	$cp*$cr]);
		}

		return defined($ADCP->{ENSEMBLE}[$ens]->{HEADING})
			   ? ($u*$E2I[0][0]+$v*$E2I[0][1]+$w*$E2I[0][2],
				  $u*$E2I[1][0]+$v*$E2I[1][1]+$w*$E2I[1][2],
				  $u*$E2I[2][0]+$v*$E2I[2][1]+$w*$E2I[2][2],
				  $ev)
			   : (undef,undef,undef,undef);

	} # velEarthToIntrument()
} # STATIC SCOPE

#----------------------------------------------------------------------
# velInstrumentToBeam() transforms instrument to beam coordinates
#	- based on manually solved eq system in sec 5.3 of coord manual
#	- does not implement bin-remapping
#	- returns undef for 3-beam solutions, as it is not known which
#	  beam was bad
#----------------------------------------------------------------------

{ # STATIC SCOPE
	my($a,$b,$c,$d);

	sub velInstrumentToBeam(@)
	{
		my($ADCP,$ens,$x,$y,$z,$ev) = @_;
		return undef unless (defined($x) + defined($y) +
					   		 defined($z) + defined($ev) == 4);

		unless (defined($a)) {
			$a = 1 / (2 * sin(rad($ADCP->{BEAM_ANGLE})));
			$b = 1 / (4 * cos(rad($ADCP->{BEAM_ANGLE})));
			$c = $ADCP->{CONVEX_BEAM_PATTERN} ? 1 : -1;
			$d = $a / sqrt(2);
		}

		return ( $x/(2*$a*$c) + $z/(4*$b) + $ev/(4*$d),
				-$x/(2*$a*$c) + $z/(4*$b) + $ev/(4*$d),
				-$y/(2*$a*$c) + $z/(4*$b) - $ev/(4*$d),
				 $y/(2*$a*$c) + $z/(4*$b) - $ev/(4*$d));

	}
} # STATIC SCOPE

#----------------------------------------------------------------------
# velEarthToBeam() combines velEarthToInstrument and velInstrumentToBeam
#----------------------------------------------------------------------

sub velEarthToBeam(@)
{
	my($ADCP,$ens,$u,$v,$w,$ev) = @_;
	return velInstrumentToBeam($ADCP,$ens,
				velEarthToInstrument($ADCP,$ens,$u,$v,$w,$ev));
}

#----------------------------------------------------------------------
# velEarthToBPw() returns w12 and w34 for beam-coordinate data
#	- I am grateful for Paul Wanis from TRDI who corrected a
#	  bug in my transformation (fixed in V1.3). [The bug did not
#	  affect the final w profiles significantly, because w12 and w34
#	  are used only as diagnostics.]
#	- algorithm:
#		1) rotate into instrument coordinates
#		2) w12 = w + e*tan(beam_angle)/sqrt(2)
#		   w34 = w - e*tan(beam_angle)/sqrt(2)
#		3) rotate into horizontal coords (earth coords w/o
#		   considering heading, i.e. same as earth coords
#		   in case of w
#	- the commented-out version above is a "brute-force"
#	  implementation which should give the same result
#----------------------------------------------------------------------

#sub velEarthToBPw(@)
#{
#   my(@bpv) = velBeamToBPEarth(&velEarthToBeam(@_));
#   return ($bpv[1],$bpv[3]);
#}

sub velEarthToBPw(@)
{
	my($ADCP,$ens,$u,$v,$w,$ev) = @_;
	my(@iv) = velEarthToInstrument(@_);
	my(@iv12) = my(@iv34) = @iv;
	$iv12[2] += $iv[3] * tan(rad($ADCP->{BEAM_ANGLE}))/sqrt(2);
	$iv34[2] -= $iv[3] * tan(rad($ADCP->{BEAM_ANGLE}))/sqrt(2);
	my(@ev12) = velInstrumentToEarth($ADCP,$ens,@iv12);
	my(@ev34) = velInstrumentToEarth($ADCP,$ens,@iv34);
	return ($ev12[2],$ev34[2]);
}

#======================================================================
# velBeamToBPEarth(@) calculates the vertical- and horizontal vels
# from the two beam pairs separately. Note that (w1+w2)/2 is 
# identical to the w estimated according to RDI (ignoring 3-beam 
# solutions).
#======================================================================

{ # STATIC SCOPE
	my($TwoCosBAngle,$TwoSinBAngle);

	sub velBeamToBPEarth(@)
	{
		my($ADCP,$ens,$b1,$b2,$b3,$b4) = @_;
		my($v12,$w12,$v34,$w34);

		return (undef,undef,undef,undef) 
			unless (defined($ADCP->{ENSEMBLE}[$ens]->{PITCH}) &&
                    defined($ADCP->{ENSEMBLE}[$ens]->{ROLL}));

		unless (defined($TwoCosBAngle)) {
			$TwoCosBAngle = 2 * cos(rad($ADCP->{BEAM_ANGLE}));
			$TwoSinBAngle = 2 * sin(rad($ADCP->{BEAM_ANGLE}));
		}
		my($rad_roll)  = rad($ADCP->{ENSEMBLE}[$ens]->{ROLL});							
		my($sr) = sin($rad_roll); my($cr) = cos($rad_roll);
		my($rad_gimbal_pitch) = atan(tan(rad($ADCP->{ENSEMBLE}[$ens]->{PITCH})) * $cr);	# gimbal pitch
		my($rad_calc_pitch) = ($RDI_Coords::beamTransformation eq 'RDI') ? $rad_gimbal_pitch :
							  asin(sin($rad_gimbal_pitch)*cos($rad_roll) /
								   sqrt(1-sin($rad_roll)**2*sin($rad_gimbal_pitch)**2));
		my($sp) = sin($rad_calc_pitch); my($cp) = cos($rad_calc_pitch);

		# Sign convention:
		#	- refer to Coord manual Fig. 3
		#	- v12 is horizontal velocity from beam1 to beam2, i.e. westward for upward-looking ADCP
		#	  with beam 3 pointing north (heading = 0)

		my($v12_ic,$w12_ic,$v34_ic,$w34_ic,$w_ic);
	    
		if (numberp($b1) && numberp($b2)) {
			$v12_ic = ($b1-$b2)/$TwoSinBAngle;									# instrument coords...
			$w12_ic = ($b1+$b2)/$TwoCosBAngle; 									# consistent with RDI convention
		}
		if (numberp($b3) && numberp($b4)) {
			$v34_ic = ($b4-$b3)/$TwoSinBAngle;
			$w34_ic = ($b3+$b4)/$TwoCosBAngle;
		}
	    
		if ($ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_DOWN}) {					# beampair Earth coords
			if (numberp($w12_ic) && numberp($w34_ic)) {
				$w_ic = ($w12_ic+$w34_ic) / 2;
				$v12 = $v12_ic*$cr		+ $v34_ic*0 		+ $w_ic*$sr;		# Lohrman et al. (1990) A1
				$v34 = $v12_ic*$sp*$sr	+ $v34_ic*$cp		- $w_ic*$sp*$cr;	#	- defined for z upward => DL
				$w12 =-$v12_ic*$cp*$sr	+ $v34_ic*$sp		+ $w12_ic*$cp*$cr;
	            $w34 =-$v12_ic*$cp*$sr  + $v34_ic*$sp       + $w34_ic*$cp*$cr;
	        } elsif (numberp($w12_ic)) {
				$v12 = $v12_ic*$cr		+ $w12_ic*$sr;	    
				$w12 =-$v12_ic*$cp*$sr	+ $w12_ic*$cp*$cr;
	        } elsif (numberp($w34_ic)) {
				$v34 = $v34_ic*$cp		- $w34_ic*$sp*$cr;    
				$w34 = $v34_ic*$sp		+ $w34_ic*$cp*$cr;
	        }
		} else {																
			if (numberp($w12_ic) && numberp($w34_ic)) {
				$w_ic = ($w12_ic+$w34_ic) / 2;
				$v12 =-$v12_ic*$cr		+ $v34_ic*0 		- $w_ic*$sr;		#	- as above with 1st & 3rd cols negated
				$v34 =-$v12_ic*$sp*$sr	+ $v34_ic*$cp		+ $w_ic*$sp*$cr;
				$w12 = $v12_ic*$cp*$sr	+ $v34_ic*$sp		- $w12_ic*$cp*$cr;
	            $w34 = $v12_ic*$cp*$sr  + $v34_ic*$sp       - $w34_ic*$cp*$cr;
	        } elsif (numberp($w12_ic)) {
				$v12 =-$v12_ic*$cr		- $w12_ic*$sr;		
				$w12 = $v12_ic*$cp*$sr	- $w12_ic*$cp*$cr;
	        } elsif (numberp($w34_ic)) {
				$v34 = $v34_ic*$cp		+ $w34_ic*$sp*$cr;
				$w34 = $v34_ic*$sp		- $w34_ic*$cp*$cr;
	        }
		}

		return ($v12,$w12,$v34,$w34);
	}
}

#===================================================================
# velBeamToBPInstrument(@) calculates the instrument-coordinate vels
# from the two beam pairs separately.
#	- in spite of the function name, the output is in ship
#	  coordinates (instr coords with w up)
#===================================================================

{ # STATIC SCOPE
	my($TwoCosBAngle,$TwoSinBAngle);

	sub velBeamToBPInstrument(@)
	{
		my($ADCP,$ens,$b1,$b2,$b3,$b4) = @_;
		my($v12,$w12,$v34,$w34);

		return (undef,undef,undef,undef) 
			unless (defined($ADCP->{ENSEMBLE}[$ens]->{PITCH}) &&
                    defined($ADCP->{ENSEMBLE}[$ens]->{ROLL}));

		unless (defined($TwoCosBAngle)) {
			$TwoCosBAngle = 2 * cos(rad($ADCP->{BEAM_ANGLE}));
			$TwoSinBAngle = 2 * sin(rad($ADCP->{BEAM_ANGLE}));
		}

		# Sign convention:
		#	- refer to Coord manual Fig. 3
		#	- v12 is horizontal velocity from beam1 to beam2
		#	- w is +ve upward, regardless of instrument orientation

		if (defined($b1) && defined($b2)) {
			$v12 = ($b1-$b2)/$TwoSinBAngle;
			$w12 = ($b1+$b2)/$TwoCosBAngle;
			$w12 *= -1 if ($ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_UP});
		}
		if (defined($b3) && defined($b4)) {
			$v34 = ($b4-$b3)/$TwoSinBAngle;
			$w34 = ($b3+$b4)/$TwoCosBAngle;
			$w34 *= -1 if ($ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_UP});
		}

		return ($v12,$w12,$v34,$w34);
	}
}

#======================================================================
# velApplyHdgBias() applies the heading bias, which is used to correct
# for magnetic declination for data recorded in Earth-coordinates ONLY.
# Bias correction for beam-coordinate data is done in velInstrumentToEarth()
#======================================================================

sub velApplyHdgBias(@)
{
	my($ADCP,$ens,$v1,$v2,$v3,$v4) = @_;
	return (undef,undef,undef,undef) 
		unless (defined($v1) && defined($v2) &&
				defined($ADCP->{ENSEMBLE}[$ens]->{HEADING}));

	my($sh) = sin(rad(-$ADCP->{HEADING_BIAS}));
	my($ch) = cos(rad(-$ADCP->{HEADING_BIAS}));

	return ( $v1*$ch + $v2*$sh,
			-$v1*$sh + $v2*$ch,
			 $v3			  ,
			 $v4			  );
}

#----------------------------------------------------------------------
# Pitch/Roll Functions
#----------------------------------------------------------------------

sub gimbal_pitch($$)	# RDI coord trans manual
{
	my($RDI_pitch,$RDI_roll) = @_;
	return 'nan' unless defined($RDI_pitch) && defined($RDI_roll);
	return deg(atan(tan(rad($RDI_pitch)) * cos(rad($RDI_roll))));
}

sub RDI_pitch($$)
{
	my($gimbal_pitch,$roll) = @_;
	return 'nan' unless defined($gimbal_pitch) && defined($roll);
	return deg(atan(tan(rad($gimbal_pitch))/cos(rad($roll))));
}

sub tilt_azimuth($$)
{
	my($gimbal_pitch,$roll) = @_;
	return 'nan' unless defined($gimbal_pitch) && defined($roll);
	return angle(deg(atan2(sin(rad($gimbal_pitch)),sin(rad($roll)))));
}

# - angle from vertical is home grown
# - angle between two unit vectors given by acos(v1 dot v2)
# - vertical unit vector v1 = (0 0 1) => dot product = z-component of v2
# - when vertical unit vector is pitched in x direction, followed by
#	roll in y direction:
#		x = sin(pitch)
#		y = cos(pitch) * sin(roll)
#		z = cos(pitch) * cos(roll)
#			has been checked with sqrt(x^2+y^2+z^2) == 1
# - for small angles, this is very similar to sqrt(pitch^2+roll^2)

sub angle_from_vertical($$)
{
	my($RDI_pitch,$RDI_roll) = @_;
	return 'nan' unless defined($RDI_pitch) && defined($RDI_roll);
	my($rad_pitch) = atan(tan(rad($RDI_pitch)) * cos(rad($RDI_roll)));
	return deg(acos(cos($rad_pitch) * cos(rad($RDI_roll))));
}

#----------------------------------------------------------------------
# alongBeamDZ(ADCP_dta,ens,beam) => (dz_to_bin1_center,bin_dz)
#	- calculate vertical distances:
#		- between transducer and bin1
#		- between adjacent bins
#	- no soundspeed correction
#	- for UL (Fig. 3 Coord Manual):
#		b1 = phi + roll		b2 = phi - roll
#		b3 = phi - pitch	b4 = phi + pitch
#	- for DL:
#		b1 = phi + roll		b2 = phi - roll
#		b3 = phi + pitch	b4 = phi - pitch
#----------------------------------------------------------------------

sub alongBeamDZ($$$)
{
	my($ADCP,$ens,$beam) = @_;

	my($tilt);																# determine tilt of given beam
	my($pitch) = $ADCP->{ENSEMBLE}[$ens]->{PITCH};
	my($roll)  = $ADCP->{ENSEMBLE}[$ens]->{ROLL};
	if ($beam == 0) {														# beam 1
		$tilt = &angle_from_vertical($pitch,$ADCP->{BEAM_ANGLE}+$roll);
	} elsif ($beam == 1) {													# beam 2
		$tilt = &angle_from_vertical($pitch,$ADCP->{BEAM_ANGLE}-$roll);
	} elsif ($beam == 2) {													# beam 3
		$tilt = $ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_UP}
			  ? &angle_from_vertical($ADCP->{BEAM_ANGLE}-$pitch,$roll)
			  : &angle_from_vertical($ADCP->{BEAM_ANGLE}+$pitch,$roll);
	} else {																# beam 4
		$tilt = $ADCP->{ENSEMBLE}[$ens]->{XDUCER_FACING_UP}
			  ? &angle_from_vertical($ADCP->{BEAM_ANGLE}+$pitch,$roll)
			  : &angle_from_vertical($ADCP->{BEAM_ANGLE}-$pitch,$roll);
	}
	return ($ADCP->{DISTANCE_TO_BIN1_CENTER}*cos(rad($tilt)),
			$ADCP->{BIN_LENGTH}*cos(rad($tilt)));
}
	
#----------------------------------------------------------------------
# binterp(ADCP_dta,ens,bin,ADCP_field) => @interpolated_vals
#	- interpolate beam velocities to nominal bin center
#	- field can be VELOCITY, ECHO_AMPLITUDE, ... 
#
# earthVels(ADCP_dta,ens,bin) 	=> (u,v,w,err_vel)
# BPEarthVels(ADCP_dta,ens,bin) => (v12,w12,v34,w34)
#	- new interface (V1.7)
#----------------------------------------------------------------------

sub binterp1($$$$$)														# interpolate along a single beam
{
	my($ADCP,$ens,$target_dz,$ADCP_field,$beam) = @_;
	
	my($dz2bin1,$bin_dz) = &alongBeamDZ($ADCP,$ens,$beam);
	my($floor_bin) = int(($target_dz-$dz2bin1) / $bin_dz);
	$floor_bin-- if ($floor_bin == $ADCP->{N_BINS}-1);
	
	my($y1) = $ADCP->{ENSEMBLE}[$ens]->{$ADCP_field}[$floor_bin][$beam];
	my($y2) = $ADCP->{ENSEMBLE}[$ens]->{$ADCP_field}[$floor_bin+1][$beam];
	$y2 = $y1 unless defined($y2);
	$y1 = $y2 unless defined($y1);
	return undef unless defined($y1);
	
	my($dz1) = $dz2bin1 + $floor_bin * $bin_dz;
	my($dz2) = $dz1 + $bin_dz;
	my($ifac) = ($target_dz - $dz1) / ($dz2 - $dz1);
	die("assertion failed\nifac = $ifac (target_dz = $target_dz, dz1 = $dz1, dz2 = $dz2)")
		unless ($ifac>= -0.5 && $ifac<=2);
	return $y1 + $ifac*($y2-$y1);
}

sub binterp($$$$)
{
	my($ADCP,$ens,$target_bin,$ADCP_field) = @_;

	my($crt) 	   = cos(rad($ADCP->{ENSEMBLE}[$ens]->{TILT}));			# calc center depth of target bin
	my($target_dz) = ($ADCP->{DISTANCE_TO_BIN1_CENTER} + $target_bin*$ADCP->{BIN_LENGTH}) * $crt;

	return (&binterp1($ADCP,$ens,$target_dz,$ADCP_field,0),				# interpolate all four beams
			&binterp1($ADCP,$ens,$target_dz,$ADCP_field,1),
			&binterp1($ADCP,$ens,$target_dz,$ADCP_field,2),
			&binterp1($ADCP,$ens,$target_dz,$ADCP_field,3));
}

sub earthVels($$$)
{
	my($ADCP,$ens,$bin) = @_;
	if ($RDI_Coords::binMapping eq 'linterp') {
		return velInstrumentToEarth($ADCP,$ens,
					velBeamToInstrument($ADCP,$ens,
						binterp($ADCP,$ens,$bin,'VELOCITY')));
	} elsif ($RDI_Coords::binMapping eq 'none') {
		return velInstrumentToEarth($ADCP,$ens,
					velBeamToInstrument($ADCP,$ens,
						@{$ADCP->{ENSEMBLE}[$ens]->{VELOCITY}[$bin]}));
    } else {
		die("earthVels(): unknown bin mapping '$RDI_Coords::binMapping '\n");
	}
}

sub BPEarthVels($$$)
{
	my($ADCP,$ens,$bin) = @_;
	if ($RDI_Coords::binMapping eq 'linterp') {
		return velBeamToBPEarth($ADCP,$ens,binterp($ADCP,$ens,$bin,'VELOCITY'));
	} elsif ($RDI_Coords::binMapping eq 'none') {
		return velBeamToBPEarth($ADCP,$ens,@{$ADCP->{ENSEMBLE}[$ens]->{VELOCITY}[$bin]});
	} else {
		die("BPEarthVels(): unknown bin mapping '$RDI_Coords::binMapping '\n");
	}
}

#----------------------------------------------------------------------

1;
