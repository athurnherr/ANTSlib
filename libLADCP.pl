#======================================================================
#                    L I B L A D C P . P L 
#                    doc: Wed Jun  1 20:38:19 2011
#                    dlm: Wed Jan 18 18:46:33 2012
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 103 19 NIL 0 0 72 2 2 4 NIL ofnI
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

require "$ANTS/libvec.pl";
require "$ANTS/libfuns.pl";

#----------------------------------------------------------------------
# Polzin et al., JAOT 2002 LADCP shear corrections
#----------------------------------------------------------------------

# NOTES:
#	- apply to downcast data only

#----------------------------------------------------------------------
# individual corrections
#----------------------------------------------------------------------

# NB: Dzb = (Dzt == Dzr) assumed

sub T_ravg($$)
{
    my($kz,$Dzb) =
        &antsFunUsage(2,'ff','<vertical wavenumber[rad/s]> <pulse/bin-length[m]>',@_);
    return 1 / sinc($kz*$Dzb/2/$PI)**4;
}


sub T_fdiff($$)
{
    my($kz,$Dzd) =
        &antsFunUsage(2,'ff','<vertical wavenumber[rad/s]> <differencing interval[m]>',@_);
    return 1 / sinc($kz*$Dzd/2/$PI)**2;
}


sub T_interp($$$)
{
    my($kz,$Dzb,$Dzg) =
        &antsFunUsage(3,'fff','<vertical wavenumber[rad/s]> <bin length[m]> <grid resolution[m]>',@_);
    return 1 / sinc($kz*$Dzb/2/$PI)**4 / sinc($kz*$Dzg/2/$PI)**2;
}


# NB: Polzin et al claim that Dz should be ADCP bin size, which does not seem to make sense
sub T_binavg($$)
{
    my($kz,$Dzg) =
        &antsFunUsage(2,'ff','<vertical wavenumber[rad/s]> <grid resolution[m]>',@_);
    return 1 / sinc($kz*$Dzg/2/$PI)**2;
}


sub T_tilt($$)
{
    my($kz,$dprime) =
        &antsFunUsage(2,'ff','<vertical wavenumber[rad/s]> <d-prime[m]>',@_);
    return 1 / sinc($kz*$dprime/2/$PI)**2;
}

#----------------------------------------------------------------------
# convenient combinations
#----------------------------------------------------------------------

sub LADCP_tilt_dprime($)
{
	return -1.2 + 0.0857 * $_[0] - 0.000136 * $_[0]**2;
} 

sub T_UH($$$$)
{
	my($kz,$blen,$grez,$maxrange) =
        &antsFunUsage(4,'ffff','<vertical wavenumber[rad/s]> <ADCP bin size[m]> <shear grid resolution[m]> <max range[m]>',@_);
    return T_ravg($kz,$blen) * T_fdiff($kz,$blen) * T_interp($kz,$blen,$grez) * T_tilt($kz,LADCP_tilt_dprime($maxrange));
}

sub T_SM($$$$)
{
	my($kz,$blen,$grez,$maxrange) =
        &antsFunUsage(4,'ffff','<vertical wavenumber[rad/s]> <ADCP bin size[m]> <shear grid resolution[m]> <max range[m]>',@_);
    return T_ravg($kz,$blen) * T_fdiff($kz,$blen) * T_binavg($kz,$grez) * T_tilt($kz,LADCP_tilt_dprime($maxrange));
}

sub T_VI($$$$$)
{
	my($kz,$blen,$sel,$grez,$maxrange) =
        &antsFunUsage(5,'ff.ff','<vertical wavenumber[rad/s]> <ADCP bin size[m]> <superensemble size[m]|nan> <shear grid resolution[m]> <max range[m]>',@_);
	return T_VI_alt($kz,$blen,$sel,$grez,LADCP_tilt_dprime($maxrange));        
}

sub T_VI_alt($$$$$)
{
	my($kz,$blen,$sel,$grez,$dprime) =
        &antsFunUsage(5,'ff.ff','<vertical wavenumber[rad/s]> <ADCP bin size[m]> <superensemble size[m]|nan> <shear grid resolution[m]> <tilt d-prime[m]>',@_);
	croak("$0: tilt-dprime outside range [0..$blen]\n")
		unless ($dprime>=0 && $dprime<=$blen);
    return ($sel>0) ? T_ravg($kz,$blen) * T_binavg($kz,$sel) * T_binavg($kz,$grez) * T_tilt($kz,$dprime)
    				: T_ravg($kz,$blen) * T_binavg($kz,$grez) * T_tilt($kz,$dprime);
}

1;
