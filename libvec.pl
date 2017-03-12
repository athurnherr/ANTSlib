#======================================================================
#                    L I B V E C . P L 
#                    doc: Sat Mar 20 12:50:32 1999
#                    dlm: Sun Aug  7 22:06:57 2016
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 137 37 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Mar 20, 1999: - created for ANTS_2.1 (no more c-code)
#	May 27, 1999: - added polar/cartesian conversions
#	Sep 18, 1999: - argument typechecking
#	Dec 10, 1999: - vel_u(), vel_v(), vel_dir(), vel_mag()
#	Mar 07, 2000: - proj(), deg(), rad()
#	Apr 18, 2002: - area()
#	Jan  6, 2003: - changed dist() output to meters
#	Jan 16, 2003: - renamed vel_vel() to vel_speed()
#	Sep  3, 2003: - dir_bias()
#	May 13, 2004: - BUG: had fogotten to adapt area() to new dist()
#	May 21, 2004: - forced zero distance on &dist() if lat/lon does
#				    not change (avoid roundoff error)
#	Jun 22, 2004: - added GMTdeg(), dir()
#	Nov 11, 2004: - BUG: roundoff test in dist() was done before
#					     conversion to numbers
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#   Jul 24, 2006: - modified to use equal()
#	Nov 16, 2006: - added degmin()
#	Dec 19, 2007: - addapted vel_speed(), vel_dir() to new &antsFunUsage()
#				  - same routines now return nan on nan input
#	Jan 15, 2007: - BUG: vel_dir() was broken
#	Jun 14, 2009: - added p_vel()
#	Nov  5, 2009: - added angle(); vel_bias() => angle_diff()
#	Apr 22, 2010: - added angle_ts()
#	Jun  5, 2012: - added &closestPointOnStraightLine()
#	Jun 11, 2012: - addeed $t output to &closestPointOnStraightLine()
#	Nov 27, 2013: - added &angle_pos(), mag_heading()
#	Mar  3, 2014: - made deg(), rad() handle nans
#	Mar  4, 2014: - made some angle funs handle nans
#	Jul 29, 2016: - BUG: mag_heading was inconsistent with ADCP headings
#						 (previous version only used for 2014 CLIVAR P06
#						 processing with IMP data with confused coord
#						 system)
#	Aug  7, 2016: - made vel_u and vel_v deal with nans

require "$ANTS/libPOSIX.pl";	# acos()

#----------------------------------------------------------------------
# &rad()							calc radians
# &deg()							calc degrees
#----------------------------------------------------------------------

$PI = 3.14159265358979;

sub rad(@)
{
	my($d) = &antsFunUsage(1,".","<deg>",@_);
	return numberp($d) ? $d/180 * $PI : nan;
}

sub deg(@)
{
	my($r) = &antsFunUsage(1,".","<rad>",@_);
	return numberp($r) ? $r/$PI * 180 : nan;
}
	

#----------------------------------------------------------------------
# &proj(from_x,from_y,onto_unit_x,onto_unit_y)
#									project vector onto another
#----------------------------------------------------------------------

# to transform CM velocity components u/v to along/across mean l/c:
#   - mean dir d = &vel_dir(<u>,<v>); with <.> indicating ensemble avg
#	- l = proj(u,v,sin(rad(d)),cos(rad(d))); NEW: l = p_vel(d[,u,v])
#	- c = -proj(u,v,-cos(rad(d)),sin(rad(d)));

sub proj(@)
{
	my($fx,$fy,$oux,$ouy) =
		&antsFunUsage(4,"ffff","<from_x> <from_y> " .
							   "<onto_unit_x> <onto_unit_y>",@_);
	return $fx*$oux + $fy*$ouy;
}

{ my(@fc);
	sub p_vel(@)
	{
		my($u,$v,$d) = &antsFunUsage(3,'..f','[u, v,] dir',\@fc,'u','v',undef,@_);
		return nan unless numbersp($d,$u,$v);
		return proj($u,$v,sin(rad($d)),cos(rad($d)));
	}
}

		
#----------------------------------------------------------------------
# &polar_r(x,y),&vel_vel(u,v)		calc polar radius, velocity
# &polar_phi(x,y),&vel_dir(u,v)		calc polar degrees cclockwise from
#									horiz (phi) OR clockwise from N (dir)
# &cartesian_x(r,phi),&vel_u(m,dir)	calc x and u from polar coords
# &cartesian_y(r,phi),&vel_v(m,dir)	calc y and v from polar coords
#----------------------------------------------------------------------

sub polar_r(@)
{
	my($x,$y) = &antsFunUsage(2,"ff","<x> <y>",@_);
	return sqrt($x*$x+$y*$y);
}

{ my(@fc);
	sub vel_speed(@)
	{
		my($u,$v) = &antsFunUsage(2,'..','[u, v]',\@fc,'u','v',@_); # . allows for nans
		return nan unless numbersp($u,$v);
		return sqrt($u*$u+$v*$v);
	}
}

