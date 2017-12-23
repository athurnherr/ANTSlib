#======================================================================
#                    L I B A L E C . P L 
#                    doc: Wed Jun  1 20:38:19 2011
#                    dlm: Mon Dec 18 10:29:08 2017
#                    (c) 2011 A.M. Thurnherr
#                    uE-Info: 71 31 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov 15, 2017: - created
#	Dec 18, 2017: - turned vel output into m/s

require "$ANTS/libvec.pl";
require "$ANTS/libfuns.pl";

#----------------------------------------------------------------------
# User Routines
#	- from manual
#	- also transform velocities to m/s
#----------------------------------------------------------------------

sub ALEC_u($$$$$$$)
{
    my($vx,$vy,$alpha,$compA,$compB,$beta,$magdec) =
		&antsFunUsage(7,'fffffff','<vx[cm/s]> <vy[cm/s]> <alpha> <compA> <compB> <beta>',@_);

	my($c) = ALEC_vel_speed($vx,$vy,$alpha);
	my($d) = ALEC_vel_dir($compA,$compB,$beta,$vx,$vy);
	return vel_u($c,$d-$magdec);
}

sub ALEC_v($$$$$$$)
{
    my($vx,$vy,$alpha,$compA,$compB,$beta,$magdec) =
		&antsFunUsage(7,'fffffff','<vx[cm/s]> <vy[cm/s]> <alpha> <compA> <compB> <beta>',@_);

	my($c) = ALEC_vel_speed($vx,$vy,$alpha);
	my($d) = ALEC_vel_dir($compA,$compB,$beta,$vx,$vy);
	return vel_v($c,$d-$magdec);
}

#------------------------------------------------------------------------------
# Routines mostly as per ALEC manual
#		- weird atan corrections in manual cause data discontinuities
#			=> removed
#		- routines verified with first PITTA time series
# 	ALEC_vel_speed(vx,vy,alpha)
#	ALEC_heading(compA,compB,beta)
# 	ALEC_vel_instrument_dir(vx,vy)
# 	ALEC_vel_dir(compA,compB,beta,vx,vy)
#------------------------------------------------------------------------------

sub ALEC_vel_speed(@)
{
    my($vx,$vy,$alpha) = &antsFunUsage(3,'fff','<vx[cm/s]> <vy[cm/s]> <alpha>',@_);
	my($ssq) = ($vx**2 + $vy**2);
	return inf unless ($ssq > 1e-6);
	return (1 + $alpha*(4*$vx**2*$vy**2)/($ssq**2)) * sqrt($ssq) / 100;
}

sub ALEC_heading(@)
{
    my($compA,$compB,$beta) =
        &antsFunUsage(3,'fff','<compass output A> <compass output B> <beta>',@_);
    return angle_pos(deg(atan2($compA,$compB)) + $beta);
}

sub ALEC_vel_instrument_dir($$)
{
    my($vx,$vy) = &antsFunUsage(2,'ff','<vx[cm/s]> <vy[cm/s]>',@_);
	return deg(atan2($vx,$vy));
}

sub ALEC_vel_dir($$$$$)
{
    my($compA,$compB,$beta,$vx,$vy) =
        &antsFunUsage(5,'fffff','<compass output A> <compass output B> <beta> <vx[cm/s]> <vy[cm/s]>',@_);
    return ALEC_heading($compA,$compB,$beta) + ALEC_vel_instrument_dir($vx,$vy);
}

1;
