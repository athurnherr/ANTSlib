#======================================================================
#                    L I B W O C E . P L 
#                    doc: Mon Aug 28 11:07:47 2000
#                    dlm: Thu Dec 10 13:43:44 2009
#                    (c) 2000 A.M. Thurnherr
#                    uE-Info: 31 33 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Sep 04, 2000: - created from [libNODC.pl]
#	Sep 19, 2000: - added &q_OK()
#	Jan  2, 2002: - added optional length argument to &q_OK()
#				  - allowed NaN observations in &q_OK()
#	Aug 14, 2002: - added &csv_q_OK()
#	Jun 19, 2004: - made Y2K compatible
#	Apr  4, 2006: - added flt_qual(), flt_src()
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#	Dec 10, 2009: - adapted to netCDF processing

require "$ANTS/libconv.pl";		# imply lat/lon conversions

#----------------------------------------------------------------------
# date/time
#----------------------------------------------------------------------

sub YYYYMMDD(@)		# 8 digit date
{
	my($YYYYMMDD) = &antsFunUsage(1,"8","YYYYMMDD",@_);
	return substr($YYYYMMDD,4,2) . '/' .
		   substr($YYYYMMDD,6,2) . '/' .
		   substr($YYYYMMDD,0,4);
}

sub HHMM(@)			# 4 digits
{
	$_[0] = sprintf('%04d',$_[0]) if (@_ > 0);		# pre-pad with 0es
	my($HHMM) = &antsFunUsage(1,"4","HHMM",@_);
	return substr($HHMM,0,2) . ":" . substr($HHMM,2,2);
}

#----------------------------------------------------------------------
# CTD quality flags
#----------------------------------------------------------------------

sub q_OK(@)			# exchange-format version (single flags)
{
	return $_[1] == 2 ? $_[0] : nan;
}

#----------------------------------------------------------------------
# Float Quality/Source Flags [/Data/Floats/DBE/WFDAC/WDBE/quality.doc]
#	- 2-digit decimal number
#	- 10s: quality (0-9, with 9 being best)
#	-  1s: source:
#			0	missing
#			1	interpolated 	(backward diff for u/v)
#			2					(forward diff for u/v)
#			3	splined
#			4	manually edited
#			5	filtered/averaged
#			9	original value
#	- should accept source values >= 4
#----------------------------------------------------------------------

sub flt_qual($)
{ return int($_[0] / 10); }

sub flt_src($)
{ return $_[0] % 10; }

1;
