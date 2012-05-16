#======================================================================
#                    L I B G M . P L 
#                    doc: Sun Feb 20 14:43:47 2011
#                    dlm: Sun Apr  1 11:29:53 2012
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 53 1 NIL 0 0 72 2 2 4 NIL ofnI
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

require "$ANTS/libEOS83.pl";

my($pi) = 3.14159265358979;

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

	my($b) = 1300; #m                               # stratification e-folding scale (Munk 81)
	my($N0) = 5.2e-3; #rad/s                        # extrapolated to surface value (Munk 81)

#	print(STDERR "omega = $omega, N = $N\n");
	return defined($omega)
		   ? $pi / $b * sqrt(($N**2 - $omega**2) / ($N0**2 - $omega**2)) * $j
		   : $pi * $j * $N / ($b * $N0);			# valid, except in vicinity of buoyancy turning frequency (p. 285)
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
	my($omega,$m,$lat,$N) = &antsFunUsage(4,'fff','<frequency[1/s]> <vertical wavenumber[1/m]> <lat[deg]> <N[rad/s]>',@_);

	local($f) = abs(&f($lat));
	return nan if ($omega < $f || $omega > $N);

	my($E0) = 6.3e-5;								# dimensionless spectral level
	my($j_star) = 3;								# peak mode number
	my($b) = 1300; #m								# pycnocline lengthscale

	my($mstar) = &m($j_star,$N,$omega);

	return $E0 * $b * 2 * $f**2/$omega**2/B($omega) * $j_star / ($m+$mstar)**2;
}

1;
