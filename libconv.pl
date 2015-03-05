#======================================================================
#                    L I B C O N V . P L 
#                    doc: Sat Dec  4 13:03:49 1999
#                    dlm: Thu Aug  7 09:17:59 2014
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 203 27 NIL 0 0 70 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#   Dec 12, 1999: - created for the Rainbow CM data as libdate
#   Jul 07, 2000: - renamed to libconv and added lat/lon conversions
#   Aug 21, 2000: - added &s2d()
#   Aug 24, 2000: - added &DDMMXh2d() and &DDDMMXh2d()
#   Aug 28, 2000: - moved &DDMMXh2d() and &DDDMMXh2d() to [libNODC.pl]
#   Sep 04, 2000: - added &GMT2d()
#   Sep 20, 2000: - added &fmtdate(), &fmttime()
#   Oct 16, 2000: - added &dmsh2d()
#   Oct 31, 2000: - added &T90(), &T68()
#   Jan 22, 2001: - BUG: &GMT2d() wrongly +ve-ized stuff like -00:05
#   Feb 28, 2001: - added &O2mlpl2umpkg()
#   Aug  3, 2001: - made &O2mlpl2umpkg() return NaN on -ve input
#   Aug  7, 2001: - added &O2umpkg2mlpl()
#                 - replaced temp_scale by ITS
#   Aug  8, 2001: - BUG: allowed for NaN O2 values
#   Aug 19, 2001: - change temp-conversions to allow nop; changed names
#   Sep  1, 2001: - BUG: allow for nan in addition to NaN
#	Dec 30, 2001: - generalized s2d()
#				  - BUG: allow NaNs on temp conversions
#	Feb  4, 2002: - allow for -ve O2 values in conversions to handle offsets
#	Aug 14, 2002: - moved ITS checks in ITS_68() & ITS_90()
#	Oct  9, 2002: - added &fmttime1(),&fmtdate1()
#	Jan 23, 2003: - added more time conversion routines
#	Apr 14, 2003: - removed antsReplaceParam() call
#	May 21, 2004: - added ``-'' as a valid date separator
#	Jun 22, 2004: - added HSV2RGB()
#	Jun 27, 2004: - renamed degree-conversion routines
#				  - added wraplon()
#	Dec  1, 2005: - cosmetics
#	Dec  9, 2005: - Version 3.2 [HISTORY]
#	Apr  4, 2006: - made epoch optional in &dayNo()
#	Apr 28, 2006: - added &dn2date()
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#	Nov  9, 2006: - added dec_time()
#				  - added dn2date_time()
#				  - moved year forward in dn2date()
#	Oct 17, 2007: - dn2date -> Date
#				  - dn2date_time -> Time
#				  - adapted Date/Time to antsFunUsage() with default fields
#	Oct 19, 2007: - removed antsFunUsage() from non-UI funs
#	Nov 17, 2007: - added "." as another legal date separator
#	Jul 10, 2008: - added support for month names in dayNo()
#	Dec  1, 2008: - added dec_time_long()
#	Dec  3, 2008: - renamed many of the date-conversion routines
#				  - added frac_day()
#	Jan  8, 2009: - BUG: &Date() returned wrong date for any time after
#						 midnite on last day of a month
#	Oct 27, 2010: - added &day_secs()
#	Jan  3, 2010: - extended frac_day() to allow a single string time-spec
#	Jul 19, 2011: - made epoch aptional in mmddyy2dec_time()
#	Aug  2, 2011: - enhanced yymmdd2dec_time()
#	Apr 17, 2012: - added space as another date separator in ddmmyy2dec_time
#	May 22, 2012: - BUG: illegal time spec error was also produced on missing seconds
#				  - BUG: mmddyy2dec_time() did not allow for optional epoch argument
#	Aug  7, 2014: - finally cleaned up date conversions

require "$ANTS/libEOS83.pl";                        # &sigma()
require "$ANTS/libPOSIX.pl";                        # &floor()
require "$ANTS/libstats.pl";                        # &min(),&max()

