#======================================================================
#          L I B E O S 8 3 . P L 
#          doc: Mon Mar  8 08:22:05 1999
#          dlm: Tue Feb  5 16:42:28 2013
#          (c) 1999 A.M. Thurnherr
#          uE-Info: 20 59 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# Perl Implementation of UNESCO Eqn of State 1983

# Notes:
# 	- copied from eos83calc.c which was in turn...
#	- copied from pexec_v4 (incl comments)
#	- only subset of functions implemented
#	- some attempt at cleaning up the code has been made
#	- pressures in dbar throughout
#	- no temperature scale assumed; set PARAM ITS=90|68
#	- T90*1.00024=T68
#	- check values calculated with T68
#	- no conductivity unit assumed; set PARAM cond.unit=S/m|mS/cm

# HISTORY:
#	Mar 08, 1999: - translated by hand from krc
#				  - added &alpha(), &beta(), &Rrho(), &TurnerAngle()
#	Mar 13, 1999: - cosmetic changes
#	Mar 14, 1999: - BUG NAN instead of NaN
#	Mar 21, 1999: - make $sigmaR optional in &sVolAnom()
#	Mar 31, 1999: - alias &potemp() = &theta(); &podens() = &sigma()
#				  - added &temp() to calc in-situ from potemp
#	Sep 18, 1999: - parameter typechecking
#	Aug 28, 2000: - added PARAM T68 check
#	Aug 29, 2000: - forced temp_scale param check --- set to T68 or T90
#	Sep 25, 2000: - changed temp_scale to 68 or 90 (easier check)
#				  - check for temp_scale during loading
#	Nov 07, 2000: - added &dynHt()
#				  - strictified
#	Nov 13, 2000: - removed temp_scale check during loading (STUPID,
#					because PARAMs are only available after header
#					is read)
#	Feb 28, 2001: - added &rho(S,T,P)
#	Mar 28, 2001: - changed Rrho() to use podens
#				  - optimized &theta() for P == Pref
#	Apr  2, 2001: - &TurnerAngle() disabled pending adaptation to new Rrho()
#	Apr  3, 2001: - updated &TurnerAngle()
#	Jul 17, 2001: - cosmetics
#				  - added &grav(), &potErgAnom()
#	Jul 18, 2001: - cosmetics
#	Jul 20, 2001: - changed temp_scale to ITS
#	Nov 26, 2001: - added &g(), &f()
#	Dec 26, 2005: - update notes
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#				  - nan must be quoted for use strict
#	Nov  5, 2006: - added K15toSalin
#	Oct 18, 2007: - adapted to new &antsFunUsage()
#				  - changed order of &salin() params
#	Oct 19, 2007: - continued
#				  - removed &grav(), podens(), potemp()
#	Dec  1, 2007: - made theta(), sigma(), rho() return nan on nan input
#	Dec 21, 2007: - BUG: grav() was still used
#	Jan 20, 2008: - BUG: theta(), sigma(), rho() still generated error on nan in
#				  - made depth(), dynht(), potErgAnom() return nan on nan in
#	Jan  4, 2011: - maded salin(), sVel() return nan on nan in
#	Oct  6, 2011: - added %cond.unit (analogous to %ITS)

require "$ANTS/libvec.pl";
use strict;

#======================================================================
# PART I: stuff taken from PEXEC
#======================================================================

{ # BEGIN STATIC SCOPE

	my($TCONV);

	sub TCONV()
	{
		unless (defined($TCONV)) {
			my($ITS) = &antsRequireParam('ITS');
			if ($ITS == 68) {
				$TCONV = 1;
			} elsif ($ITS == 90) {
				$TCONV = 1.00024;
			} else {
				croak("$0: illegal PARAM-value ITS=$ITS\n");
	        }
	    }
	    return $TCONV;
	}

} # END STATIC SCOPE

