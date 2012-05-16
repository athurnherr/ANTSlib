#======================================================================
#                    L I B N O D C . P L 
#                    doc: Mon Aug 28 11:07:47 2000
#                    dlm: Sun Jul  2 00:16:26 2006
#                    (c) 2000 A.M. Thurnherr
#                    uE-Info: 117 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Aug 28, 2000: - created
#	Sep 05, 2000: - allow spaces instead of 0es in lat/lon to accomodate
#					for Talley's OCEANUS 24S files
#	Oct 16, 2000: - added &DD[D]MMSSh2d()
#	Feb 28, 2001: - changed &depth to &obs_depth to remove clash with
#					[libEOS83]
#	Aug  1, 2001: - BUG: obs() could not handle Reid and Mantyla -ve values
#					correctly (such as -80 with precision 3!)
#   Jul  1, 2006: - Version 3.3 [HISTORY]

require "$ANTS/libconv.pl";

#----------------------------------------------------------------------
# Lat/Lon
#----------------------------------------------------------------------

sub DDMMXh2d(@)			# NODC SD2 header info
{
	my($DDMMX,$H) = &antsFunUsage(2,"51","DDMMX H",@_);
	$DDMMX =~ s/ /0/g;
	return &dmh2d(substr($DDMMX,0,2),
				  substr($DDMMX,2,2) . "." . substr($DDMMX,4,1),
				  $H);
}
		
sub DDDMMXh2d(@)		# NODC SD2 header info
{
	my($DDDMMX,$H) = &antsFunUsage(2,"61","DDDMMX H",@_);
	$DDDMMX =~ s/ /0/g;
	return &dmh2d(substr($DDDMMX,0,3),
				  substr($DDDMMX,3,2) . "." . substr($DDDMMX,5,1),
				  $H);
}
		
sub DDMMSSh2d(@)		# NODC detailed inventory info
{
	my($DDMMSS,$H) = &antsFunUsage(2,"61","DDMMSS H",@_);
	$DDMMSS =~ s/ /0/g;
	return &dmsh2d(substr($DDMMSS,0,2),
				   substr($DDMMSS,2,2),
				   substr($DDMMSS,4,2),
				   $H);
}
		
sub DDDMMSSh2d(@)		# NODC detailed inventory info
{
	my($DDDMMSS,$H) = &antsFunUsage(2,"71","DDDMMSS H",@_);
	$DDDMMSS =~ s/ /0/g;
	return &dmsh2d(substr($DDDMMSS,0,3),
				   substr($DDDMMSS,3,2),
				   substr($DDDMMSS,5,2),
				   $H);
}
		
#----------------------------------------------------------------------
# date/time
#----------------------------------------------------------------------

sub YYMMDD(@)		# 6 digit date
{
	my($YYMMDD) = &antsFunUsage(1,"6","YYMMDD",@_);
	return substr($YYMMDD,2,2) . "/" .
		   substr($YYMMDD,4,2) . "/19" . substr($YYMMDD,0,2);
}

sub HHt(@)			# 3 digits (hours to tenths)
{
	my($HHt) = &antsFunUsage(1,"3","HHt",@_);
	return sprintf("%02d:%02d",substr($HHt,0,2),substr($HHt,2,1)*6);
}

#----------------------------------------------------------------------
# depth
#----------------------------------------------------------------------

sub obs_depth(@)									# good depth only
{
	my($obs,$quality,$t_flag) =
		&antsFunUsage(3,"c..","obs quality t_flag",@_);
	return (isnan($quality) && ($t_flag ne 'T'))
		? $obs : nan;
}

sub wire_out(@)										# wire-out
{
	my($obs,$quality,$t_flag) =
		&antsFunUsage(3,"c..","obs quality t_flag",@_);
	return (($quality == 6) && ($t_flag ne 'T'))
		? $obs : nan;
}

sub t_depth(@)										# good thermometric depth
{
	my($obs,$quality,$t_flag) =
		&antsFunUsage(3,"c..","obs quality t_flag",@_);
	return (isnan($quality) && ($t_flag eq 'T'))
		? $obs : nan;
}

#----------------------------------------------------------------------
# temp, salin, O2, ...
#----------------------------------------------------------------------

sub obs(@)
{
	my($obs,$prec,$qual) =
		&antsFunUsage(3,".1.","obs prec qual",@_);
	return nan if isnan($obs);
	return nan if isnan($qual);						# spc->nan==OK

	my($fac) = 1;									# Reid and Mantyla weird fmt
	if ($obs =~ /^-/) {
		$fac = -1;
		$obs = $';
	}
	$obs = sprintf("%0${prec}d",$obs);				# pre-pad missing 0es
	substr($obs,-$prec,0) = ".";					# PERL is wonderful...
	return $fac * $obs;
}

1;
