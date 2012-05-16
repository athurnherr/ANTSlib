#======================================================================
#                    L I B G A M M A . P L 
#                    doc: Mon Mar  8 11:46:36 1999
#                    dlm: Tue Jan  2 11:27:11 2001
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 17 40 NIL 0 0 72 0 2 4 ofnI
#======================================================================

# HISTORY:
#	Sep 25, 2000: - finished implementation
#	Jan 02, 2001: - updated documentation (here)

# NOTES:
# 	- gamma library stub to allow -L option
# 	- requires the perl interface of the (fortran library) gamma.a 
#	  [/usr/local/src/gamma/perl-interface]
#	- main use of this library: [gamma_n]

# SYNOPSIS:
#	$gamma::temp_scale = &antsRequireParam(temp_scale);
#		MUST DO THIS 1ST
#	&gamma::gamma_n(S,T,P,lon,lat[,dg_lo,dg_hi])
#		[$|@]S			salinity
#		[$|@]T			temperature (scale in $gamma::temp_scale)
#		[$|@]P			pressure
#		$lat			latitude
#		$lon			longitude
#		[$|\$|\@]dg_lo	low end of error range
#		[$|\$|\@]dg_lo	high end of error range
#	&gamma::gamma_n_lol(buf,S_f,T_f,P_f,gam_f,lon,lat[,dg_lo_f,dg_hi_f])
#		@buf			LoL containing columns for S,T,P,gamma[,dg_lo,dg_hi]
#		$S_f			salinity field
#		$T_f			temperature field
#		$P_f			pressure field
#		$lat			latitude
#		$lon			longitude
#		$dg_lo_f		low end of error range (field number)
#		$dg_lo_f		high end of error range (field number)

use gamma;

1;
