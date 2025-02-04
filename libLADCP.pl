#======================================================================
#                    L I B L A D C P . P L 
#                    doc: Wed Jun  1 20:38:19 2011
#                    dlm: Thu Jan 12 11:26:24 2023
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 276 34 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Jun  1, 2011: - created
#	Jul 29, 2011: - improved
#	Aug 10, 2011: - made correct
#	Aug 11, 2011: - added "convenient combinations"
#	Aug 18, 2011: - made buoyancy frequency non-constant in S()
#	Jan  4, 2012: - improved T_VI to allow correcting even without superensembles
#	Jan  5, 2012: - removed S(), which is just pwrdens/N^2 (rather than
#				    pwrdens/N^2/(2pi) as I erroneously thought)
#	Jan 18, 2012: - added T_VI_alt() to allow assessment of tilt correction extrema
#	Aug 22, 2012: - added documentation
#				  - added T_w()
#	Sep 24, 2012: - made "k" argument default in T_w()
#	Oct 25, 2012: - renamed T_SM() to T_ASM()
#	Jun 26, 2013: - added T_w_z()
#				  - added parameter checks to processing-specific corrections
#	May 18, 2015: - added pulse length to T_w() and T_w_z()
#	Apr 25, 2018: - added eps_VKE() parameterization
#	Apr  5, 2018: - adapted to improved antsFunUsage()
#				  - BUG eps_VKE() had erroneous string
#	Sep  9, 2021: - removed T_w_z(); consistent with Thurnherr (JAOT 2012),
#				    vertical divergence spectra should be corrected with
#					T_w()
#	Jan 10, 2023: - renamed T_interp() to T_interpgrid() to avoid confusion
#				  - added T_regrid()
#				  - uncommented T_w_z()
#				  - renamed T_{UH,ASM} to T_{UH,ASM}_shear to make things clear
#	Jan 12, 2023: - 

require "$ANTS/libvec.pl";
require "$ANTS/libfuns.pl";

#------------------------------------------------------------------------------
# VKE parameterization for epsilon
#
# NOTES:
#	- see Thurnherr et al. (GRL 2015)
#	- calculate eps from p0
#	- optional second argument allows free choice of parameterization constant
#	- default value is from paper, which is slightly lower than the current value
#	  used in [LADCP_VKE], which applies the parameterization only to spectra
#	  passing a few tests
#------------------------------------------------------------------------------

sub eps_VKE(@)
{
    my($p0,$c) =
        &antsFunUsage(-1,'.','eps_VKE(<p0[m^2/s^2/(rad/m)]> [c[0.021 [1/sqrt(s)]]])',@_);
	$c = 0.021 unless defined($c);
    return numberp($p0) ? ($p0 / $c) ** 2 : nan;
}

#------------------------------------------------------------------------------
# Spectral corrections for LADCP data
#
# NOTES:
#	- see Polzin et al. (JAOT 2002), Thurnherr (JAOT 2012)
#	- T HERE ARE RECIPROCALS OF T IN POLZIN AND THURNHERR!!!!
#	- to correct, multiply power densities (or power) with transfer functions defined below
#	- T_VI from Thurnherr applies to velocity, not shear! (error in paper)
#------------------------------------------------------------------------------

#----------------------------------------------------------------------
# 1. Corrections for individual data acquisition and processing steps
#----------------------------------------------------------------------

#------------------------------------------------------------------------------
# T_ravg(k,blen[,plen])
#	- correct for range averaging due to finite pulse and finite receive window
# 	- when called with 2 arguments, bin-length == pulse-length assumed
#------------------------------------------------------------------------------

sub T_ravg(@)
{
    my($k,$blen,$plen) =
        &antsFunUsage(-2,'ff','T_ravg(<vertical wavenumber[rad/s]> <bin-length[m]> [pulse-length[m]])',@_);
	$plen = $blen unless defined($plen);        
    return 1 / sinc($k*$blen/2/$PI)**2 / sinc($k*$plen/2/$PI)**2;
}

#-------------------------------------------------------------
# T_fdiff_UH(k,dz)
#	- supposedly corrects for first differencing (Polzin et al. 2002)
#	- however, as applied by Polzin, this corrects for a low-
#	  pass filter, whereas first differencing is clearly a
#	  high-pass filter
#	- the overall shear-method transfer functions of Polzin et al.
#	  and of Thurnherr are correct, but this particular correction
#	  does not what it is advertised to be doing?!
#-------------------------------------------------------------