#---------------------------------------------------------------------- 
#	ADIABATIC TEMPERATURE GRADIENT DEG C/BAR							 
#	REF: BRYDEN,H.,1973,DEEP-SEA RES.,20,401-408						 
#	CHECK VALUE: ATGR80=3.255976E-3 FOR S=40 NSU,T=40 DEG C,			 
#	PIN=10000 DECIBARS
#	NB: real check value appears to be 3.255976E-4; this makes sense
#	    as check value of potential temperature below is correct. Also
#       note the 0.1 factor on return.
#---------------------------------------------------------------------- 

{ my(@fc);
	sub adiaTempGrad(@)
	{
		my($S,$T,$P) = &antsFunUsage(3,'fff','[salin, temp, press(db)]',
									 \@fc,'salin','temp','press',@_);
		my($DS);
		my($TCONV) = &TCONV();
	
		$T *= $TCONV;		# use T68 
		$P *= 0.1;
		$DS = $S - 35.0;
		return 0.1 * ((((-2.1687E-13*$T+1.8676E-11)*$T-4.6206E-10)*$P
					+((2.7759E-10*$T-1.1351E-8)*$DS+((-5.4481E-12*$T
					+8.733E-10)*$T-6.7795E-8)*$T+1.8741E-6))*$P
					+(-4.2393E-7*$T+1.8932E-5)*$DS
					+((6.6228E-9*$T-6.836E-7)*$T+8.5258E-5)*$T+3.5803E-4) / $TCONV;
	}
}

#---------------------------------------------------------------------- 
# TO COMPUTE LOCAL POTENTIAL TEMPERATURE AT PR							 
#	USING BRYDEN 1973 POLYNOMIAL FOR ADIABATIC LAPSE RATE				 
#	AND RUNGE-KUTTA 4-TH ORDER INTEGRATION ALGORITHM.					 
#	REF: BRYDEN,H.,1973,DEEP-SEA RES.,20,401-408						 
#	FOFONOFF,N.,1977,DEEP-SEA RES.,24,489-491							 
#	CHECK VALUE: PTMP83 =36.89072 FOR S=40 NSU,T=40 DEG C,				 
#	P(MEASURED PRESSURE)=10000 DECIBARS,Pref=0 DECIBARS
#---------------------------------------------------------------------- 

{ my(@fc);
	sub theta(@)
	{
		my($S,$T,$P,$Pref) =
			&antsFunUsage(4,'....','[salin, temp, press(db),] refpress(db)',
						  \@fc,'salin','temp','press',undef,@_);
		return 'nan' unless numberp($S) && numberp($T) && numberp($P);
		my($H,$XK,$Q);
		my($TCONV) = &TCONV();
	
		return $T if ($P == $Pref);
		$T *= $TCONV;	# use T68 
		$H = $Pref - $P;
		$XK = $H * &adiaTempGrad($S,$T/$TCONV,$P)*$TCONV;
		$T += 0.5 * $XK;
		$Q = $XK;
		$P += 0.5 * $H;
		$XK = $H * &adiaTempGrad($S,$T/$TCONV,$P)*$TCONV;
		$T += 0.29289322 * ($XK-$Q);
		$Q = 0.58578644*$XK + 0.121320344*$Q;
		$XK = $H * &adiaTempGrad($S,$T/$TCONV,$P)*$TCONV;
		$T += 1.707106781 * ($XK-$Q);
		$Q = 3.414213562*$XK - 4.121320344*$Q;
		$P += 0.5*$H;
		$XK = $H * &adiaTempGrad($S,$T/$TCONV,$P)*$TCONV;
		return ($T + ($XK-2.0*$Q)/6.0)/$TCONV;
	}
}

# can't easily do default fields because theta field name is not unique
sub temp(@)
{
	my($S,$T,$P,$Pref) =
		&antsFunUsage(4,"ffff","salin, potemp, press(db), refpress(db)",@_);
	return &theta($S,$T,$Pref,$P);
}