#----------------------------------------------------------------------
# Date Conversion
#----------------------------------------------------------------------

sub leapYearP(@)                                    # leap year?
{
    my($y) = @_;

    $y += ($y < 50) ? 2000 : 1900 if ($y < 100);    # Y2K

    return 0 if ($y%4 != 0);
    return 1 if ($y%100 != 0);
    return 0 if ($y%400 > 0);
    return 1;
}

sub monthLength(@)                                  # #days in given month/year
{
    my($y,$m) = @_;

    return 31 if ($m==1 || $m==3 || $m==5 || $m==7 ||
                  $m==8 || $m==10 || $m==12);
    return 30 if ($m==4 || $m==6 || $m==9 || $m==11);
    return 28 + &leapYearP($y) if ($m == 2);
    croak("$0: &monthLength(): Illegal month\n");
}

sub dayNo(@)										# day number, starting at 1
{
    my($y,$m,$d,$epoch) =
        &antsFunUsage(-3,"c..","year, month, day[, epoch]",@_);
	$epoch = $y unless defined($epoch);

	unless (cardinalp($m)) {
		$m = lc($m);
		if    ($m =~ /^jan/) { $m = 1; }
		elsif ($m =~ /^feb/) { $m = 2; }
		elsif ($m =~ /^mar/) { $m = 3; }
		elsif ($m =~ /^apr/) { $m = 4; }
		elsif ($m =~ /^may/) { $m = 5; }
		elsif ($m =~ /^jun/) { $m = 6; }
		elsif ($m =~ /^jul/) { $m = 7; }
		elsif ($m =~ /^aug/) { $m = 8; }
		elsif ($m =~ /^sep/) { $m = 9; }
		elsif ($m =~ /^oct/) { $m = 10; }
		elsif ($m =~ /^nov/) { $m = 11; }
		elsif ($m =~ /^dec/) { $m = 12; }
		else { croak("$0: unknown month $m\n"); }
	}

    my($dn) = 0;        

    $epoch += ($epoch < 50) ? 2000 : 1900           # Y2K       
        if ($epoch < 100);
    $y += ($y < 50) ? 2000 : 1900
        if ($y < 100);

    croak("$0: &dayNo(): Error: epoch > year\n")        # only positive times
        if ($y < $epoch);
    while ($epoch < $y) {                           # entire years
        $dn += 365 + &leapYearP($epoch);
        $epoch++;
    }
    
    croak("$0: &dayNo(): Error: day > #days of month\n")    # current month
        if ($d > &monthLength($y,$m));
    $dn += $d;
    $m--;

    while ($m > 0) {                                # current year
        $dn += &monthLength($y,$m);
        $m--;
    }

    return $dn
}

sub frac_day(@)										# fractional day
{
	my($h,$m,$s);
	if (@_ == 1) {
		($h,$m,$s) = split(':',$_[0]);
	} else {
		($h,$m,$s) = &antsFunUsage(3,'ccf',"<h:m:s>|<hour> <min> <sec>",@_);
	}

	croak("$0: &frac_day_long(): illegal time spec $h:$m:$s\n")
		unless ((defined($h) && $h>=0 && $h<24) &&
				(defined($m) && $m>=0 && $m<60) &&
				(!defined($s) || ($s>=0 && $s<60)));
	return $h/24 + $m/24/60 + $s/24/3600;
}

sub day_secs(@)										# seconds since daystart
{
	my($h,$m,$s) = &antsFunUsage(3,'ccf',"<hour> <min> <sec>",@_);

	croak("$0: &frac_day_long(): illegal time spec $h:$m:$s\n")
		unless ((defined($h) && $h>=0 && $h<24) &&
				(defined($m) && $m>=0 && $m<60) &&
				(!defined($s) || ($s>=0 && $s<60)));
	return $h*3600 + $m*60 + $s;
}

sub dec_time(@)										# decimal time
{
	my($epoch,$yy,$mm,$dd,$h,$m,$s) =
        &antsFunUsage(7,'ccccccf',"<epoch> <year> <month> <day> <hour> <min> <sec>",@_);
	return &dayNo($yy,$mm,$dd,$epoch) + &frac_day($h,$m,$s);
}