sub T_fdiff_UH($$)
{
    my($k,$dz) =
        &antsFunUsage(2,'ff','T_fdiff_UH(<vertical wavenumber[rad/s]> <differencing interval[m]>)',@_);
    return 1 / sinc($k*$dz/2/$PI)**2;
}

#----------------------------------------------------------------------
# T_fdiff()
#	- correct for first differencing
#----------------------------------------------------------------------

sub T_fdiff($$)
{
    my($k,$dz) =
        &antsFunUsage(2,'ff','T_fdiff(<vertical wavenumber[rad/s]> <differencing interval[m]>)',@_);
    return sinc($k*$dz/2/$PI)**2;
}

#------------------------------------------------------------
# T_interpgrid(k,blen,dz)
#	- correct for CODAS gridding-with-interpolation algorithm
#	- ONLY USED IN UH SOFTWARE
#------------------------------------------------------------

sub T_interpgrid($$$)
{
    my($k,$blen,$dz) =
        &antsFunUsage(3,'fff','T_interpgrid(<vertical wavenumber[rad/s]> <bin length[m]> <grid resolution[m]>)',@_);
    return 1 / sinc($k*$blen/2/$PI)**4 / sinc($k*$dz/2/$PI)**2;
}

#-------------------------------------------------------------------------
# T_binavg(k,dz)
#	- correct for simple bin averaging
#	- Polzin et al. suggest to use blen instead of dz; this must be a typo
#-------------------------------------------------------------------------

sub T_binavg($$)
{
    my($k,$dz) =
        &antsFunUsage(2,'ff','T_binavg(<vertical wavenumber[rad/s]> <grid resolution[m]>)',@_);
    return 1 / sinc($k*$dz/2/$PI)**2;
}

#------------------------------------------------------------
# T_regrid(k,dz)
#	- correct for linear interpolation onto different grid
#	- verified with 1997 KN9710:
#		- oversampling:
#			- for oversampling factor of 4x and greater, this routine
#			  applies exactly
#			- for oversampling factor 2, blen should be reduced by 10%
#			- at factor 1, blen should be reduced by 100%
#		- undersampling:
#			- no correction should be applied
#------------------------------------------------------------

sub T_regrid($$)
{
    my($k,$blen) =
        &antsFunUsage(2,'ff','T_interpolate(<vertical wavenumber[rad/s]> <ADCP bin length [m]>',@_);
    return 1 / sinc($k*$blen/2/$PI)**2;
}

#--------------------------------------------------------------------------------
# T_tilt(k,d')
#	- d' is a length scale that depends on tilt stats and range max
#	- on d' == 0, T_tilt() == 1, i.e. the correction is disabled
#	- d' = dprime(range_max)
#			- is from a quadratic fit to three data points given by Polzin et al.
#			- see Thurnherr (J. Tech. 2012) for notes
#			- on range_max == 0, d' == 0, i.e. the correction is disabled
#--------------------------------------------------------------------------------

sub T_tilt($$)
{
    my($k,$dprime) =
        &antsFunUsage(2,'ff','T_tilt(<vertical wavenumber[rad/s]> <d-prime[m]>)',@_);
    return $dprime ? 1 / sinc($k*$dprime/2/$PI)**2 : 1;
}

sub dprime($)
{
	return $_[0] ? -1.2 + 0.0857 * $_[0] - 0.000136 * $_[0]**2 : 0;
} 

#======================================================================
# 2. Processing-Specific Corrections
#======================================================================

#----------------------------------------------------------------------
# T_UH(k,blen,dz,range_max)
#	- UH implementation of the shear method (WOCE standard)
#	- range_max == 0 disables tilt correction
#----------------------------------------------------------------------

sub T_UH_shear($$$$)
{
	my($k,$blen,$dz,$range_max) =
        &antsFunUsage(-3,'fff','T_UH(<vertical wavenumber[rad/s]> <ADCP bin size[m]> <shear grid resolution[m]> <range max[m]>)',@_);
	croak("T_UH($k,$blen,$dz,$range_max): bad parameters\n")
		unless ($k>=0 && $blen>0 && $dz>0 && $range_max>=0);				
    return T_ravg($k,$blen) * T_fdiff_UH($k,$blen) * T_interpgrid($k,$blen,$dz) * T_tilt($k,dprime($range_max));
}

#----------------------------------------------------------------------
# T_ASM_shear(k,blen,dz,range_max)
#	- re-implemented shear method with simple depth binning
#	- range_max == 0 disables tilt correction
#----------------------------------------------------------------------