#---------------------------------------------------------------------- 
#	Calculation of specific volume anomaly
#		Gill (1982), p.215: - specific volume = inverse of density
#							- SVA referenced to same press, T=0, S=35
#																		 
#	 *************************************************					 
#	 *** USES EQUATION OF STATE FOR SEA WATER 1980 ***					 
#	 *************************************************					 
#																		 
#	Check value. SVAN83=981.30210E-8, SIGMA=59.82037					 
#	for S=40, T=40, P=10000												 
#																		 
# 	NB: - this one was a bitch to translate, used f2c and it shows :-)	 
#		- the 1e-8 factor in the check value is wrong; yup: see gill p.215
#		  (typical units are 1e-8m^3kg^-1)
#		- check val appears to be slightly off, I get 981.30187319561
#	  
#---------------------------------------------------------------------- 

sub sVolAnom(@)
{
	my($S,$T,$P,$sigmaR) =
		&antsFunUsage(-3,'fff','salin, temp, press(db)[, ref to sigma var]',@_);
	my($r3500) = 1028.1063;
	my($r4)	   = 4.8314e-4;
	my($dr350) = 28.106331;

	my($temp0,$temp1,$temp2,$temp3,$temp4);
	my($dvan,$dr35p,$p,$t,$dk,$pk,$sr,$gam,$sig,$rk35,$sva,$v350p);

	my($TCONV) = &TCONV();

	$t = $T*$TCONV;								# use T68 
	$p = $P / 10.;
#	$sr = sqrt(abs($S));
	$sr = sqrt($S);
	$temp3 = (((($t * 6.536332e-9 - 1.120083e-6) * $t + 
	  1.001685e-4) * $t - .00909529) * $t + .06793952) * $t 
	  - 28.263737;
	$temp2 = ((($t * 5.3875e-9 - 8.2467e-7) * $t + 7.6438e-5) 
	  * $t - .0040899) * $t + .824493;
	$temp1 = ($t * -1.6546e-6 + 1.0227e-4) * $t - .00572466;
	$sig = ($r4 * $S + $temp1 * $sr + $temp2) * $S + $temp3;
	$v350p = 1. / $r3500;
	$sva = -$sig * $v350p / ($r3500 + $sig);
	$$sigmaR = $sig + $dr350 if (defined($sigmaR));
	return $sva * 1e8 if ($p == 0.0);

	$temp0 = ($t * 9.1697e-10 + 2.0816e-8) * $t - 9.9348e-7;
	$temp1 = ($t * 5.2787e-8 - 6.12293e-6) * $t + 3.47718e-5;
	$temp1 = $temp1 + $temp0 * $S;
	$temp0 = 1.91075e-4;
	$temp2 = ($t * -1.6078e-6 - 1.0981e-5) * $t + .0022838;
	$temp3 = (($t * -5.77905e-7 + 1.16092e-4) * $t + .00143713) * $t - .1194975;
	$temp3 = ($temp0 * $sr + $temp2) * $S + $temp3;
	$temp0 = ($t * -5.3009e-4 + .016483) * $t + .07944;
	$temp2 = (($t * -6.167e-5 + .0109987) * $t - .603459) * $t + 54.6746;
	$temp4 = ((($t * -5.155288e-5 + .01360477) * $t - 2.327105) * $t + 148.4206) * $t - 1930.06;
	$temp4 = ($temp0 * $sr + $temp2) * $S + $temp4;
	$dk = ($temp1 * $p + $temp3) * $p + $temp4;
	$rk35 = ($p * 5.03217e-5 + 3.359406) * $p + 21582.27;
	$gam = $p / $rk35;
	$pk = 1. - $gam;
	$sva = $sva * $pk + ($v350p + $sva) * $p * $dk / ($rk35 * ($rk35 + $dk));
	$v350p *= $pk;
	$dr35p = $gam / $v350p;
	$dvan = $sva / ($v350p * ($v350p + $sva));
	$$sigmaR = $dr350 + $dr35p - $dvan if (defined($sigmaR));
	return $sva * 1e8;
}

