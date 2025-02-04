#======================================================================
#                    L I B S B E . P L 
#                    doc: Mon Nov  3 12:42:14 2014
#                    dlm: Mon Jun 27 18:37:05 2022
#                    (c) 2014 A.M. Thurnherr
#                    uE-Info: 29 33 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov  3, 2014: - exported from [importCNV]
#	Jun 16, 2015: - cosmetics
#	Jun 17, 2015: - ensured numeric retvals of SBE_parseheader are returned as numbers
#	Jun 18, 2015: - BUG: binary code had several bugs
#	Sep 29, 2015: - added potemp and sigma standard field names
#	Mar 19, 2016: - BUG: conductivity unit checking on input had multiple bugs
#				  - solution for files with multiple conductivity units: ignore
#				    all conductivities with units not equal to the first cond var
#				  - added $libSBE_quiet to suppress diagnostic messages
#	May 31, 2016: - made successfully decoding lat/lon optional
#	Mar 10, 2017: - made lat/lon decoding more flexible
#	Mar  3, 2018: - adapted SBE37 fields (multiple changes)
#				  - added default field name for sound speed (sspd)
#	Mar  8, 2018: - BUG: SBE_parseHeader() did not correctly detect missing lat/lon
#				  - suppressed warnings in SBE_parseHeader()
#	Apr 23, 2018: - BUG: header lat/lon was incorrectly parsed when there was no space
#						 before hemisphere
#	Jan  3, 2019: - BUG: SBE_parseHeader() did not correctly detect missing lat/lon
#	Jun 27, 2022: - BUG: ASCII data files can have format anomalies (missing space) on
#						 bad data

#----------------------------------------------------------------------
# fname_SBE2std($)
#	- standardize field names (also adds correct unit %PARAMs)
#----------------------------------------------------------------------

sub fname_SBE2std($)
{
	$_ = $_[0];

	return 'lat' 		if /^lat/;
	return 'lon' 		if /^lon/;
	return 'press'		if /^pr[dD]M/;
	return 'sspd'		if /^sv[dD]M/;
	return 'depth'		if /^depSM/;
	return 'O2' 		if /^sbeox0/;
	return 'alt_O2' 	if /^sbeox1/;
	return 'salin' 		if /^sal00/;
	return 'alt_salin' 	if /^sal11/;
	return 'elapsed'	if /^timeS/;
	return 'time_jday'	if /^timeJV2/;
	return 'sigma0' 	if /^sigma.*00/;
	return 'alt_sigma0' if /^sigma.*11/;
	return 'rho0' 		if /^density00/;
	return 'alt_rho0'	if /^density11/;
	
	if (/^t090/) {											# temperatures with different scales
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
		return 'temp';
	} elsif (/^t068/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
		return 'temp';
	}
		
	if (/^t190/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
		return 'alt_temp';
	} elsif (/^t168/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
		return 'alt_temp';
	}

	if (/^potemp090/) {											# potential temperatures with different scales
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
		return 'theta0';
	} elsif (/^potemp068/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
		return 'theta0';
	}
		
	if (/^potemp190/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
		return 'alt_theta0';
	} elsif (/^potemp168/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
		return 'alt_theta0';
	}

	if (m{^c0S/m} || m{^cond0S/m}) {										# conductivity with different units
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'S/m');
		&antsAddParams('cond.unit','S/m');
		return 'cond';
	} elsif (m{^c0mS/cm} || m{^cond0mS/cm}) {
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'mS/cm');
		&antsAddParams('cond.unit','mS/cm');
		return 'cond';
	}
		
	if (m{^c1S/m} || m{^cond1S/m}) {
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'S/m');
		&antsAddParams('cond.unit','S/m');
		return 'alt_cond';
	} elsif (m{^c1mS/cm} || m{^cond1mS/cm}) {
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'mS/cm');
		&antsAddParams('cond.unit','mS/cm');
		return 'alt_cond';
	}

	return $_;
}

# same as above but leaving names in place (only setting %PARAMs)
sub fname_SBE($)
{
	$_ = $_[0];

	if (/^t090/) {											# temperatures with different scales
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
	} elsif (/^t068/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
	}
		
	if (/^t190/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
	} elsif (/^t168/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
	}

	if (/^potemp090/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
	} elsif (/^potemp068/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
	}
		
	if (/^potemp190/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
	} elsif (/^potemp168/) {
		return undef
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
	}

	if (m{^c0S/m} || m{^cond0S/m}) {										# conductivity with different units
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'S/m');
		&antsAddParams('cond.unit','S/m');
	} elsif (m{^c0mS/cm} || m{^cond0mS/cm}) {
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'mS/cm');
		&antsAddParams('cond.unit','mS/cm');
	}
		
	if (m{^c1S/m} || m{^cond1S/m}) {
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'S/m');
		&antsAddParams('cond.unit','S/m');
	} elsif (m{^c1mS/cm} || m{^cond1mS/cm}) {
		return undef
			if defined($P{'cond.unit'}) && ($P{'cond.unit'} ne 'mS/cm');
		&antsAddParams('cond.unit','mS/cm');
	}

	return $_;
}

