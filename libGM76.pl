#======================================================================
#                    L I B G M 7 6 . P L 
#                    doc: Sun Feb 20 14:43:47 2011
#                    dlm: Sat Feb  2 02:33:11 2019
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 144 43 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Feb 20, 2011: - created
#	Feb 28, 2011: - cosmetics
#	Mar 28, 2012: - BUG: N had been ignored (but only affects vertical
#						 wavelengths > 1000m in any was significantly
#				  - changed from Munk eqn 9.23b to 9.23a, which also
#					affects only long wavelengths
#				  - return nan for omega outside internal-wave band
#	Mar 29, 2012: - re-wrote using definition of B(omega) from Munk (1981)
#	Aug 23, 2012: - cosmetics?
#	Sep  7, 2012: - made N0, E0, b, jstar global
#	Dec 28, 2012: - added allowance for small roundoff error to Sw()
#	Oct  6, 2014: - made omega optional in Sw()
#	Nov 18, 2014: - made b & jstar mandatory for Sw()
#	Feb  2, 2019: - renamed from libGM.pl to libGM76.pl
#				  - replaced beta with m
#				  - replaced old code based on Gregg + Kunze formalism with
#					expressions from Thurnherr et al. (GRL 2015)
#				  - added GM_strain
#				  - BUG: Sw usage message had wrong parameter order
#				  - renamed Sw => GM_VKE; Su_z => GM_shear


require "$ANTS/libEOS83.pl";

my($pi) = 3.14159265358979;

#======================================================================
# Global Constants
#======================================================================

$GM_N0 = 5.24e-3;   # rad/s			# reference stratification (from Gregg + Kunze, 1991)
$GM_E0 = 6.3e-5;	# dimensionless # spectral level (Munk 1981)
$GM_b  = 1300;		# m				# pycnocline e-folding scale
$GM_jstar = 3;		# dimless		# peak mode number

#======================================================================
# Vertical velocity spectral density
#
# Units: K.E. per frequency per wavenumber [m^2/s^2*1/s*1/m = m^3/s]
# Version: GM76
#
# E. Kunze (email, Feb 2011): The GM vertical velocity w spectrum is described by
#
# S[w](omega, k_z) = PI*E_0*b*{f*sqrt(omega^2-f^2)/omega}*{j*/(k_z + k_z*)^2}
#
# where E_0 = 6.3 x 10^-5 is the dimensionless spectral level, b = 1300 m is
# the pycnocline lengthscale, j* = 3 the peak mode number and k_z* the
# corresponding vertical wavenumber.  The flat log-log spectrum implies w is
# dominated by near-N frequencies (where we know very little though Yves
# Desaubies wrote some papers back in the late 70's/early 80's about the
# near-N peak) and low modes.  The rms w = 0.6 cm/s, right near your noise
# level.  Interestingly, the only N dependence is in m and m*.  As far
# as I know, little is known about its intermittency compared to horizontal
# velocity.  Since w WKB-scales inversely with N, the largest signals should
# be in the abyss where you therefore likely have the best chance of
# measuring it.
#
# E. Kunze (email, Sep 19, 2013):
#
# S[w](omega, m) = PI*E0*b*[f*sqrt(omega^2-f^2)/omega]*[jstar/(m+mstar)^2] with
#
# S[w](m) = PI*E0*b*N*f*[jstar/(m+mstar)^2]
#
# where the nondimensional spectral energy level E0 = 6.3e-5, stratification
# lengthscale b = 1500 m, jstar = 3, mstar = jstar*PI*N/b/N0, and N0 =
# 5.3e-3 rad/s.
#
# NOTES:
#	- b=1500m is a likely typo, as Gregg & Kunze (1991) have b=1300m
#	- k_z == m
#    
#======================================================================

sub m($$)	# vertical wavenumber as a function of mode number & stratification params
{
	my($j,$N,$omega) = @_;

	return defined($omega) && ($omega <= $GM_N0)
		   ? $pi / $GM_b * sqrt(($N**2 - $omega**2) / ($GM_N0**2 - $omega**2)) * $j
		   : $pi * $j * $N / ($GM_b * $GM_N0);		# valid, except in vicinity of buoyancy turning frequency (Munk 1981, p.285)
}

sub B($)											# structure function (omega dependence)
{													# NB: f must be defined
	my($omega) = @_;
	croak("coriolis parameter not defined\n")
		unless defined($f);
	return 2 / $pi * $f / $omega / sqrt($omega**2 - $f**2);
}

sub GM_VKE(@)
{
	my($omega,$m,$lat,$b,$jstar,$N) =
		&antsFunUsage(-5,'fff','[frequency[1/s]] <vertical wavenumber[rad/m]> <lat[deg]> <b[m]> <j*> <N[rad/s]>',@_);

	if (defined($N)) {									# Sw(omega,m)
		local($f) = abs(&f($lat));
		$omega += $PRACTICALLY_ZERO if ($omega < $f);
		$omega -= $PRACTICALLY_ZERO if ($omega > $N);
		return nan if ($omega < $f || $omega > $N);
		my($mstar) = &m($jstar,$N,$omega);
		return $GM_E0 * $b * 2 * $f**2/$omega**2/B($omega) * $jstar / ($m+$mstar)**2;
	} else {											# Sw(m), i.e. integrated over all omega; as in Thurnherr et al., GRL 2015
		$N = $lat;										# shift arguments to account for missing omega
		$lat = $m;
		local($f) = abs(&f($lat));
		$m = $omega;
		undef($omega);
		my($mstar) = &m($jstar,$N);
		return $pi * $GM_E0 * $b * $N * $f * $jstar / ($m+$mstar)**2;
	}
}

#----------------------------------------------------------------------
# Shear and Strain m-spectra (i.e. integrated over f)
#	- spectral density
#	- from Thurnherr et al. (GRL 2015)
#----------------------------------------------------------------------

sub GM_shear(@)
{
	my($m,$lat,$b,$jstar,$N) =
		&antsFunUsage(5,'fffff','<vertical wavenumber[rad/m]> <lat[deg]> <b[m]> <j*> <N[rad/s]>',@_);
	local($f) = abs(&f($lat));
	my($mstar) = &m($jstar,$N);
	return 3 * $pi/2 * $GM_E0 * $b * $jstar * $m**2 / ($m+$mstar)**2;
}

sub GM_strain(@)
{
	my($m,$lat,$b,$jstar,$N) =
		&antsFunUsage(5,'fffff','<vertical wavenumber[rad/m]> <lat[deg]> <b[m]> <j*> <N[rad/s]>',@_);
	local($f) = abs(&f($lat));
	my($mstar) = &m($jstar,$N);
	return $pi/2 * $GM_E0 * $b * $jstar * $m**2 / ($m+$mstar)**2;
}

##----------------------------------------------------------------------
## GM76, as per Gregg and Kunze (JGR 1991)
##	- beta is vertical wavenumber
##----------------------------------------------------------------------
#
#sub Su($$)
#{
#	my($beta,$N) = @_;
#
#	my($beta_star) = &m($GM_jstar,$N);				# A3
#	return 3*$GM_E0*$GM_b**3*$GM_N0**2 / (2*$GM_jstar*$pi) / (1+$beta/$beta_star)**2;	# A2
#}
#
#sub Su_z($$)
#{
#	my($beta,$N) = &antsFunUsage(2,'ff','<vertical wavenumber[rad/m]> <N[rad/s]>',@_);
#	return $beta**2 * &Su($beta,$N);
#}

1;