#----------------------------------------------------------------------
# Dynamic Height (from dyht83.F)
#	Usage:
#		- dynHt(salin,temp,press[,idx])
#	Check Values from PEXEC:
#		- dynHt(40,18,20)  -> -.01879
#		- dynHt(??,16,50)  -> -.03194
#		- dynHt(??,14,100) -> -.00255
#	NB: - check values 2 & 3 do not appear to check out
#		- checked against WHOI-supplied BBTRE data indicates max
#		  diff of 1e-3 dyn.m at 5141m
#		- use different idx to use multiple times in single program
#		  (c.f. [gshear])
#		- behaves the same as the pexec version with PFIRST=0
#		- dynamic height seems to be defined (1e-5 factor) to allow
#		  station distance to be in km and velocities in cm/s
#----------------------------------------------------------------------

{ # BEGIN static scope

	my(@lastP,@lastAnom,@ht);

	sub dynHt(@)
	{
		my($S,$T,$P,$idx) =
			&antsFunUsage(-3,"...","salin, temp, press(db)[, <idx>]",@_);
		return 'nan' unless numbersp($S,$T,$P);
		my($anom) = sVolAnom($S,$T,$P) * 1e-5;

		if (!defined($ht[$idx])) {					# first call
			$ht[$idx] = $P * $anom;
		} else {									# successive calls
		    croak("$0: pressure not increasing monotonically ($lastP[$idx] -> $P)\n")
		    	if ($P < $lastP[$idx]);
			$ht[$idx] += ($P-$lastP[$idx]) * ($anom+$lastAnom[$idx])/2;
		}
		$lastP[$idx] = $P; $lastAnom[$idx] = $anom;

		return $ht[$idx];
	}

} # END static scope

#----------------------------------------------------------------------
# Local Gravity (from grav83.F)
#	Usage:
#		- g(press,lat)
#	Check Values:
#		- g(10000,30) = 9.804160
#----------------------------------------------------------------------

{ my(@fc);
	sub g(@)
	{
		my($P,$lat) = &antsFunUsage(2,'ff','[press(db), lat]',\@fc,'press','%lat',@_);
	
		my($x) = sin($lat/57.29578) ** 2;				    
		my($g) = 9.780318*(1.0+(5.2788e-3+2.36e-5*$x)*$x);	# global variation
		return $g + 1.092e-6 * $P;							# pressure correction
	}
}

#----------------------------------------------------------------------
# Coriolis frequency
#	Usage:
#		- f(%lat)
#----------------------------------------------------------------------

{ my(@fc);
	sub f(@)
	{
		my($lat) = &antsFunUsage(1,'f','[lat]',\@fc,'%lat',@_);
		my($Omega) = 7.292e-5;								# Gill (1982)
		return 2 * $Omega * sin(rad($lat));
	}
}

#----------------------------------------------------------------------
# Potential Energy Anomaly (from pean83.F)
#	Usage:
#		- potErgAnom(salin,temp,press,refPress,lat)
#	Check Values from PEXEC: (NB: sequence of calls)
#		- potErgAnom(40,18, 20,0,49.2235) = -1.91462
#		- potErgAnom(38,16, 50,0,49.2235) = -4.31092
#		- potErgAnom(36,14,100,0,49.2235) = 24.82922
#	Units:
#		- Gill (1982) p.45: m^2/s^2 = J/kg
#	NB:
#		- geopotential Phi is PEA wrt zero pressure
#		- PE of volume is volume integral of rho*PEA (c.f. Gill, p.80)
#		- check value lat calculated so that g(0,lat) ~ 9.81
#		- IF Pref<P ON 1ST CALL, HEIGHT WILL BE CALCULATED FROM LEVEL
#		  Pref.  HENCE IF Pref = 0.0, FROM SEA SURFACE DOWN.
#		- different to pexec, this version sets values for P<Pref to nan
#----------------------------------------------------------------------

