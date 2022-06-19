#======================================================================
#                    A N T S N C . P L 
#                    doc: Mon Jul 17 11:59:37 2006
#                    dlm: Sat Jun 18 20:28:20 2022
#                    (c) 2006 A.M. Thurnherr
#                    uE-Info: 32 29 NIL 0 0 70 0 2 4 NIL ofnI
#======================================================================

# ANTS netcdf library

# HISTORY:
#	Jul 17, 2006: - created
#	Jul 21, 2006: - documented
#				  - added NC-encoding routines
#	Jul 22: 2006: - BUG: pseudo %PARAMs were written as well
#				  -	BUG: var ATTRs were not enconded correctly
#				  - added type support
#	Jul 23, 2006: - improved type magic
#	Sep  1, 2006: - BUG: removing trainling 0s had not worked
#	Sep 23, 2006: - fiddled
#	Jul 11, 2008: - adapted to new pseudo %PARAMs
#	Jul 16, 2008: - remove \0s from strings in NC_stringify
#	Mar 20, 2008: - added progress output to NC_stringify
#	Jul 21, 2009: - allowed for suppression of %PARAMs
#	Jan 15, 2016: - BUG: %DEPS pseudo-%PARAM was encoded
#	Apr  5, 2022: - added NC_writeMDataMulti()
#				  - implemented disappeared NetCDF::DOUBLE etc.
#				  - enabled fill value handling (library bug has gone away)
#	Apr 22, 2022: - added "_coordinate" to abscissa dimension to
#					allow reading with python xr
#	Jun 18, 2022: - found better earlier solution for NetCDF::DOUBLE etc. 
#					on laptop
# HISTORY END

# NOTES:
#	- multi-valued attribs are not loaded by getInfo()
#	- spaces in NC strings are replaced by underscores

# NetCDF Library Bug: NO LONGER ACTIVE AS OF APR 2022
#	The library appears to have incorrect default _FillValue types for
#	integer data types. The error appears if the "setfill" line is commented
#	out and the following command is run:
#		listNC -ct dbk100.nc | NCode -o TEMP.nc time
#	NB: The error occurs when the 1st variable value is written, NOT when
#	    the first Q_time value is written. However, when all the Q_ fields
#		are ommitted, the error disappears.

use NetCDF;

#----------------------------------------------------------------------
# NetCDF Constants
#	- in April 2022 I encoded these constants from .h file
#	- in June 2022 I found a more general earlier solution on my laptop
#----------------------------------------------------------------------

sub NetCDF::NAT 		 { return NetCDF::constant(NAT,0); }
sub NetCDF::BYTE		 { return NetCDF::constant(BYTE,0); }
sub NetCDF::CHAR		 { return NetCDF::constant(CHAR,0); }
sub NetCDF::SHORT		 { return NetCDF::constant(SHORT,0); }
sub NetCDF::INT 		 { return NetCDF::constant(INT,0); }
sub NetCDF::LONG		 { return NetCDF::constant(LONG,0); }
sub NetCDF::FLOAT		 { return NetCDF::constant(FLOAT,0); }
sub NetCDF::DOUBLE		 { return NetCDF::constant(DOUBLE,0); }
sub NetCDF::UBYTE		 { return NetCDF::constant(UBYTE,0); }
sub NetCDF::USHORT		 { return NetCDF::constant(USHORT,0); }
sub NetCDF::UINT		 { return NetCDF::constant(UINT,0); }
sub NetCDF::INT64		 { return NetCDF::constant(INT64,0); }
sub NetCDF::UINT64		 { return NetCDF::constant(UINT64,0); }
sub NetCDF::STRING		 { return NetCDF::constant(STRING,0); }

