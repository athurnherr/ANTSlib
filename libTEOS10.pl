#======================================================================
#                    L I B T E O S 1 0 . P L 
#                    doc: Fri Jan 18 11:09:22 2019
#                    dlm: Fri Jan 18 23:23:27 2019
#                    (c) 2019 A.M. Thurnherr
#                    uE-Info: 144 30 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# perl wrapper for GSW TEOS-10 libary

# Notes:
#	- requires GSW shared library (currently GSW-C-3.05.0-4)
#	- requires home-grown perl-interface, implementing GSW::
#	- small subset of functions implemented
#	- no temperature scale assumed; set PARAM ITS=90|68
#	- T90*1.00024=T68
#	- check values calculated with T68

# HISTORY:
#	Jan 18, 2019: - created

require "$ANTS/libvec.pl";

use strict;
use GSW;

#----------------------------------------------------------------------
# ITS-68/-90 conversion
#	- call once return conversion factor
#	- divide input temperatures by conversion factor to turn into ITS-90
#	- multiply output temperatures by conv factor to return to original ITS
#	- optimized for repeat calls
#----------------------------------------------------------------------

{ # BEGIN STATIC SCOPE
	my($TCONV);
	sub TCONV90()
	{
		return $TCONV if defined($TCONV);
		my($ITS) = &antsRequireParam('ITS');
		if ($ITS == 68) { 		$TCONV = 1.00024;
		} elsif ($ITS == 90) {	$TCONV = 1;
		} else {
			croak("$0: illegal PARAM-value ITS=$ITS\n");
        }
	}
} # END STATIC SCOPE

#----------------------------------------------------------------------
# practical salinity
#	- input: cond temp press
#	- use units from %cond.unit
#	- IDENTICAL TO EOS83 VERIFIED
#----------------------------------------------------------------------

{ my(@fc,$cscale);
	sub salin(@)
	{
		my($C,$T,$P) = &antsFunUsage(3,'...','[cond, temp, press]',
									 \@fc,'cond','temp','press',@_);
		unless (defined($cscale)) {
			my($cu) = &antsRequireParam('cond.unit');
			if    ($cu eq 'S/m')   { $cscale = 10; }
			elsif ($cu eq 'mS/cm') { $cscale = 1;  }
			else { croak("$0: illegal PARAM-value cond.unit=$cu\n"); }
		}									 
		return numbersp($C,$T,$P) ?
					GSW::gsw_sp_from_c($C*$cscale,$T,$P) :
					'nan';
	}
}

#----------------------------------------------------------------------
# conductivity
#	- input: salin temp press
#	- take units from %cond.unit
#	- COND(SALIN(COND)) = COND VERIFIED
#----------------------------------------------------------------------

{ my(@fc,$cscale);
	sub cond(@)
	{
		my($S,$T,$P) = &antsFunUsage(3,'...','[salin, temp, press]',
									 \@fc,'salin','temp','press',@_);
		unless (defined($cscale)) {
			my($cu) = &antsRequireParam('cond.unit');
			if    ($cu eq 'S/m')   { $cscale = 10; }
			elsif ($cu eq 'mS/cm') { $cscale = 1;  }
			else { croak("$0: illegal PARAM-value cond.unit=$cu\n"); }
		}									 
		return numbersp($S,$T,$P) ?
					GSW::gsw_c_from_sp($S,$T,$P)/$cscale :
					'nan';
	}
}

#----------------------------------------------------------------------
# absolute salinity
#	- input salin, press, lon, lat
#	- if %lat/%lon are available, they are used
#	- otherwise, they must be supplied as arguments
#----------------------------------------------------------------------

{ my(@fc);
	sub asalin(@)
	{
		my($LON,$LAT,$SP,$P);
		$LON = &antsParam('lon');
		$LAT = &antsParam('lat');
		if (numbersp($LON,$LAT))  {
			($SP,$P) = &antsFunUsage(2,'..','[salin, press]',
									 \@fc,'salin','press',@_);
		} else {
			($SP,$P,$LON,$LAT) =
				&antsFunUsage(4,'....','[salin, press, lon, lat]',
							  \@fc,'salin','press','lon','lat',@_);
		}
		return numbersp($LON,$LAT,$SP,$P) ?
					GSW::gsw_sa_from_sp($SP,$P,$LON,$LAT) :
					'nan';
	}
}