{ # BEGIN STATIC SCOPE

	my($gzero,$H,$lastZ,$lastP);

	sub potErgAnom(@)
	{
		my($S,$T,$P,$Pref,$lat) =
	        &antsFunUsage(5,".....","salin, temp, press(db), refpress(db), lat",@_);
	    return 'nan' unless numbersp($S,$T,$P,$Pref,$lat);

		return 'nan' if ($P < $Pref);

		$gzero = g(0,$lat) unless (defined($gzero));		# 1st time
		my($g) = $gzero + 1.113e-4*$P;

		my($anom) = sVolAnom($S,$T,$P) * 1e-3;
		my($Z) = $anom * $P/$g;

		if (defined($H)) {									# not 1st time
		    croak("$0: pressure not increasing monotonically\n")
		    	if ($P < $lastP);
			$H += ($Z+$lastZ) * ($P-$lastP)*0.5;
		} else {
			$H = (($anom*$Pref/$g)+$Z)*($P-$Pref)*0.5;
        }
        
		$lastP = $P; $lastZ = $Z;
		return $H;
    }

} # END static scope

#---------------------------------------------------------------------- 
# Density at pressure P (P - Measured pressure)						 
# 						(PREF - Reference pressure)					 
# Equation of state for seawater proposed by JPOTS 1980				 
# References															 
#		Millero et al 1980, Deep Sea Res.,27A,255-264					 
#		Jpots Ninth Report 1978, Tenth Report 1980						 
# Units:																 
#	   Pressure   P  Decibars									 
#	   Temperature T  Deg Celcius (IPTS-68)						 
#	   Salinity   S  NSU (IPSS-78)								 
#	   Density   RHO KG/M**3										 
#	   Spec. Vol.  EOS80 M**3/KG									 
#	check value. 43.331642 for P=10000,PREF=5000,T=40,S=40				 
# NB: check value appears to be 42.33164!!!							 
#---------------------------------------------------------------------- 

{ my(@fc); 
	sub sigma(@)
	{
		my($S,$T,$P,$Pref) =
			&antsFunUsage(4,'....','[salin, temp, press(db),] refpress(db)',
						  \@fc,'salin','temp','press',undef,@_);
		return 'nan' unless numberp($S) && numberp($T) && numberp($P);
		my($sig);
		&sVolAnom($S,&theta($S,$T,$P,$Pref),$Pref,\$sig);
		return $sig;
	}
}

{ my(@fc);
	sub rho(@)
	{
		my($S,$T,$P) = &antsFunUsage(3,'...','[salin, temp, press(db)]',
									 \@fc,'salin','temp','press',@_);
		return 'nan' unless numberp($S) && numberp($T) && numberp($P);
		return 1000 + &sigma($S,$T,$P,$P);
	}
}

#---------------------------------------------------------------------- 
#	FUNCTION TO CONVERT CONDUCTIVITY TO SALINITY ACCORDING TO THE		 
#	ALGORITHMS RECOMMMENDED BY JPOTS USING THE 1978 PRACTICAL 			 
#	SALINITY SCALE (IPSS-78) AND IPTS-68 FOR TEMPERATURE. 				 
#	C1535=CONDUCTIVITY (FROM CULKIN&SMITH,1980,J.OCEAN.ENG.VOL.5 		 
#    PP22-23) = 42.9140 AT    PRES=0.0, 							 
#	SALINITY 35 NSU AND TEMPERATURE 15 DEG CELSIUS (IPTS-68) 			 
#	PRESSURE=DECIBARS 													 
#	RETURNS ZERO FOR CND<.0005 		 									 
#	CHECKVALUES.... 													 
#	SAL83 =40.000000 FOR CND=81.025545,T=40 DEG C,PIN=10000 			 
#   DECIBARS														 
#	WRITTEN BY N FOFONOFF; REVISED OCT 6 1980 							 
#	FCN SAL83, XR=SQRT(RT) 												 
#	DERIVATIVE WRT XR ; DSAL/DXR 										 
#	RT35 																 
#	C,B,A, POLYNOMIALS 													 
#	NB: - done using f2c (couldn't be bothered)							 
#		- removed SAL->COND												 
#---------------------------------------------------------------------- 

