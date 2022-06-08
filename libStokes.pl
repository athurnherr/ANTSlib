#======================================================================
#                    L I B S T O K E S . P L 
#                    doc: Tue Feb 15 12:41:27 2022
#                    dlm: Tue Feb 15 12:55:44 2022
#                    (c) 2022 A.M. Thurnherr
#                    uE-Info: 30 2 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Feb 15, 2022: - created

#----------------------------------------------------------------------
# Stokes Settling Velocity
#----------------------------------------------------------------------

sub Stv(@)
{
	my($rho_p,$r_p,$g,$rho_f,$mu_f) = @_;

	$g 	   = 9.81 unless defined($g);					# acceleration due to gravity
	$rho_f = 1000 unless defined($rho_f);				# fluid density
	$mu_f  = 1e-3 unless defined($mu_f);				# dynamic viscosity (order of magnitude)

	croak("Usage: Stv(rho_p,r_p[,g[,rho_f[,mu_f]]]\n")
		unless numbersp($rho_p,$r_p,$g,$rho_f,$mu_f);

	return 2/9 * ($rho_p - $rho_f)/$mu_f * $g * $r_p**2;
}

1;