sub T_ASM_shear($$$$)
{
	my($k,$blen,$dz,$range_max) =
        &antsFunUsage(-3,'fff','T_ASM(<vertical wavenumber[rad/s]> <ADCP bin size[m]> <shear grid resolution[m]> <range max[m]>)',@_);
	croak("T_ASM($k,$blen,$dz,$range_max): bad parameters\n")
		unless ($k>=0 && $blen>0 && $dz>0 && $range_max>=0);				
    return T_ravg($k,$blen) * T_fdiff_UH($k,$blen) * T_binavg($k,$dz) * T_tilt($k,dprime($range_max));
}

#------------------------------------------------------------
# T_VI(k,blen,preavg_dz,grid_dz,range_max)
# T_VI_alt(k,blen,preavg_dz,grid_dz,dprime)
#	- correction for velocity 
#	- velocity inversion method of Visbeck (J. Tech., 2002)
#	- only valid if pre-averaging into superensembles is used
#	- range_max == 0 disables tilt correction
#	- sel == nan disables pre-averaging correction
#------------------------------------------------------------

sub T_VI($$$$$)
{
	my($k,$blen,$sel,$dz,$range_max) =
        &antsFunUsage(-4,'ff.f','T_VI(<vertical wavenumber[rad/s]> <ADCP bin size[m]> <superensemble size[m]|nan> <shear grid resolution[m]> <range max[m]>)',@_);
	return T_VI_alt($k,$blen,$sel,$dz,dprime($range_max));        
}

sub T_VI_alt($$$$$)
{
	my($k,$blen,$sel,$dz,$dprime) =
        &antsFunUsage(-4,'ff.ff','T_VI_alt(<vertical wavenumber[rad/s]> <ADCP bin size[m]> <superensemble size[m]|nan> <shear grid resolution[m]> <tilt d-prime[m]>)',@_);
	croak("T_VI_alt($k,$blen,$sel,$dz,$range_max): bad parameters\n")
		unless ($k>=0 && $blen>0 && $sel ne '' && $dz>0 && $range_max>=0);				
	croak("$0: tilt-dprime outside range [0..$blen]\n")
		unless ($dprime>=0 && $dprime<=$blen);
    return ($sel>0) ? T_ravg($k,$blen) * T_binavg($k,$sel) * T_binavg($k,$dz) * T_tilt($k,$dprime)
    				: T_ravg($k,$blen) * T_binavg($k,$dz) * T_tilt($k,$dprime);
}

#----------------------------------------------------------------------
# T_w(k,blen,plen,dz,range_max)
#	- vertical-velocity method of Thurnherr (IEEE 2011)
#	- range_max == 0 disables tilt correction
#	- this is the expression that should be used to correct spectra
#	  of VKE (and is used by [LADCP_VKE])
#----------------------------------------------------------------------

{ my(@fc);
	sub T_w(@)
	{
		my($k,$blen,$plen,$dz,$range_max) =
			&antsFunUsage(-4,'ffff',
				'T_w([vertical wavenumber[rad/s]] <ADCP bin length[m]> <pulse length[m]> <output grid resolution[m]> <range max[m]>)',
				\@fc,'k',undef,undef,undef,@_);
		croak("T_w($k,$blen,$plen,$dz,$range_max): bad parameters\n")
			unless ($k>=0 && $blen>0 && $plen>0 && $dz>0 && $range_max>=0);				
		return T_ravg($k,$blen,$plen) * T_binavg($k,$dz) * T_tilt($k,dprime($range_max));
	}
}

#----------------------------------------------------------------------
# T_w_z(k,blen,plen,dz,range_max)
#	- vertical-velocity method of Thurnherr (IEEE 2011)
#	- first differencing of gridded shear to calculate dw/dz
#	- NB: grid-scale differentiation assumed
#	- output is independent of dz!
#	- range_max == 0 disables tilt correction
#----------------------------------------------------------------------

{ my(@fc);
	sub T_w_z(@)
	{
		my($k,$blen,$plen,$dz,$range_max) =
			&antsFunUsage(-4,'ffff',
				'T_w_z([vertical wavenumber[rad/s]] <ADCP bin size[m]> <pulse length[m]> <output grid resolution[m]> <range max[m]>)',
				\@fc,'k',undef,undef,undef,@_);
		croak("T_w_z($k,$blen,$plen,$dz,$range_max): bad parameters\n")
			unless ($k>=0 && $blen>0 && $plen>0 && $dz>0 && $range_max>=0);				
		return T_w($k,$blen,$plen,$dz,$range_max) * T_fdiff($k,$dz);
#		return T_ravg($k,$blen,$plen) * T_tilt($k,dprime($range_max));		# same without requiring $dz!
	}
}

1;