sub NetCDF::FILL_BYTE		 { return NetCDF::constant(FILL_BYTE,0); }
sub NetCDF::FILL_CHAR		 { return NetCDF::constant(FILL_CHAR,0); }
sub NetCDF::FILL_SHORT		 { return NetCDF::constant(FILL_SHORT,0); }
sub NetCDF::FILL_INT		 { return NetCDF::constant(FILL_INT,0); }
sub NetCDF::FILL_LONG		 { return NetCDF::constant(FILL_LONG,0); }
sub NetCDF::FILL_FLOAT		 { return NetCDF::constant(FILL_FLOAT,0)+36; }
sub NetCDF::FILL_DOUBLE 	 { return NetCDF::constant(FILL_DOUBLE,0)+36; }
sub NetCDF::FILL_UBYTE		 { return NetCDF::constant(FILL_UBYTE,0); }
sub NetCDF::FILL_USHORT 	 { return NetCDF::constant(FILL_USHORT,0); }
sub NetCDF::FILL_UINT		 { return NetCDF::constant(FILL_UINT,0); }
sub NetCDF::FILL_INT64		 { return NetCDF::constant(FILL_INT64,0); }
sub NetCDF::FILL_UINT64 	 { return NetCDF::constant(FILL_UINT64,0); }
sub NetCDF::FILL_STRING 	 { return NetCDF::constant(FILL_STRING,0); }

sub NetCDF::NOWRITE 	 { return NetCDF::constant(NOWRITE,0); }
sub NetCDF::CLOBBER 	 { return NetCDF::constant(CLOBBER,0); }
sub NetCDF::NOFILL		 { return NetCDF::constant(NOFILL,0); }
sub NetCDF::GLOBAL		 { return NetCDF::constant(GLOBAL,0); }
sub NetCDF::UNLIMITED	 { return NetCDF::constant(UNLIMITED,0); }

if (0) {
	sub NetCDF::NAT 		 { return 0; }
	sub NetCDF::BYTE		 { return 1; }
	sub NetCDF::CHAR		 { return 2; }
	sub NetCDF::SHORT		 { return 3; }
	sub NetCDF::INT 		 { return 4; }
	sub NetCDF::LONG		 { return 4; }
	sub NetCDF::FLOAT		 { return 5; }
	sub NetCDF::DOUBLE		 { return 6; }
	sub NetCDF::UBYTE		 { return 7; }
	sub NetCDF::USHORT		 { return 8; }
	sub NetCDF::UINT		 { return 9; }
	sub NetCDF::INT64		 { return 10; }
	sub NetCDF::UINT64		 { return 11; }
	sub NetCDF::STRING		 { return 12; }
	
	sub NetCDF::FILL_BYTE		 { return -127; }
	sub NetCDF::FILL_CHAR		 { return "\0"; }
	sub NetCDF::FILL_SHORT		 { return -32767; }
	sub NetCDF::FILL_INT		 { return -2147483647; }
	sub NetCDF::FILL_LONG		 { return -2147483647; }
	sub NetCDF::FILL_FLOAT		 { return 9.9692099683868690e+36; }
	sub NetCDF::FILL_DOUBLE 	 { return 9.9692099683868690e+36; }
	sub NetCDF::FILL_UBYTE		 { return 255; }
	sub NetCDF::FILL_USHORT 	 { return 65535; }
	sub NetCDF::FILL_UINT		 { return 4294967295; }
	sub NetCDF::FILL_INT64		 { return -9223372036854775806; }
	sub NetCDF::FILL_UINT64 	 { return 18446744073709551614; }
	sub NetCDF::FILL_STRING 	 { return ''; }
	
	sub NetCDF::NOWRITE 	 { return 0x0000; }
	sub NetCDF::CLOBBER 	 { return 0x0000; }
	sub NetCDF::NOFILL		 { return 0x100; }
	sub NetCDF::GLOBAL		 { return -1; }
	sub NetCDF::UNLIMITED    { return 0; }
}


#----------------------------------
# string representation of NC types
#----------------------------------