#---------------------------------------------------------------------- 
# potential temperature
#	- DIFFERENCES < 0.0005 degC IN FULL DEPTH PROFILE VIZ [libEOS83.pl]
#---------------------------------------------------------------------- 

{ my(@fc);
	sub theta(@)
	{
		my($SA,$T,$P,$Pref) =
 			&antsFunUsage(4,'....','[asalin, temp, press,] refpress',
						  \@fc,'asalin','temp','press',undef,@_);
		return 'nan' unless numbersp($SA,$T,$P,$Pref);
		return $T if ($P == $Pref);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_pt_from_t($SA,$T/$TCONV,$P,$Pref)*$TCONV;
	}
}

#---------------------------------------------------------------------- 
# conservative temperature
#	- input: asalin temp press
#---------------------------------------------------------------------- 

{ my(@fc);
	sub ctemp(@)
	{
		my($SA,$T,$P) =
			&antsFunUsage(3,'...','[asalin, temp, press]',
						  \@fc,'asalin','temp','press',@_);
		return 'nan' unless numbersp($SA,$T,$P);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_ct_from_t($SA,$T/$TCONV,$P)*$TCONV;
	}
}

#---------------------------------------------------------------------- 
# depth
#	- input: press lat
#	- if %lat is available, it is used
#	- CHECKED AGAINS [libEOS83.pl] => DIFF < 0.12m FOR FULL DEPTH PROF
#	- PRESS(DEPTH(PRESS)) = PRESS VERIFIED
#---------------------------------------------------------------------- 

{ my(@fc);
	sub depth(@)
	{
		my($P,$LAT);
		$LAT = &antsParam('lat');
		if (numberp($LAT)) {
			($P) = &antsFunUsage(1,'.','[press]',\@fc,'press',@_);
		} else {
			($P,$LAT) = &antsFunUsage(2,'..','[press, lat]',\@fc,'press','lat',@_);
		}
		return numbersp($P,$LAT) ? -1*GSW::gsw_z_from_p($P,$LAT) : 'nan';
	}
}

#---------------------------------------------------------------------- 
# press
#	- input: depth lat
#	- if %lat is available, it is used
#	- PRESS(DEPTH(PRESS)) = PRESS VERIFIED
#---------------------------------------------------------------------- 

{ my(@fc);
	sub press(@)
	{
		my($D,$LAT);
		$LAT = &antsParam('lat');
		if (numberp($LAT)) {
			($D) = &antsFunUsage(1,'.','[depth]',\@fc,'depth',@_);
		} else {
			($D,$LAT) = &antsFunUsage(2,'..','[depth, lat]',\@fc,'depth','lat',@_);
		}
		return numbersp($D,$LAT) ? GSW::gsw_p_from_z(-1*$D,$LAT) : 'nan';
	}
}

#---------------------------------------------------------------------- 
# thermal expansion coefficient
#	- input: asalin ctemp press
#	- ~ 1% higher than homegrown approximation in [libEOS83.pl]
#---------------------------------------------------------------------- 

{ my(@fc);
	sub alpha(@)
	{
		my($SA,$TC,$P) =
			&antsFunUsage(3,'...','[asalin, ctemp, press]',
						  \@fc,'asalin','ctemp','press',@_);
		return 'nan' unless numbersp($SA,$TC,$P);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_alpha($SA,$TC/$TCONV,$P);
	}
}

#---------------------------------------------------------------------- 
# haline contraction coefficient
#	- input: asalin ctemp press
#	- ~ 0.6% lower than homegrown approximation in [libEOS83.pl]
#---------------------------------------------------------------------- 

{ my(@fc);
	sub beta(@)
	{
		my($SA,$TC,$P) =
			&antsFunUsage(3,'...','[asalin, ctemp, press]',
						  \@fc,'asalin','ctemp','press',@_);
		return 'nan' unless numbersp($SA,$TC,$P);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_beta($SA,$TC/$TCONV,$P);
	}
}

