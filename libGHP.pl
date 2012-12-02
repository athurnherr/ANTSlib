#======================================================================
#                    L I B G H P . P L 
#                    doc: Fri Sep  7 09:56:08 2012
#                    dlm: Mon Oct 22 13:10:47 2012
#                    (c) 2012 A.M. Thurnherr
#                    uE-Info: 11 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Sep  7, 2012: - created
#	Oct 22, 2012: - cosmetics

require "$ANTS/libfuns.pl";		# arccosh
require "$ANTS/libGM.pl";		# GM_N0

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

#----------------------------------------------------------------------------
# j(f,N)	correction factor for latitude
#	- this version from Kunze et al. (2006)
#----------------------------------------------------------------------------

sub j(@)
{
	my($f,$N) = @_;
	return 0 if ($f == 0);
	$N = $GM_N0 unless defined($N);
	my($f30) = &f(30);
	return $f*acosh($N/$f) / ($f30*acosh($GM_N0/$f30));
}

1;