{ my(@fc);
  my($cond_scale);	# 1 for mS/cm, 10 for S/m
	sub salin(@)
	{
		my($C,$T,$P) = &antsFunUsage(3,'...','[cond, temp, press(db)]',
									 \@fc,'cond','temp','press',@_);
		return 'nan' unless numberp($C) && numberp($T) && numberp($P);
		my($r__,$dt,$rt,$c1535);
		my($TCONV) = &TCONV();

		unless (defined($cond_scale)) {				# deal with different conductivity units
			my($cu) = &antsRequireParam('cond.unit');
			if    ($cu eq 'S/m')   { $cond_scale = 10; }
			elsif ($cu eq 'mS/cm') { $cond_scale = 1;  }
			else { croak("$0: illegal PARAM-value cond.unit=$cu\n"); }
		}
		$C *= $cond_scale;
	
		return 0.0 if ($C <= 5e-4); 				# zero salinity trap 
		$T *= $TCONV;								# use T68 scale 
		$c1535 = 42.914;
		$dt = $T - 15.0;
		$P *= .1;									# convert pressure to bars 
		$r__ = $C / $c1535; 						# convert cond to salin
		$rt = $r__ / ((((($T * 1.0031e-9 - 6.9698e-7) * $T + 
		  1.104259e-4) * $T + .0200564) * $T + .6766097) * ((($P 
		  * 3.989e-12 - 6.37e-8) * $P + 2.07e-4) * $P / (
		  ($T * 4.464e-4 + .03426) * $T + 1. + ($T *
		  -.003107 + .4215) * $r__) + 1.));
		$rt = sqrt(abs($rt));
		return (((($rt * 2.7081 - 7.0261) * $rt + 14.0941) *
		   $rt + 25.3851) * $rt - .1692) * $rt + .008 + 
		  $dt / ($dt * .0162 + 1.) * ((((($rt * -.0144 + 
		  .0636) * $rt - .0375) * $rt - .0066) * $rt - 
		  .0056) * $rt + 5e-4);
	}
}

#----------------------------------------------------------------------
# K15toSalin; see http://ioc.unesco.org/oceanteacher/OceanTeacher2/01_GlobOcToday/02_CollDta/02_OcDtaFunda/03_T&SScales/TemperatureAndSalinityScales.htm
#----------------------------------------------------------------------

sub K15toSalin(@)
{
	my($K15) = &antsFunUsage(1,'f','K15',@_);
	return  0.0080 -  0.1692 * $K15**0.5
				   + 25.3851 * $K15**1.0
				   + 14.0941 * $K15**1.5
				   -  7.0261 * $K15**2.0
				   +  2.7081 * $K15**2.5;
}

#---------------------------------------------------------------------- 
#	DEPTH IN METERS FROM PRESSURE IN DECIBARS USING						 
#	SAUNDERS AND FOFONOFF'S METHOD.										 
#	DEEP SEA RES., 1976,23,109-111.										 
#	FORMULA REFITTED FOR EOS80											 
#	CHECK VALUE. 9712.654 M FOR PIN=10000 DECIBARS,LATITUDE=30 DEG		 
#	..CONVERT PRESSURE TO BARS
#	NB: results are closer to Saunders, JPO 11, 1981 than ref given
#	    above. They are not exact, either, however.
#---------------------------------------------------------------------- 

{ my(@fc);
	sub depth(@)
	{
		my($P,$lat) = &antsFunUsage(2,'..','[press(db), lat]',\@fc,'press','%lat',@_);
		return 'nan' unless numbersp($P,$lat);
		my($x) = sin($lat/57.29578);
		$P *= 0.1;
		$x = $x*$x;
		return ((((-1.82E-11*$P+2.279E-7)*$P-2.2512E-3)*$P+97.2659)*$P) /
			  (9.780318*(1.0+(5.2788E-3+2.36E-5*$x)*$x) + 1.092E-5*$P);
	}
}