#---------------------------------------------------------------------- 
# in situ density
#	- input: asalin ctemp press
#	- CHECKED RHO & ALL SIGMA AGAINST [libEOS83.pl] => CONSISTENT PATTERN
#---------------------------------------------------------------------- 

{ my(@fc);
	sub rho(@)
	{
		my($SA,$TC,$P) =
			&antsFunUsage(3,'...','[asalin, ctemp, press]',
						  \@fc,'asalin','ctemp','press',@_);
		return 'nan' unless numbersp($SA,$TC,$P);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_rho($SA,$TC/$TCONV,$P);
	}
}

#---------------------------------------------------------------------- 
# potential density
#	- input: asalin ctemp
#	- CHECKED RHO & ALL SIGMA AGAINST [libEOS83.pl] => CONSISTENT PATTERN
#---------------------------------------------------------------------- 

{ my(@fc);
	sub sigma0(@)
	{
		my($SA,$TC) = &antsFunUsage(2,'..','[asalin, ctemp]',\@fc,'asalin','ctemp',@_);
		return 'nan' unless numbersp($SA,$TC);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_sigma0($SA,$TC/$TCONV);
	}
}

{ my(@fc);
	sub sigma1(@)
	{
		my($SA,$TC) = &antsFunUsage(2,'..','[asalin, ctemp]',\@fc,'asalin','ctemp',@_);
		return 'nan' unless numbersp($SA,$TC);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_sigma1($SA,$TC/$TCONV);
	}
}

{ my(@fc);
	sub sigma2(@)
	{
		my($SA,$TC) = &antsFunUsage(2,'..','[asalin, ctemp]',\@fc,'asalin','ctemp',@_);
		return 'nan' unless numbersp($SA,$TC);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_sigma2($SA,$TC/$TCONV);
	}
}

{ my(@fc);
	sub sigma3(@)
	{
		my($SA,$TC) = &antsFunUsage(2,'..','[asalin, ctemp]',\@fc,'asalin','ctemp',@_);
		return 'nan' unless numbersp($SA,$TC);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_sigma3($SA,$TC/$TCONV);
	}
}

{ my(@fc);
	sub sigma4(@)
	{
		my($SA,$TC) = &antsFunUsage(2,'..','[asalin, ctemp]',\@fc,'asalin','ctemp',@_);
		return 'nan' unless numbersp($SA,$TC);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_sigma4($SA,$TC/$TCONV);
	}
}

#---------------------------------------------------------------------- 
# sound speed
#	- input: asalin ctemp press
#	- VERIFIED AGAINST [libEOS83.pl]
#---------------------------------------------------------------------- 

{ my(@fc);
	sub sound_speed(@)
	{
		my($SA,$TC,$P) =
			&antsFunUsage(3,'...','[asalin, ctemp, press]',
						  \@fc,'asalin','ctemp','press',@_);
		return 'nan' unless numbersp($SA,$TC,$P);
		my($TCONV) = &TCONV90();					# library uses ITS90
		return GSW::gsw_sound_speed($SA,$TC/$TCONV,$P);
	}
}

#----------------------------------------------------------------------
# Coriolis parameter
#	- input: lat
#	- copied from [libEOS83.pl]
#----------------------------------------------------------------------

{ my(@fc);
	sub f(@)
	{
		my($lat) = &antsFunUsage(1,'f','[lat]',\@fc,'%lat',@_);
		my($Omega) = 7.292e-5;								# Gill (1982)
		return 2 * $Omega * sin(rad($lat));
	}
}

#---------------------------------------------------------------------- 
# acceleration due to gravity
#	- input: press lat
#	- if %lat is available, it is used
#	- CHECKED AGAINST [libEOS83.pl] => DIFFERENCES LESS THAN 0.1%
#---------------------------------------------------------------------- 

{ my(@fc);
	sub g(@)
	{
		my($P,$LAT);
		$LAT = &antsParam('lat');
		if (numberp($LAT)) {
			($P) = &antsFunUsage(1,'.','[press]',\@fc,'press',@_);
		} else {
			($P,$LAT) = &antsFunUsage(2,'..','[press, lat]',\@fc,'press','lat',@_);
		}
		return numbersp($P,$LAT) ? GSW::gsw_grav($LAT,$P) : 'nan';
	}
}

1;