#----------------------------------------------------------------------
# String to Decimal Time Conversion
#----------------------------------------------------------------------

{ my($date_fmt); 

	sub str2dec_time(@) 									# heuristic
	{
		my($ds,$ts,$epoch) =
			&antsFunUsage(-2,"..","date, hh:mm[:ss][, epoch]",@_);
	
		croak("$0 str2dec_time: date required\n") unless ($ds ne '');

		unless (defined($date_fmt)) {
			my($X,$Y,$Z) = split('[-/\.]',$ds);
			if ($X > 31) {									# YY/MM//DD
				$date_fmt = 1;							    
			} elsif ($X > 12) { 							# DD/MM/YY
				$date_fmt = 2;
			} elsif ($Y > 12) { 							# MM/DD/YY
				$date_fmt = 3;
			} else {
				&antsInfo("str2dec_time: ambiguous date <$ds>; MM/DD/YY assumed");
				$date_fmt = 3;
	        }
	    }

	    if 	  ($date_fmt == 1) { return yymmdd2dec_time($ds,$ts,$epoch); }
	    elsif ($date_fmt == 2) { return ddmmyy2dec_time($ds,$ts,$epoch); }
	    else 				   { return mmddyy2dec_time($ds,$ts,$epoch); }
    }

}

sub mmddyy2dec_time(@)								
{
	my($ds,$ts,$epoch) =
        &antsFunUsage(-2,"..","MM/DD/[YY]YY, hh:mm[:ss][, epoch]",@_);

	my($time) = 0;
	if ($ds ne '') {
		my($yy,$mm,$dd);
		if (length($ds) == 6) {
			$mm = substr($ds,0,2);
			$dd = substr($ds,2,2);
			$yy = substr($ds,4,2);
		} else {
			($mm,$dd,$yy) = split('[-/\.]',$ds);
		}
		$time = dayNo($yy,$mm,$dd,$epoch);
	}
	if ($ts ne '') {
		my($h,$m,$s) = split(':',$ts);
		$s = 0 unless defined($s);
	    return $time + &frac_day($h,$m,$s);
	}
	return $time;
}

sub ddmmyy2dec_time(@)
{
	my($ds,$ts,$epoch) =
        &antsFunUsage(-2,"..","DD/MM/[YY]YY, hh:mm[:ss][, epoch]",@_);

	my($time) = 0;
	if ($ds ne '') {
		my($yy,$mm,$dd);
		if (length($ds) == 6) {
			$dd = substr($ds,0,2);
			$mm = substr($ds,2,2);
			$yy = substr($ds,4,2);
		} else {
			($dd,$mm,$yy) = split('[-/\.]',$ds);
		}
		$time = dayNo($yy,$mm,$dd,$epoch);
	}

	if ($ts ne '') {
		my($h,$m,$s) = split(':',$ts);
		$s = 0 unless defined($s);
	    return $time + &frac_day($h,$m,$s);
	}

	return $time;
}

sub yymmdd2dec_time(@)								
{
	my($ds,$ts,$epoch) =
        &antsFunUsage(-2,"..","[YY]YY/MM/DD, hh:mm[:ss][, epoch]",@_);

	my($time) = 0;
	if ($ds ne '') {								
		my($yy,$mm,$dd);
		if (length($ds) == 6) {
			$yy = substr($ds,0,2);
			$mm = substr($ds,2,2);
			$dd = substr($ds,4,2);
		} else {
			($yy,$mm,$dd) = split('[-/\.]',$ds);
		}
		$time = dayNo($yy,$mm,$dd,$epoch);
	}

	if ($ts ne '') {
		my($h,$m,$s) = split(':',$ts);
		$s = 0 unless defined($s);
	    return $time + &frac_day($h,$m,$s);
	}

	return $time;
}

#----------------------------------------------------------------------
# Decimal Time to Strin Conversion
#----------------------------------------------------------------------