sub polar_phi(@)
{
	my($x,$y) = &antsFunUsage(2,"ff","<x> <y>",@_);
	return 180 / $PI * atan2($y,$x);
}


{ my(@fc);
	sub vel_dir(@)
	{
		my($u,$v) = &antsFunUsage(2,'..','[u, v]',\@fc,'u','v',@_); # . allows for nans
		return nan unless numbersp($u,$v);
		my($dir) = 180 / $PI * atan2($u,$v);
		return ($dir >= 0) ? $dir : $dir+360;
	}
}

sub cartesian_x(@)
{
	my($r,$phi) = &antsFunUsage(2,"..","<r> <phi>",@_);
	return nan unless numbersp($r,$phi);
	return $r * cos($PI*$phi/180);
}

sub vel_u(@) { return &cartesian_x($_[0],90-$_[1]); }

sub cartesian_y(@)
{
	my($r,$phi) = &antsFunUsage(2,"..","<r> <phi>",@_);
	return nan unless numbersp($r,$phi);
	return $r * sin($PI*$phi/180);
}

sub vel_v(@) { return &cartesian_y($_[0],90-$_[1]); }

#----------------------------------------------------------------------
# magnetic heading from magnetometers
#	- atan2 handles all the singularities
#	- the current version (7/29/2016) was verified with ECOGIG EN586
#	  data, where the IMP Mk.3 rev 2 (i.e. with coordinate mapping
#	  in the sensor board) on profiles 1-15 was accidentally installed
#	  in a consistent orientation with the DL (very similar pitch/roll
#	  measured by both instruments) => heading is directly comparable
#----------------------------------------------------------------------

sub mag_heading($$)
{
#    return angle_pos(deg(-atan2($_[0],$_[1])));	# used for 2014 CLIVAR P06 IMP processing with confused coord systems
	return angle_pos(deg(atan2($_[1],$_[0])));
}

#----------------------------------------------------------------------
# &angle(val)
#	return angle in range [-180,180]
# &angle_pos(val)
#	return angle in range [0,360]
# &angle_diff(ref_dir,dir)
#	return rotation between two angles in range [-180,180]
# &rotation_ts(dir)
#	return time series of rotation
# &angle_ts(dir)
#	return time series of angle without "wrap-around jumps"
#----------------------------------------------------------------------

sub angle(@)
{
	my($val) = &antsFunUsage(1,".","<val>",@_);
	return nan unless numberp($val);
	$val += 360 while ($val < -180);
	$val -= 360 while ($val > 180);
	return $val;
}

sub angle_pos(@)
{
	my($val) = angle(@_);
	return nan unless numberp($val);
	return ($val < 0) ? 360+$val : $val;
}

sub angle_diff(@)
{
	my($m,$s) = &antsFunUsage(2,"..","<minuend> <subtrahend>",@_);
	return nan unless numbersp($m,$s);
	return angle($m-$s);
}

{ my($last_in);

  sub rotation_ts(@)
  {
	my($a) = &antsFunUsage(1,"f","<angle>",@_);

	my($rot) = defined($last_in) ? angle_diff($a,$last_in) : nan;
	$last_in = $a;
	return $rot;
  }
}

{ my($last_in,$last_out);

  sub angle_ts(@)
  {
	my($a) = &antsFunUsage(1,"f","<angle>",@_);

	$last_out = $last_in = $a
		unless (defined($last_in));

	$last_out += angle_diff($a,$last_in);
	$last_in = $a;
	return $last_out;
  }
}

#----------------------------------------------------------------------
# &ddeg(deg),&GMTdeg(deg)				convert degree formats
#----------------------------------------------------------------------

sub ddeg(@)
{
	my($deg) = &antsFunUsage(1,"","<degrees in GMT format>",@_);
	my($d,$m,$s) = split(':',$deg);
	return ($d>=0) ? $d+$m/60+$s/3600
				   : $d-$m/60-$s/3600;
}

# NB: without roundoff code, results are as follows:
#		abc -Lvec 'GMTdeg(ddeg("10:11"))' -> 10:11:8.52651e-13
#		abc -Lvec 'GMTdeg(ddeg("10:10"))' -> 10:9:60
sub GMTdeg(@)
{
	my($deg) = &antsFunUsage(1,"f","<degrees>",@_);
	my($sgn); if ($deg < 0) { $sgn = '-'; $deg *= -1; }
	my($min) = 60*($deg-int($deg));
	my($sec) = 60*($min-int($min));
	$sec=0,$min++ if equal($sec,60);
	$sec=0        if equal($sec,0);
	return sprintf("$sgn%d:%d:%g",int($deg),int($min),$sec);
}

sub degmin(@)
{
	my($deg) = &antsFunUsage(1,"f","<degrees>",@_);
	my($sgn); if ($deg < 0) { $sgn = '-'; $deg *= -1; }
	my($min) = 60*($deg-int($deg));
	$min=0 if equal($min,0);
	return sprintf("$sgn%d:%04.1f",int($deg),$min);
}

