#======================================================================
#                    L I B G H P . P L 
#                    doc: Fri Sep  7 09:56:08 2012
#                    dlm: Wed Aug 11 13:12:52 2021
#                    (c) 2012 A.M. Thurnherr
#                    uE-Info: 38 0 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Sep  7, 2012: - created
#	Oct 22, 2012: - cosmetics
#	Jul 14, 2021: - BUG: adapted to new libGM name
#	Aug 11, 2021: - modified j() to handle N<f

require "$ANTS/libfuns.pl";		# arccosh
require "$ANTS/libGM76.pl";		# GM_N0

#----------------------------------------------------------------------------
# h(R_omega)	correction factor for different shear/strain (R_omega) ratios
#	- this version from Kunze et al. (2006)
#	- R_omega:
#		= (N^2-omega^2)/N^2 (omega^2+f^2)/(omega^2-f^2)	Polzin et al. 1995
#		= (omega^2+f^2)/(omega^2-f^2)					Kunze et al. 2006
#		- the Kunze et al formulation is presumably an approximation valid for
#		  omega<<N
#----------------------------------------------------------------------------

sub h1($)
{
	my($R_omega) = @_;
	return 3*($R_omega+1) / (2*sqrt(2)*$R_omega*sqrt($R_omega-1));
}

sub h2($)
{
	my($R_omega) = @_;
	return 1/(6*sqrt(2)) * $R_omega*($R_omega+1) / sqrt($R_omega-1);
}

#----------------------------------------------------------------------------
# j(f,N)	correction factor for latitude
#	- this version from Kunze et al. (2006)
#	- if N<f, N/f = 1 assumed
#----------------------------------------------------------------------------

sub j(@)
{
	my($f,$N) = @_;

	$f = abs($f);
	return 0 if ($f < 1e-6);

	my($f30) = &f(30);

	$N = $GM_N0 unless defined($N);
	$N = $f unless ($N > $f);

	return $f*acosh($N/$f) / ($f30*acosh($GM_N0/$f30));
}

1;