{ my(@fc);

	sub Date(@) 										# day number -> date
	{
	
		my($dnf);										# find std dn field & epoch
		if (@_ == 0) {
			for (my($i)=0; $i<@antsLayout; $i++) {
				next unless ($antsLayout[$i] =~ /^dn(\d\d)$/);
				$dnf = $antsLayout[$i]; push(@_,$1);
				last;
	        }
	    }
	    
		my($year,$day) = &antsFunUsage(2,"cf","epoch, dayNo",\@fc,undef,$dnf,@_);
	
		$year += ($year < 50) ? 2000 : 1900 			# Y2K
			if ($year < 100);
	
		$day = int($day);								# prevent runover on last day of month
		while ($day > 365+&leapYearP($year)) {			# adjust year
			$day -= 365 + &leapYearP($year);
			$year++;
		}
	
		my($month) = 1;
		while ($day > &monthLength($year,$month)) {
			$day -= &monthLength($year,$month);
			$month++;
		}
	
		return sprintf('%04d/%02d/%02d',$year,$month,$day);
	}
}

{ my(@fc);

	sub Time(@) 										# day number -> date/time
	{
		my($dnf);										# find standard dn field
		for (my($i)=0; $i<@antsLayout; $i++) {
			next unless ($antsLayout[$i] =~ /^dn\d\d$/);
			$dnf = $antsLayout[$i];
			last;
		}
	    
		my($fday) = &antsFunUsage(1,"f","dayNo",\@fc,$dnf,@_);
		my($day) = int($fday);
		$fday -= $day;
	
		my($hour) = int(24*$fday);
		$fday -= $hour/24;
		my($min) = int(24*60*$fday);
		$fday -= $min/24/60;
		my($sec) = round(24*3600*$fday);
		$min++,$sec=0 if ($sec == 60);
		$hour++,$min=0 if ($min == 60);
		$day++,$hour=0 if ($hour == 24);
	
		return sprintf('%02d:%02d:%02d',$hour,$min,$sec);
	}
}

#----------------------------------------------------------------------
# Other Misc Date Conversions
#----------------------------------------------------------------------

sub date2str(@)
{
    my($MM,$DD,$YYYY) = &antsFunUsage(3,'ccc','month, day, year',@_);
    $YYYY += 2000 if ($YYYY < 50);
    $YYYY += 1900 if ($YYYY < 100);
    return sprintf('%02d',$MM) . '/' .
           sprintf('%02d',$DD) . '/' . $YYYY;
}

sub card_date2str(@)
{
    my($DDMMYY) = &antsFunUsage(1,'c','ddmmyy',@_);
    $DDMMYY = sprintf('%06d',$DDMMYY);
    return &fmtdate(substr($DDMMYY,2,2),substr($DDMMYY,0,2),substr($DDMMYY,4,2));
}

sub time2str(@)
{
    my($HH,$MM) = &antsFunUsage(2,'cc','hr, min',@_);
    return sprintf('%02d',$HH) . ':' . sprintf('%02d',$MM);
}

sub card_time2str(@)
{
    my($HHMM) = &antsFunUsage(1,'c','hrmin',@_);
    return &fmttime(int($HHMM/100),$HHMM%100);
}

#----------------------------------------------------------------------
# Lat/Lon Conversion
#----------------------------------------------------------------------

sub wraplon(@)		# get sign of longitudes right
{
	my($deg) = &antsFunUsage(1,'f','deg',@_);
	return ($deg > 180) ? $deg - 360 : $deg;
}

sub dmh2deg(@)		# dd mm.m NSEW -> dd.d
{
    my($deg,$min,$hemisph) =
        &antsFunUsage(3,'ff1','deg, min, hemisphere',@_);
    croak("$0 dmh2d(): <deg> may not be -ve\n") if ($deg < 0);
    croak("$0 dmh2d(): <min> may not be -ve\n") if ($min < 0);
    $deg += $min/60;
    $_ = $hemisph;
    SWITCH: {
        $deg = -$deg, last SWITCH if (/[sSwW]/);
        last SWITCH if (/[nNeE]/);
        croak("$0 dmh2d(): $hemisph is an invalid hemisphere id\n");
    }
    return $deg;
}