#----------------------------------------------------------------------
#	Convert depth to pressure using 2nd order polynomial
#	From file pdepth.F (pexec)
#	This is based on Saunders, JPO 11, 1981
#----------------------------------------------------------------------

{ my(@fc);
	sub press(@)
	{
		my($d,$lat) = &antsFunUsage(2,'ff','[depth, lat]',\@fc,'depth','%lat',@_);
		my($c1) = 5.92E-3 + 5.25E-3 * sin($lat/57.29578) ** 2;
		my($c2) = 2.21E-6;
		my($press) = (1 - $c1 - sqrt((1 - $c1)**2 - 4*$d*$c2)) / (2*$c2);
		my($derr) = abs(&depth($press,$lat) - $d);
	    
		&antsInfo("WARNING (libEOS83.pl): %.1gm depth error due to pressure " .
				  "approximation", $derr) if ($derr >= 1);
		return $press;
	}
}

#---------------------------------------------------------------------- 
#	SOUND SPEED SEAWATER (CHEN & MILLERO 1977, JASA,62,1129-1135) 		 
#	SPEED IN M/S, P IN DECIBARS, T DEG C (IPTS-68), S NSU(IPSS-78) 		 
#	CHECK VALUE : 1731.9954 M/S FOR PIN=10000, T=40, C,S=40 			 
#	NB: - f2c used (because of fortran `equivalence')					 
#---------------------------------------------------------------------- 

{ my(@fc);
	sub sVel(@)
	{
		my($S,$T,$P) = &antsFunUsage(3,'...','[salin, temp, press(db)]',
									 \@fc,'salin','temp','press',@_);
		return 'nan' unless numberp($S) && numberp($T) && numberp($P);
		my($temp0,$temp1,$temp2,$temp3);
		my($a,$b,$c__,$d__,$sr);
		my($TCONV) = &TCONV();
	
		$T *= $TCONV;									# T68 
		$P *= .1;										# CONVERT PRESSURE TO BARS 
		$sr = sqrt(abs($S));							# S**2 TERM 
		$d__ = .001727 - $P * 7.9836e-6;
		$temp1 = $T * 1.7945e-7 + 7.3637e-5;			# S**3/2 TERM 
		$temp0 = -.01922 - $T * 4.42e-5;
		$b = $temp0 + $temp1 * $P;
		$temp3 = ($T * -3.389e-13 + 6.649e-12) * $T + 1.1e-10;	# S**1 TERM 
		$temp2 = (($T * 7.988e-12 - 1.6002e-10) * $T + 9.1041e-9) * $T - 3.9064e-7;
		$temp1 = ((($T * -2.0122e-10 + 1.0507e-8) * $T - 6.4885e-8) * $T
			- 1.258e-5) * $T + 9.4742e-5;
		$temp0 = ((($T * -3.21e-8 + 2.006e-6) * $T + 7.164e-5) * $T - .01262)
			* $T + 1.389;
		$a = (($temp3 * $P + $temp2) * $P + $temp1) * $P + $temp0;
		$temp3 = ($T * -2.3643e-12 + 3.8504e-10) * $T - 9.7729e-9;	# S**0 TERM 
		$temp2 = ((($T * 1.0405e-12 - 2.5335e-10) * $T + 2.5974e-8) * $T
			- 1.7107e-6) * $T + 3.126e-5;
		$temp1 = ((($T * -6.1185e-10 + 1.3621e-7) * $T - 8.1788e-6) * $T
			+ 6.8982e-4) * $T + .153563;
		$temp0 = (((($T * 3.1464e-9 - 1.478e-6) * $T + 3.342e-4) * $T - .0580852)
			* $T + 5.03711) * $T + 1402.388;
		$c__ = (($temp3 * $P + $temp2) * $P + $temp1) * $P + $temp0;
		return $c__ + ($a + $b * $sr + $d__ * $S) * $S; 		# SOUND SPEED RETURN 
	}
}

#======================================================================
# PART II: Homegrown Stuff
#======================================================================

