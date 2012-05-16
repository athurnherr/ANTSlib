#======================================================================
#                    L I B C P T . P L 
#                    doc: Wed Nov 15 12:28:49 2000
#                    dlm: Fri May  9 11:40:01 2008
#                    (c) 2000 A.M. Thurnherr
#                    uE-Info: 25 31 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov 15, 2000: - created
#	May 29, 2001: - made bg/fg numeric
#	May 31, 2001: - removed dummy bg val from all arrays
#	Dec 12, 2001: - clarified format errors
#	Jun 21, 2004: - relaxed cpt file format restrictions
#			      - made cpt into a hash
#				  - totally re-written
#	Jun 25, 2004: - return good value if $z equal upper cpt table limit
#	Jun 28, 2004: - added default color model
#	Jun 30, 2004: - renamed from libGMT.pl to libCPT.pl
#	Dec  1, 2005: - BUG: roundoff error
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#   Jul 24, 2006: - modified to use $PRACTICALLY_ZERONY
#	Aug 16, 2006: - BUG: last level was returned on value < first level
#	May  9, 2008: - adapted to GMT 4.3 (see also IMPLEMENTATION NOTES
#					in [mkCPT])

#----------------------------------------------------------------------
# CPT File Parsing
#----------------------------------------------------------------------

# NB: %CPT structure assumes RGB --- if the color model is really HSV,
#	  field names are wrong.

# %CPT
#	levels				number of different color levels
#	color_model			RGB or HSV
#	@from_z				from values (z, RGB) for each level
#	@from_R
#	@from_G
#	@from_B
#	@to_z				to values (z, RGB) for each level
#	@to_R
#	@to_G
#	@to_B
#	bg_R				background vals
#	bg_G
#	bg_B
#	fg_R				foreground vals
#	fg_G
#	fg_B
#	nan_R				nan vals
#	nan_G
#	nan_B

sub readCPT($)
{
	my($f) = @_;
	my($flag,%CPT);

	for ($CPT{levels}=0; <$f>;) {
		$CPT{color_model} = $' if /^# COLOR_MODEL = /; chomp($CPT{color_model});
		s/#.*//;
		next if /^\s*$/;
		my(@f) = split;
		if ($f[0] eq 'B') {
			$CPT{bg_R} = $f[1]; $CPT{bg_G} = $f[2]; $CPT{bg_B} = $f[3];
		} elsif ($f[0] eq 'F') {
			$CPT{bg_R} = $f[1]; $CPT{bg_G} = $f[2]; $CPT{bg_B} = $f[3];
		} elsif ($f[0] eq 'N') {
			$CPT{nan_R} = $f[1]; $CPT{nan_G} = $f[2]; $CPT{nan_B} = $f[3];
		} else {
			$CPT{from_z}[$CPT{levels}] = $f[0];
			$CPT{from_R}[$CPT{levels}] = $f[1];
			$CPT{from_G}[$CPT{levels}] = $f[2];
			$CPT{from_B}[$CPT{levels}] = $f[3];
			$CPT{to_z}[$CPT{levels}] = $f[4];
			$CPT{to_R}[$CPT{levels}] = $f[5];
			$CPT{to_G}[$CPT{levels}] = $f[6];
	        $CPT{to_B}[$CPT{levels}] = $f[7];
			$CPT{levels}++;
	    }
    }
    $CPT{color_model} = 'RGB' unless defined($CPT{color_model});
    croak("$0: color model $CPT{color_model} not implemented\n")
    	unless ($CPT{color_model} =~ '\+?RGB' || $CPT{color_model} =~ '\+?HSV');
	return %CPT;
}
		
sub CPTlvl($%)
{
	my($z,%CPT) = @_;
	my($l);
	
	croak("$0: no valid CPT info\n")
		unless ($CPT{levels} > 0);

	return nan if isnan($z);

	for ($l=0; $l<$CPT{levels}; $l++) {
		return $l if ($CPT{from_z}[$l] <= $z && $z < $CPT{to_z}[$l]);
	}
	return $CPT{levels}-1
		if (abs($z-$CPT{to_z}[$CPT{levels}-1]) < $PRACTICALLY_ZERO);
	return -1 if ($z < $CPT{from_z}[0]);
	return $CPT{levels};
}

1;