sub dmsh2deg(@)   # dd mm ss NSEW -> dd.d
{
    my($deg,$min,$sec,$hemisph) =
        &antsFunUsage(4,'fff1','deg, min, sec, hemisphere',@_);
    croak("$0 dmsh2d(): <deg> may not be -ve\n") if ($deg < 0);
    croak("$0 dmsh2d(): <min> may not be -ve\n") if ($min < 0);
    croak("$0 dmsh2d(): <sec> may not be -ve\n") if ($sec < 0);
    $deg += $min/60 + $sec/3600;
    $_ = $hemisph;
    SWITCH: {
        $deg = -$deg, last SWITCH if (/[sSwW]/);
        last SWITCH if (/[nNeE]/);
        croak("$0 dmh2d(): $hemisph is an invalid hemisphere id\n");
    }
    return $deg;
}

sub str2deg(@)      # string containing dd [mm.m] [NSEW] -> dd.d
{
    my($s) = &antsFunUsage(1,'.',"'deg[ :][min][ ]hemisphere'",@_);
    my($deg,$a,$b) = ($s =~ m{^([-\d]+)[\s:]([\d\.]+)\s*([NSEW])$});
#    print(STDERR "--> $deg, $a, $b\n");
	return ($b eq "") ? &dmh2d($deg,0,$a) : &dmh2d($deg,$a,$b);
}

sub GMT2deg(@)	# GMT degree format to decimal
{
	my($GMT) = &antsFunUsage(1,".","GMT-degs ",@_);
	return (substr($1,0,1) eq "-") ? $1-$2/60.0 : $1+$2/60.0
		if ($GMT =~ /\s*([^:]+):([^:]+)/);
	return $GMT;
}

#----------------------------------------------------------------------
# Temp-Scale Conversion
#----------------------------------------------------------------------

{ my($ITS);

sub ITS_68(@)		  # T90|T68 -> T68
{
	unless (defined($ITS)) {
		$ITS = &antsRequireParam('ITS');
		croak("$0 ITS_68(): ITS == $ITS???\n")
			unless ($ITS == 68 || $ITS ==90);
		unless ($ITS == 68)	{
			croak("$0 ITS_68(): can't change %ITS after flushing header\n")
				if ($antsHeadersPrinted);
			&antsAddParams('ITS',68);
		}
	}
	my($temp) = &antsFunUsage(1,".","temp",@_);
	return nan unless (numberp($temp));
	return($temp) if ($ITS == 68);
    return $temp * 1.00024;
}

} # static scope

{ my($ITS);

sub ITS_90(@)		  # T90|T68 -> T90
{
	unless (defined($ITS)) {
		$ITS = &antsRequireParam('ITS');
		croak("$0 ITS_90(): ITS == $ITS???\n")
			unless ($ITS == 68 || $ITS ==90);
		unless ($ITS == 90)	{
			croak("$0 ITS_90(): can't change %ITS after flushing header\n")
				if ($antsHeadersPrinted);
			&antsAddParams('ITS',90);
		}
	}
	my($temp) = &antsFunUsage(1,".","temp",@_);
	return nan unless (numberp($temp));
	return($temp) if ($ITS == 90);
	return $temp / 1.00024;
}

}

#----------------------------------------------------------------------
# Oxygen Unit Conversion
#
# - old units (e.g. sd2) are ml/l
# - new units (e.g. WOCE) are umol/kg => independent of pressure!
# - conversion (from [http://sea-mat.whoi.edu/robbins/ox_units.m]; Paul
#	Robbins) uses potential density ref'd to surface --- makes sense
#	because titration is presumably done at atmospheric pressure
# - constant divisor is volume of one mole derived from gas law
#   (PV = nRT) in the right units (whatever)
#----------------------------------------------------------------------