#----------------------------------------------------------------------
# &dist(lat1,lon1,lat2,lon2)	distance on globe (in m)
# &dist12(...)					ditto but with deg/min/sec separate
# &dir(lat1,lon1,lat2,lon2)		direction btw two points
# &area(gmt_region)				approximate area
#----------------------------------------------------------------------

sub dist(@)
{
	my($lat1,$lon1,$lat2,$lon2) =
		&antsFunUsage(4,"","lat1 lon1 lat2 lon2",@_);

	$lat1 = &ddeg($lat1);
	$lat2 = &ddeg($lat2);
	$lon1 = &ddeg($lon1);
	$lon2 = &ddeg($lon2);

	return 0 if ($lat1 == $lat2 && $lon1 == $lon2);	# avoid roundoff

	$radius = 6378139; 					# const
	$pi = 3.14159265358979;
	$d2r = $pi/180.0;
	
	$ct1 = cos($d2r*$lat1);
	$st1 = sin($d2r*$lat1);
	$cp1 = cos($d2r*$lon1);
	$sp1 = sin($d2r*$lon1);
	$ct2 = cos($d2r*$lat2);
	$st2 = sin($d2r*$lat2);
	$cp2 = cos($d2r*$lon2);
	$sp2 = sin($d2r*$lon2);
	
	$cosine = $ct1*$cp1*$ct2*$cp2 + $ct1*$sp1*$ct2*$sp2 + $st1*$st2;
	if ($cosine > 1.0) { $cosine = 1.0; }
	if ($cosine < -1.0) { $cosine = -1.0; }
	
	return $radius * acos($cosine);
}

sub dist12(@)
{
	my($la1d,$la1m,$la1s,$lo1d,$lo1m,$lo1s,
	   $la2d,$la2m,$la2s,$lo2d,$lo2m,$lo2s) =
		&antsFunUsage(12,"ffffffffffff","lat1 m s lon1 m s lat2 m s lon2 m s",@_);
	return dist(
		($la1d>=0)?$la1d+$la1m/60+$la1s/3600 : $la1d-$la1m/60-$la1s/3600,
		($lo1d>=0)?$lo1d+$lo1m/60+$lo1s/3600 : $lo1d-$lo1m/60-$lo1s/3600,
		($la2d>=0)?$la2d+$la2m/60+$la2s/3600 : $la2d-$la2m/60-$la2s/3600,
		($lo2d>=0)?$lo2d+$lo2m/60+$lo2s/3600 : $lo2d-$lo2m/60-$lo2s/3600
	);
}

sub dir(@)
{
	my($lat1,$lon1,$lat2,$lon2) =
		&antsFunUsage(4,"","lat1 lon1 lat2 lon2",@_);
	my($dx) = dist(($lat1+$lat2)/2,$lon1,($lat1+$lat2)/2,$lon2);
	$dx *= -1 if ($lon2 < $lon1);
	my($dy) = dist($lat1,($lon1+$lon2)/2,$lat2,($lon1+$lon2)/2);
	$dy *= -1 if ($lat2 < $lat1);
	return ($dx == 0 && $dy == 0) ? nan : vel_dir($dx,$dy);
}

sub area(@)
{
	my($R) = &antsFunUsage(1,"",'<"W/E/S/N">',@_);
	my($W,$E,$S,$N) = split('/',$R);

	return (&dist($S,$W,$S,$E) + &dist($N,$W,$N,$E)) / 2 *
		   (&dist($S,$W,$N,$W) + &dist($S,$E,$N,$E)) / 2;
}

#----------------------------------------------------------------------
# ($lat,$lon,$t) = &closestPointOnStraightLine(lat,lon,lat1,lonA,lat2,lon2)
#	- determine point on line segment from <lat1,lonA> to <lat2,lon2> that
#	  is closest to target point <lat,lon>
#	- $t [0-1] output indicates where along the line segment the closest
#	  point lies
#   - http://stackoverflow.com/questions/3120357/get-closest-point-to-a-line
#	- NOT DONE IN PLANAR GEOMETRY => USE ONLY IN SMALL DOMAINS
#----------------------------------------------------------------------

sub closestPointOnStraightLine(@)
{
	my($latP,$lonP,$latA,$lonA,$latB,$lonB) =
		&antsFunUsage(6,'ffffff','pnt_lat, pnt_lon, lne_latA, lne_lonA, lne_latB, lne_lonB',@_);

	my($ABlon) = $lonB - $lonA; my($ABlat) = $latB - $latA; 
	my($APlon) = $lonP - $lonA; my($APlat) = $latP - $latA;
	my($t) = ($APlon*$ABlon + $APlat*$ABlat) / ($ABlon**2 + $ABlat**2);
	return (undef,undef) unless ($t>=0 && $t<=1);
	return ($latA + $t*$ABlat,$lonA + $t*$ABlon, $t);
}

1;