#----------------------------------------------------------------------
# &alpha(S,T,P)		linear thermal expansion coefficient
# 	Notes:			- use temperature interval of 0.2 degrees
#					- depth instead of pressure ok
# 	Check Value:	- alpha(35,2,6000) = 0.000209447279306853
#----------------------------------------------------------------------

sub alpha(@)
{
	my($S,$T,$P) = &antsFunUsage(3,"fff","salin, temp, press | depth",@_);
	return (&sigma($S,$T-.1,$P,$P) - &sigma($S,$T+.1,$P,$P))
			/ (.2 * (1000+&sigma($S,$T,$P,$P)));
}

#----------------------------------------------------------------------
# &beta(S,T,P)		linear haline contraction coefficient
# 	Notes:			- use salinity interval of 0.02 psu
#					- depth instead of pressure ok
# 	Check Value:	- beta(35,2,6000) = 0.000718513652714652 (should check Gill)
#----------------------------------------------------------------------

sub beta(@)
{
	my($S,$T,$P) = &antsFunUsage(3,"fff","salin, temp, press | depth",@_);
	return (&sigma($S+0.01,$T,$P,$P) - &sigma($S-0.01,$T,$P,$P))
			/ (.02 * (1000+&sigma($S,$T,$P,$P)));
}

#----------------------------------------------------------------------
# &Rrho(midS,S0,S1,midT,T0,T1,midP,P0,P1)	stability ratio
# 	Notes:			- depth instead of pressure ok
# 	Check Value:	- Rrho(35.05,35.1,35,4.27,4.82,3.72,2100,2100,2100) = 2.222
#----------------------------------------------------------------------

sub alphaDT(@)
{
	my($S,$T0,$T1,$P,$P0,$P1) = @_;
#		&antsFunUsage(6,"ffffff","S, T0, T1, P, P0, P1",@_);
	my($sgn) = ($P1 > $P0) ? 1 : -1;
	return $sgn * (&sigma($S,$T1,$P1,$P) - &sigma($S,$T0,$P0,$P));
}

sub betaDS(@)
{
	my($S0,$S1,$T,$P,$P0,$P1) = @_;
#		&antsFunUsage(6,"ffffff","S0, S1, T, P, P0, P1",@_);
	my($sgn) = ($P1 > $P0) ? 1 : -1;
	return $sgn * (&sigma($S0,$T,$P0,$P) - &sigma($S1,$T,$P1,$P));
}

sub Rrho(@)
{
	my($S,$S0,$S1,$T,$T0,$T1,$P,$P0,$P1) =
		&antsFunUsage(9,"fffffffff","S, S0, S1, T, T0, T1, P, P0, P1",@_);
	my($aDT) = &alphaDT($S,$T0,$T1,$P,$P0,$P1);
	my($bDS) = &betaDS($S0,$S1,$T,$P,$P0,$P1);
	return $bDS == 0 ? 'nan' : $aDT / $bDS;
}

#----------------------------------------------------------------------
# &TurnerAngle(midS,S0,S1,midT,T0,T1,midP,P0,P1)	Turner Angle
# 	Notes:						- c.f. &Rrho()
#								- -45<Tu<45 	doubly stable
#								- Tu<-90, Tu>90 statically unstable
#								- 45<Tu<90 		fingering regime
#								- -90<Tu<-45	diffusive regime
# 	Check Value: TurnerAngle(35.05,35.1,35,4.27,4.82,3.72,2100,2100,2100.01) = 69.2296333539803
#----------------------------------------------------------------------

sub TurnerAngle(@)
{
	my($S,$S0,$S1,$T,$T0,$T1,$P,$P0,$P1) =
		&antsFunUsage(9,"fffffffff","S, S0, S1, T, T0, T1, P, P0, P1",@_);
	my($aDT) = &alphaDT($S,$T0,$T1,$P,$P0,$P1);
	my($bDS) = &betaDS($S0,$S1,$T,$P,$P0,$P1);
	return atan2($aDT+$bDS,$aDT-$bDS)*57.29577951;
}

1;