sub NC_typeName($)
{
	my($tp) = @_;

	return 'byte'	if ($tp == NetCDF::BYTE);
	return 'char'	if ($tp == NetCDF::CHAR);
	return 'short'	if ($tp == NetCDF::SHORT);
	return 'long'	if ($tp == NetCDF::LONG);
	return 'float'	if ($tp == NetCDF::FLOAT);
	return 'double' if ($tp == NetCDF::DOUBLE);
	croak("$0: unknown NetCDF type #$tp\n");
}

sub NC_type($)
{
	my($tn) = lc($_[0]);

	return	NetCDF::BYTE	if ($tn eq 'byte');
	return	NetCDF::CHAR	if ($tn eq 'char');
	return	NetCDF::SHORT	if ($tn eq 'short');
	return	NetCDF::LONG	if ($tn eq 'long');
	return	NetCDF::FLOAT	if ($tn eq 'float');
	return	NetCDF::DOUBLE	if ($tn eq 'double');
	croak("$0: unknown NetCDF type <$tn>\n");
}

#--------------------------------------
# test whether given NC type is numeric
#--------------------------------------

sub NC_isNumeric($)
{
	my($tp) = @_;

	return 1 if ($tp == NetCDF::BYTE);
	return 1 if ($tp == NetCDF::SHORT);
	return 1 if ($tp == NetCDF::LONG);
	return 1 if ($tp == NetCDF::FLOAT);
	return 1 if ($tp == NetCDF::DOUBLE);
	return 0;
}

#----------------------------------------
# test whether given NC type is character
#----------------------------------------

sub NC_isChar($)
{
	return $_[0] == NetCDF::CHAR;
}

#-----------------------------------
# convert character- to string array
#-----------------------------------

