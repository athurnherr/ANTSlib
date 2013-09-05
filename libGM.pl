#======================================================================
#                    L I B G M . P L 
#                    doc: Sun Feb 20 14:43:47 2011
#                    dlm: Sat Apr 20 20:05:51 2013
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 62 0 NIL 0 0 72 2 2 4 NIL ofnI
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
# Version: GM79?
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
#======================================================================

sub m($$)	# vertical wavenumber as a function of mode number & stratification params
{
	my($j,$N,$omega) = @_;

	return defined($omega) && ($omega <= $GM_N0)
		   ? $pi / $GM_b * sqrt(($N**2 - $omega**2) / ($GM_N0**2 - $omega**2)) * $j
		   : $pi * $j * $N / ($GM_b * $GM_N0);			# valid, except in vicinity of buoyancy turning frequency (p. 285)
}

sub B($)											# structure function (omega dependence)
{													# NB: f must be defined
	my($omega) = @_;
	croak("coriolis parameter not defined\n")
		unless defined($f);
	return 2 / $pi * $f / $omega / sqrt($omega**2 - $f**2);
}


sub Sw($$$$)
{
	my($omega,$m,$lat,$N) = &antsFunUsage(4,'fff','<frequency[1/s]> <vertical wavenumber[rad/m]> <lat[deg]> <N[rad/s]>',@_);

	local($f) = abs(&f($lat));
	$omega += $PRACTICALLY_ZERO if ($omega < $f);
	$omega -= $PRACTICALLY_ZERO if ($omega > $N);
	return nan if ($omega < $f || $omega > $N);

	my($GM_b) = 1300; #m								# pycnocline lengthscale

	my($mstar) = &m($GM_jstar,$N,$omega);

	return $GM_E0 * $GM_b * 2 * $f**2/$omega**2/B($omega) * $GM_jstar / ($m+$mstar)**2;
}

#----------------------------------------------------------------------
# GM76, as per Gregg and Kunze (JGR 1991)
#	- beta is vertical wavenumber (m above)
#----------------------------------------------------------------------

sub Su($$)
{
	my($beta,$N) = @_;

	my($beta_star) = &m($GM_jstar,$N);				# A3
	return 3*$GM_E0*$GM_b**3*$GM_N0**2 / (2*$GM_jstar*$pi) / (1+$beta/$beta_star)**2;	# A2
}

sub Su_z($$)
{
	my($beta,$N) = &antsFunUsage(2,'ff','<vertical wavenumber[rad/m]> <N[rad/s]>',@_);
	return $beta**2 * &Su($beta,$N);
}

1;