#----------------------------------------------------------------------
# SBE_checkTime($$)
# 	- make sure all times are (roughly) the same
#----------------------------------------------------------------------

{ # static scope
	my($target_month,$target_day,$target_year,$target_time);

sub SBE_checkTime($$)
{
	return unless $_[1];
	my($mo,$dy,$yr,$tm) = split('\s+',$_[0]);

	unless (defined($target_month)) {
		$target_month = $mo;
		$target_day   = $dy;
		$target_year  = $yr;
		$target_time  = $tm;
		return;
	}

	croak("$0: inconsistent dates in header ($target_month $target_day $target_year vs $mo $dy $yr)\n")
		unless ($target_month eq $mo && $target_day == $dy && $target_year == $yr);
	croak("$0: inconsistent times in header ($target_time vs $tm)\n")
		unless (abs(frac_day(split(':',$target_time))-frac_day(split(':',$tm))) < 1/60/24);
}

} # static scope

#----------------------------------------------------------------------
# sub SBE_parseHeader(FP,std-field-names,time-check)
#	- parse header information
#	- set @ignore_input_fields with fields with inconsistent units
#----------------------------------------------------------------------

my(@ignore_input_fields);								# in reverse order!!!

sub SBE_parseHeader($$$)
{
	my($FP,$sfn,$tc) = @_;
	my($hdr,$nfields,$nrecs,$deg,$min,$NS,$EW,$lat,$lon,$sampint,$badval,$ftype);

	while (1) { 										# parse header
		chomp($hdr = <$FP>);
		$hdr =~ s/\r*$//;
		die("$0: unexpected EOF (format error)\n") unless defined($hdr);
		last if ($hdr eq '*END*');
	    
		$nfields = $',next if ($hdr =~ /nquan = /); 	# Layout
		$nrecs = $',next if ($hdr =~ /nvalues = /);
		if ($hdr =~ /name (\d+) = ([^:]+):/) {
			my($fn) = $sfn ? fname_SBE2std($2) : fname_SBE($2);
			if (defined($fn)) {
				push(@antsNewLayout,$fn);
			} else {
				unshift(@ignore_input_fields,$1);
				&antsInfo("CNV input field \#$1 ($2) ignored, because of unit inconsistency")
					unless defined($libSBE_quiet);
			}
		}
		    
		SBE_checkTime($1,$tc),next 						# sanity time check
			if ($hdr =~ /NMEA UTC \(Time\) = (.*)/);
		SBE_checkTime($1,$tc),next
			if ($hdr =~ /System UpLoad Time = (.*)/);
	
		&antsAddParams('CNV_File',$1),next				# selected metadata
			if ($hdr =~ /FileName = (.*)$/);
		SBE_checkTime($1,$tc),&antsAddParams('start_time',$1),next
			if ($hdr =~ /start_time = (.*)/);
	
		&antsAddParams('station',$1),next
			if ($hdr =~ /Station\s*:\s*(.*)/);
		&antsAddParams('ship',$1),next
			if ($hdr =~ /Ship\s*:\s*(.*)/);
		&antsAddParams('cruise',$1),next
			if ($hdr =~ /Cruise\s*:\s*(.*)/);
		&antsAddParams('time',$1),next
			if ($hdr =~ /Time\s*:\s*(.*)/);
		&antsAddParams('date',$1),next
			if ($hdr =~ /Date\s*:\s*(.*)/);
	
		if (($hdr =~ /Latitude\s*[:=]\s*/) && !defined($lat)) {
#			($deg,$min,$NS) = split(/\s+/,$');
			($deg,$min,$NS) = ($' =~ m{([^\s]+)\s+(\d+\.\d*)\s*([NS])});
			if ($NS eq 'N' || $NS eq 'S') {
				$lat = $deg + $min/60;
				$lat *= -1 if ($NS eq 'S');
			} elsif (!defined($NS) && defined($deg) && abs($deg)<=90 && ($min >= 0) && ($min <= 60)) {
				$lat = $deg + $min/60;
			} else {
#				print(STDERR "$0: WARNING: cannot decode latitude ($')\n");
				$lat = nan;
			}
			&antsAddParams('lat',$lat);
			next;
		}
		if (($hdr =~ /Longitude\s*[:=]\s*/) && !defined($lon)) {
#			($deg,$min,$EW) = split(/\s+/,$');
			($deg,$min,$EW) = ($' =~ m{([^\s]+)\s+(\d+\.\d*)\s*([EW])});
			if ($EW eq 'E' || $EW eq 'W') {
				$lon = $deg + $min/60;
				$lon *= -1 if ($EW eq 'W');
			} elsif (!defined($EW) && defined($deg) && abs($deg)<=360 && ($min >= 0) && ($min <= 60)) {
				$lon = $deg + $min/60;
			} else {
#				print(STDERR "$0: WARNING: cannot decode longitude ($')\n");
				$lon= nan;
			}
			&antsAddParams('lon',$lon);
			next;
		}
	    
		if ($hdr =~ /interval = seconds: /) {
			$sampint = 1*$';
			&antsAddParams('sampling_frequency',1/$sampint);
			next;
		}
		if ($hdr =~ /interval = decibars: /) {
			$sampint = 1*$';
			&antsAddParams('sampling_press_interval',$sampint);
			next;
		}
	    
		$badval = $',next
			if ($hdr =~ /bad_flag = /); 
		$ftype = $',next
			if ($hdr =~ /file_type = /);    
	}

	croak("$0: cannot determine file layout\n")
		unless (@antsNewLayout && defined($nfields) && defined($nrecs));
	croak("$0: cannot determine missing value\n")
	    unless defined($badval);

	$lat = nan unless defined($lat);
	$lon = nan unless defined($lon);

	@antsLayout = @antsNewLayout;
	return (1*$nfields,1*$nrecs,1*$sampint,1*$badval,$ftype,$lat,$lon);
}

#----------------------------------------------------------------------
# SBEin($$)
#	- read SBE CTD data
#----------------------------------------------------------------------

{ my(@dta); my($nextR)=0;										# static scope

sub SBEin($$$$$)
{
	my($FP,$ftype,$nf,$nr,$bad) = @_;
	my(@add);

	splice(@ants_,0,$antsBufSkip);								# shift buffers

	if ($ftype eq 'ascii') {
		until ($#ants_>=0 && &antsBufFull()) {
			return undef unless (@add = &antsFileIn($FP));
			if (@add == $nf) {
				for (my($f)=0; $f<=$nf; $f++) {
					$add[$f] = nan if ($add[$f] == $bad);
	            }
			} else {
				&antsInfo(sprintf("CNV scan#%d: bad format",$nextR+1))
					unless defined($libSBE_quiet);
				for (my($f)=0; $f<=$nf; $f++) {
					$add[$f] = nan;
	            }
			}
			foreach my $sf (@ignore_input_fields) {
				splice(@add,$sf,1);
			}
			push(@ants_,[@add]);
		}
	} elsif ($ftype eq 'binary') {
		unless (@dta) {											# read binary data once
			my($fbits) = 8 * length(pack('f',0));
			croak(sprintf("$0: incompatible native CPU float representation (%d instead of 32bits)\n",fbits))
				unless ($fbits == 32);  
			my($dta);
			croak("$0: can't read binary data\n")
				unless (read($FP,$dta,4*$nf*$nr) == 4*$nf*$nr);
			print(STDERR "WARNING: extraneous data at EOF\n")
				unless eof($FP);
			$dta = pack('V*',unpack('N*',$dta)) 				# big-endian CPU
				if (unpack('h*', pack('s', 1)) =~ /01/);		# c.f. perlport(1)
			@dta = unpack("f*",$dta);
			for ($r=0; $r<$nr; $r++) {
				for ($f=0; $f<$nf; $f++) {
					$dta[$r*$nf+$f] = nan if ($dta[$r*$nf+$f] == $bad);
				}
	        }
	    }
		until ($#ants_>=0 && &antsBufFull()) {					# copy next out
			return undef unless ($nextR < $nr);
			@add = @dta[$nextR*$nf..($nextR+1)*$nf-1];
			foreach my $sf (@ignore_input_fields) {
				splice(@add,$sf,1);
			}
			push(@ants_,[@add]);
        }
    } else {
		croak("$0: unknown file type $ftype\n");
    }

	$nextR++;
	return $#ants_+1;											# ok
}

} # static scope

#----------------------------------------------------------------------

1;																# return true