{ my(@fc);
	sub O2mlpl2umpkg(@)
	{
		return nan if isnan($_[3]);
		my($S,$T,$P,$mlpl) =
			&antsFunUsage(4,'ffff','[S, T, P [dbar], O2 [ml/l]]',
						  \@fc,'salin','temp','press','O2',@_);
		return $mlpl * 1000/(1000+sigma($S,$T,$P,0)) / .022403;
	}
}
		
{ my(@fc);
	sub O2umpkg2mlpl(@)
	{
		return nan if isnan($_[3]);
		my($S,$T,$P,$umpkg) =
			&antsFunUsage(4,'ffff','[S, T, P [dbar], O2 [ml/l]]',
						  \@fc,'salin','temp','press','O2',@_);
		return .022403 * $umpkg * (1000+sigma($S,$T,$P,0))/1000;
	}
}
		
#----------------------------------------------------------------------
# Color Conversion
#
# - algorithms taken from the web; source given alternatively as ACM 
#	and Foley and VanDam
# - from the available GMT default cpt files, it looks like
#	the range for hue is 0 - 359 (angles on a circle)
# - ACM implementation uses a hue range of 0-6 with pure red being 0 or 6
# - ACM implementation uses range of 0-1 for R,G,B
# - in HSV, gray scales are not uniquely defined; I extended the 
#   algorithms to behave like matlab in this case, i.e. return a hue of
#	pure red (0)
#----------------------------------------------------------------------

sub HSV2RGB(@)
{
    my($H,$S,$V) = &antsFunUsage(3,"fff","H (0-360), S (0-1), V (0-1), ",@_);
	my($m,$n,$f,$i);

	$H = 0 if ($H < 0 && $H >= -$PRACTICALLY_ZERO);
	croak("$0 HSV2RGB(): H=$H out of range\n") if ($H < 0 || $H > 360);
	croak("$0 HSV2RGB(): S=$S out of range\n") if ($S < 0 || $S > 1);
	croak("$0 HSV2RGB(): V=$V out of range\n") if ($V < 0 || $V > 1);

	$i = POSIX::floor($H/60);	# ACM implementation uses [0-6] with red = 0 = 6
	$f = $H/60 - $i;
	$f = 1 - $f if (!($i & 1));	# if i is even
	$m = $V * (1 - $S);
	$n = $V * (1 - $S * $f);
	return (int(255*$V+0.5),int(255*$n+0.5),int(255*$m+0.5)) if ($i==0 || $i==6);
	return (int(255*$n+0.5),int(255*$V+0.5),int(255*$m+0.5)) if ($i == 1);
	return (int(255*$m+0.5),int(255*$V+0.5),int(255*$n+0.5)) if ($i == 2);
	return (int(255*$m+0.5),int(255*$n+0.5),int(255*$V+0.5)) if ($i == 3);
	return (int(255*$n+0.5),int(255*$m+0.5),int(255*$V+0.5)) if ($i == 4);
	return (int(255*$V+0.5),int(255*$m+0.5),int(255*$n+0.5)) if ($i == 5);
	croak("$0 HSV2RGB(): implementation error");
}

sub RGB2HSV(@)
{
	my($R,$G,$B) = &antsFunUsage(3,"cc","R, G, B",@_);
	my($V,$x,$f,$i,$H);

	$R /= 255; $G /= 255; $B /= 255;
	croak("$0 RGB2HSV(): R out of range\n") if ($R < 0 || $R > 1);
	croak("$0 RGB2HSV(): G out of range\n") if ($G < 0 || $G > 1);
	croak("$0 RGB2HSV(): B out of range\n") if ($B < 0 || $B > 1);

	$x = min($R,$G,$B);
	$V = max($R,$G,$B);
	return (0,0,$V) if ($V == $x);	# any hue is valid

	$f = ($R == $x) ? $G - $B : (($G == $x) ? $B - $R : $R - $G);
	$i = ($R == $x) ? 3 : (($G == $x) ? 5 : 1);

	$H = 60 * ($i - $f / ($V - $x));
	$H = 0 if ($H == 360);

	return ($H, ($V - $x)/$V, $V);
}

1;