sub NC_stringify($@)
{
	my($len,@chars) = @_;
	my(@strings);
	my($nStrings) = @chars/$len;

	print(STDERR "$0: extracting $nStrings strings")
		if ($nStrings > 1000);

	while (@chars) {
		print(STDERR ".") if ($nStrings>1000 && $n++%1000 == 0);
		push(@strings,pack("c$len",@chars));
		$strings[$#strings] =~ s/ /_/g;
		$strings[$#strings] =~ s/\0//g;
		splice(@chars,0,$len);
	}
	print(STDERR "\n") if ($nStrings > 1000);
	return @strings;
}

#----------------------------------------------------------------------
# open netcdf file and read (most) metadata into hash
#
#	INPUT:
#		<filename>
#
#	OUTPUT:
#		$NC{id}								netcdf id
#
#		@NC{attrName}[]						names of global attrs
#		%NC{AttrType}{$aName}				types of global attrs
#		%NC{AttrLen}{$aName}				# of elts in global attrs
#		%NC{Attr}{$aName}					vals of scalar global attrs
#
#		$NC{unlim_dimId}					dim id of unlimited dim
#		@NC{dimName}[$dimId]				dim names
#		%NC{dimID}{$dName}					dim ids
#		%NC{dimLen}{$dName}					# elts in dim
#
#		@NC{varName}[$varId]				var names
#		%NC{varType}{$vName}				var types
#		%NC{varId}{$vName}					var ids
#		@%NC{varDimIDs}{$vName}[]			dims of vars, e.g. u(lon,lat)
#		@%NC{varAttrName}{$vName}[]			names of var attrs
#		%%NC{varAttrType}{$vName}{$aName}	types of var attrs
#		%%NC{varAttrLen}{$vName}{$aName}	# of elts in var attrs
#		%%NC{varAttr}{$vName}{$aName}		vals of scalar var attrs
#
#----------------------------------------------------------------------

sub NC_readMData($)
{
	my($fn) = @_;
	my(%NC);

	$NC{id} = NetCDF::ncopen($ARGV[0],NetCDF::NOWRITE);	# open

	my($nd,$nv,$nga,$udi);								# get nelts
	NetCDF::ncinquire($NC{id},$nd,$nv,$nga,$udi);
	$NC{unlim_dimId} = $udi;

	for (my($d)=0; $d<$nd; $d++) {						# dimensions
		my($dnm,$ln);
		NetCDF::ncdiminq($NC{id},$d,$dnm,$ln);
		$NC{dimName}[$d] = $dnm;
		$NC{dimId}{$dnm} = $d;
		$NC{dimLen}{$dnm} = $ln;
	}

	for (my($v)=0; $v<$nv; $v++) {						# vars & var-attribs
		my($vnm,$vtp,$nvd,$nva);
		my(@dids) = ();
		NetCDF::ncvarinq($NC{id},$v,$vnm,$vtp,$nvd,\@dids,$nva);
		$NC{varName}[$v] = $vnm;
		$NC{varId}{$vnm} = $v;
		$NC{varType}{$vnm} = $vtp;
		@{$NC{varDimIds}{$vnm}} = @dids[0..$nvd-1];
		
		for (my($a)=0; $a<$nva; $a++) {					# var-attribs
			my($anm,$atp,$aln);
			NetCDF::ncattname($NC{id},$v,$a,$anm);
			$NC{varAttrName}{$vnm}[$a] = $anm;
			NetCDF::ncattinq($NC{id},$v,$anm,$atp,$aln);
			$NC{varAttrType}{$vnm}{$anm} = $atp;
			$NC{varAttrLen}{$vnm}{$anm} = $aln;
			if ($atp == NetCDF::BYTE || $atp == NetCDF::CHAR || $aln == 1) {
				my($val) = "";
				NetCDF::ncattget($NC{id},$v,$anm,\$val);
				$val =~ s{\0+$}{} if ($atp == NetCDF::CHAR);	# trailing \0
				$NC{varAttr}{$vnm}{$anm} = $val;
			}		
		}
	}

	for (my($a)=0; $a<$nga; $a++) {						#  global attribs
		my($anm,$atp,$aln);
		NetCDF::ncattname($NC{id},NetCDF::GLOBAL,$a,$anm);
		$NC{attrName}[$a] = $anm;
		NetCDF::ncattinq($NC{id},NetCDF::GLOBAL,$anm,$atp,$aln);
		$NC{attrType}{$anm} = $atp;
		$NC{attrLen}{$anm} = $aln;
		if ($atp == NetCDF::BYTE || $atp == NetCDF::CHAR || $aln == 1) {
			my($val) = "";
			NetCDF::ncattget($NC{id},NetCDF::GLOBAL,$anm,\$val);
			$val =~ s{\0+$}{} if ($atp == NetCDF::CHAR);
			$NC{attr}{$anm} = $val;
		}	    
    }
	
	return %NC;
}

#----------------------------------------------------------------------
# create new nc file and write metadata
#
#	INPUT:
#		<filename>
#		<abscissa>			name of unlimited dimension
#		<suppress-params>	if true, don't write %PARAMs
#
#	OUTPUT:
#		<netcdf id>
#
#	NOTES:
#		- netcdf types can be set with %<var>:NC_type to
#			byte, long, short, double
#		- string types are as in old PASCAL convention (e.g. string80)
#		- default type is NetCDF::DOUBLE
#		- %<var>:NC_type are not added to ATTRIBs
#----------------------------------------------------------------------

sub NC_writeMData($$$)
{
	my($fn,$abscissa,$suppress_params) = @_;
	my(%attrDone,@slDim,@NCtype);

	my($ncId) = NetCDF::nccreate($fn,NetCDF::CLOBBER);
#	NetCDF::ncsetfill($ncId,NetCDF::NOFILL);			# NetCDF library bug

														# DIMENSIONS
	my($aid) = NetCDF::ncdimdef($ncId,$abscissa . '_coordinate',NetCDF::UNLIMITED);

	for (my($f)=0; $f<=$#antsLayout; $f++) {			# types
		my($tpa) = $antsLayout[$f] . ':NC_type';
		my($sl) = ($P{$tpa} =~ m{^string(\d+)$});
		if ($sl > 0) {									# string
			$slDim[$f] = NetCDF::ncdimdef($ncId,"$antsLayout[$f]:strlen",$sl);
			$NCtype[$f] = NetCDF::CHAR;
		} elsif (defined($P{$tpa})) {					# custom
			$NCtype[$f] = NC_type($P{$tpa});
		} else {										# default
			$NCtype[$f] = NetCDF::DOUBLE;
		}
#		printf(STDERR "type %s set to %s\n",$antsLayout[$f],NC_typeName($NCtype[$f]));
		undef($P{$tpa});								# do not add to ATTRIBs
    }

	for (my($f)=0; $f<=$#antsLayout; $f++) {			# VARIABLES
		my($vid);
		if (defined($slDim[$f])) {
			$vid = NetCDF::ncvardef($ncId,$antsLayout[$f],$NCtype[$f],[$aid,$slDim[$f]]);
		} else {
			$vid = NetCDF::ncvardef($ncId,$antsLayout[$f],$NCtype[$f],[$aid]);
		}
		croak("$0: varid != fnr (implementation restriction)")
			unless ($vid == $f);
		foreach my $anm (keys(%P)) {					# VARIABLE ATTRIBUTES
			next unless defined($P{$anm});
			my($var,$attr) = ($anm =~ m{([^:]+):(.*)});
			next unless ($var eq $antsLayout[$f]);
			$attrDone{$anm} = 1;						# mark
			if (numberp($P{$anm}) || lc($P{$anm}) eq nan) {
				NetCDF::ncattput($ncId,$f,$attr,NetCDF::DOUBLE,$P{$anm});
			} else {
				NetCDF::ncattput($ncId,$f,$attr,NetCDF::CHAR,$P{$anm});
			}
        }		                  
	}

	unless ($suppress_params) {
		foreach my $anm (keys(%P)) {					# GLOBAL ATTRIBUTES
			next unless defined($P{$anm});
			next if ($anm eq 'FILENAME' || $anm eq 'DIRNAME' || # skip pseudo 
					 $anm eq 'BASENAME' || $anm eq 'EXTN' ||
					 $anm eq 'PATHNAME' || $anm eq 'DEPS' ||
					 $anm eq 'RECNO'	|| $anm eq 'LINENO');
			next if $attrDone{$anm};
			if (numberp($P{$anm}) || lc($P{$anm}) eq nan) {
				NetCDF::ncattput($ncId,NetCDF::GLOBAL,$anm,NetCDF::DOUBLE,$P{$anm});
			} else {
				NetCDF::ncattput($ncId,NetCDF::GLOBAL,$anm,NetCDF::CHAR,$P{$anm});
			}
	    }
	}

	NetCDF::ncendef($ncId);

	return $ncId;
}

#----------------------------------------------------------------------
# create new nc "multi" file and write metadata
#
#	INPUT:
#		<filename>
#		<abscissa>			name of unlimited dimension
#		<suppress-params>	flag to suppress params
#		<file-id>			name of dimension enumerating input files (e.g. profile_number, cruise_id, etc.)
#		<n-files>			number of 1-D files to encode in multi file
#
#	OUTPUT:
#		<netcdf id>
#		%nc_vid				netcdf variable ids for %PARAMs
#		%nc_varAttr			flags for variable (not global) attributes
#
#	NOTES:
#		- netcdf types can be set with %<var|param>:NC_type to
#			byte, chat, long, short, double, float (NC_type())
#			- don't use same-named var and param with different types...
#		- string types are as in old PASCAL convention (e.g. string80)
#		- default type is NetCDF::DOUBLE; other types must be set
#		  explicitly
#		- %<var>:NC_type are not added to ATTRIBs
#----------------------------------------------------------------------

sub NC_writeMDataMulti($$$$)
{
	my($fn,$abscissa,$suppress_params,$file_id,$n_files) = @_;
	my(@slDim,@NCtype);

	my($ncId) = NetCDF::nccreate($fn,NetCDF::CLOBBER);
																				# DIMENSIONS
	my($aid) = NetCDF::ncdimdef($ncId,$abscissa . '_coordinate',NetCDF::UNLIMITED);
	my($mid) = NetCDF::ncdimdef($ncId,$file_id,$n_files);

	for (my($f)=0; $f<=$#antsLayout; $f++) {									# TYPES
		my($tpa) = $antsLayout[$f] . ':NC_type';								# defined explicitly
		my($sl) = ($P{$tpa} =~ m{^string(\d+)$});
		if ($sl > 0) {															# string
			$slDim[$f] = NetCDF::ncdimdef($ncId,"$antsLayout[$f]:strlen",$sl);
			$NCtype[$f] = NetCDF::CHAR;
		} elsif (defined($P{$tpa})) {											# other custom type 
			$NCtype[$f] = NC_type($P{$tpa});
		} else {																# default type
			$NCtype[$f] = NetCDF::DOUBLE;
		}
#		printf(STDERR "type %s set to %s\n",$antsLayout[$f],NC_typeName($NCtype[$f]));
		undef($P{$tpa});														# do not add to ATTRIBs
    }

	for (my($f)=0; $f<=$#antsLayout; $f++) {									# VARIABLES
		my($vid);
		if (defined($slDim[$f])) {
			$vid = NetCDF::ncvardef($ncId,$antsLayout[$f],$NCtype[$f],[$aid,$mid,$slDim[$f]]);
		} else {
			$vid = NetCDF::ncvardef($ncId,$antsLayout[$f],$NCtype[$f],[$aid,$mid]);
		}
		croak("$0: varid != fnr (implementation restriction)")
			unless ($vid == $f);
		foreach my $anm (keys(%P)) {											# VARIABLE ATTRIBUTES
			next unless defined($P{$anm});
			my($var,$attr) = ($anm =~ m{([^:]+):(.*)});
			next unless ($var eq $antsLayout[$f]);
			$nc_varAttr{$anm} = 1;												# mark as done
			if (numberp($P{$anm}) || lc($P{$anm}) eq nan) {
				NetCDF::ncattput($ncId,$f,$attr,NetCDF::DOUBLE,$P{$anm});
			} else {
				NetCDF::ncattput($ncId,$f,$attr,NetCDF::CHAR,$P{$anm});
			}
        }		                  
	}

	unless ($suppress_params) {													# PARAM vectors
		foreach my $anm (keys(%P)) {
			next if ($anm eq 'FILENAME' || $anm eq 'DIRNAME' || 				# skip pseudo %PARAMs
					 $anm eq 'BASENAME' || $anm eq 'EXTN' ||
					 $anm eq 'PATHNAME' || $anm eq 'DEPS' ||
					 $anm eq 'RECNO'	|| $anm eq 'LINENO');
			next if $nc_varAttr{$anm};											# variable attribute (done already)
			next if ($anm =~ /:NC_type$/);										# this is needed to remove the :NC_type params!?

			my($tpa) = $anm . ':NC_type';										# defined explicitly
			my($sl) = ($P{$tpa} =~ m{^string(\d+)$});
			if ($sl > 0) {														# string
				$slDim{$anm} = NetCDF::ncdimdef($ncId,"$anm:strlen",$sl);
				$NCtype{$anm} = NetCDF::CHAR;
			} elsif (defined($P{$tpa})) {										# other custom type 
				$NCtype{$anm} = NC_type($P{$tpa});
			} else {
				$NCtype{$anm} = NetCDF::DOUBLE;										# not a NC type %PARAM
			}
			if (defined($slDim{$anm})) {										# string type
				$nc_vid{$anm} = NetCDF::ncvardef($ncId,$anm,$NCtype{$anm},[$mid,$slDim{$anm}]);
			} else {															# other type
				$nc_vid{$anm} = NetCDF::ncvardef($ncId,$anm,$NCtype{$anm},[$mid]);
			}
	    }
	}

	NetCDF::ncendef($ncId);

	return $ncId;
}

1;
