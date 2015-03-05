#======================================================================
#                    L I B S B E . P L 
#                    doc: Mon Nov  3 12:42:14 2014
#                    dlm: Mon Nov  3 19:35:53 2014
#                    (c) 2014 A.M. Thurnherr
#                    uE-Info: 83 13 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov  3, 2014: - exported from [importCNV]

#----------------------------------------------------------------------
# fname_SBE2std($)
#	- standardize field names (also adds correct unit %PARAMs)
#----------------------------------------------------------------------

sub fname_SBE2std($)
{
	$_ = $_[0];

	return 'lat' 		if /^lat/;
	return 'lon' 		if /^lon/;
	return 'press'		if /^prDM/;
	return 'depth'		if /^depSM/;
	return 'O2' 		if /^sbeox0/;
	return 'alt_O2' 	if /^sbeox1/;
	return 'salin' 		if /^sal00/;
	return 'alt_salin' 	if /^sal11/;
	return 'elapsed'	if /^timeS/;
	
	if (/^t090/) {											# temperatures with different scales
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
		return 'temp';
	} elsif (/^t068/) {
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
		return 'temp';
	}
		
	if (/^t190/) {
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
		return 'alt_temp';
	} elsif (/^t168/) {
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
		return 'alt_temp';
	}

	if (m{^c0S/m}) {										# conductivity with different units
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} ne 'S/m');
		&antsAddParams('cond.unit','S/m'); $P{cond.unit} = 'S/m';
		return 'cond';
	} elsif (m{^c0mS/cm}) {
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} != 'mS/cm');
		&antsAddParams('cond.unit','mS/cm'); $P{cond.unit} = 'mS/cm';
		return 'cond';
	}
		
	if (m{^c1S/m}) {
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} != 'S/m');
		&antsAddParams('cond.unit','S/m'); $P{cond.unit} = 'S/m';
		return 'alt_cond';
	} elsif (m{^c1mS/cm}) {
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} != 'mS/cm');
		&antsAddParams('cond.unit','mS/cm'); $P{cond.unit} = 'mS/cm';
		return 'alt_cond';
	}

	return $_;
}

# same as above but leaving names in place (only setting %PARAMs)
sub fname_SBE($)
{
	$_ = $_[0];

	if (/^t090/) {											# temperatures with different scales
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
	} elsif (/^t068/) {
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
	}
		
	if (/^t190/) {
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 90);
		&antsAddParams('ITS',90); $P{ITS} = 90;
	} elsif (/^t168/) {
		croak("$0: inconsistent temperature scales\n")
			if defined($P{ITS}) && ($P{ITS} != 68);
		&antsAddParams('ITS',68); $P{ITS} = 68;
	}

	if (m{^c0S/m}) {										# conductivity with different units
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} ne 'S/m');
		&antsAddParams('cond.unit','S/m'); $P{cond.unit} = 'S/m';
	} elsif (m{^c0mS/cm}) {
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} != 'mS/cm');
		&antsAddParams('cond.unit','mS/cm'); $P{cond.unit} = 'mS/cm';
	}
		
	if (m{^c1S/m}) {
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} != 'S/m');
		&antsAddParams('cond.unit','S/m'); $P{cond.unit} = 'S/m';
	} elsif (m{^c1mS/cm}) {
		croak("$0: inconsistent conductivity units\n")
			if defined($P{cond.unit}) && ($P{cond.unit} != 'mS/cm');
		&antsAddParams('cond.unit','mS/cm'); $P{cond.unit} = 'mS/cm';
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
#----------------------------------------------------------------------

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
			$antsNewLayout[$1] = $sfn ? fname_SBE2std($2) : fname_SBE($2);
			next;
		}
		    
		SBE_checkTime($1,$tc),next 							# sanity time check
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
			($deg,$min,$NS) = split(/\s+/,$');
			croak("$0: cannot decode latitude ($')\n")
				unless ($NS eq 'N' || $NS eq 'S');
			$lat = $deg + $min/60;
			$lat *= -1 if ($NS eq 'S');
			&antsAddParams('lat',$lat);
			next;
		}
		if (($hdr =~ /Longitude\s*[:=]\s*/) && !defined($lon)) {
			($deg,$min,$EW) = split(/\s+/,$');
			croak("$0: cannot decode longitude ($')\n")
				unless ($EW eq 'E' || $EW eq 'W');
			$lon = $deg + $min/60;
			$lon *= -1 if ($EW eq 'W');
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

	@antsLayout = @antsNewLayout;
	return ($nfields,$nrecs,$sampint,$badval,$ftype,$lat,$lon);
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
			for (my($f)=0; $f<$nf; $f++) {
				$add[$f] = nan if ($add[$f] == $bad);
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
					@add[$f] = $dta[$r*$nf+$f] == $bad ? nan : $dta[$r*$nf+$f];
				}
	        }
	    }
		until ($#ants_>=0 && &antsBufFull()) {					# copy next out
			return undef unless ($nextR < $nr);
			@add = $dta[$nextR*$nf..($nextR+1)*$nr+$nf];
			push(@ants_,[@add]);
			$nextR++;
        }
    } else {
		croak("$0: unknown file type $ftype\n");
    }

	return $#ants_+1;											# ok
}

} # static scope

#----------------------------------------------------------------------

1;																# return true
