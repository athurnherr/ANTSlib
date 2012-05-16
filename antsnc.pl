#======================================================================
#                    A N T S N C . P L 
#                    doc: Mon Jul 17 11:59:37 2006
#                    dlm: Tue Jul 21 21:50:44 2009
#                    (c) 2006 A.M. Thurnherr
#                    uE-Info: 24 54 NIL 0 0 72 2 2 4 NIL ofnI
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

# NOTES:
#	- multi-valued attribs are not loaded by getInfo()
#	- spaces in NC strings are replaced by underscores
#	- data filling is disabled, because of a bug in the NetCDF library

# NetCDF Library Bug:
#	The library appears to have incorrect default _FillValue types for
#	integer data types. The error appears if the "setfill" line is commented
#	out and the following command is run:
#		listNC -ct dbk100.nc | NCode -o TEMP.nc time
#	NB: The error occurs when the 1st variable value is written, NOT when
#	    the first Q_time value is written. However, when all the Q_ fields
#		are ommitted, the error disappears.

use NetCDF;

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

	return  NetCDF::BYTE	if ($tn eq 'byte');
	return  NetCDF::CHAR	if ($tn eq 'char');
	return  NetCDF::SHORT	if ($tn eq 'short');
	return  NetCDF::LONG	if ($tn eq 'long');
	return  NetCDF::FLOAT	if ($tn eq 'float');
	return  NetCDF::DOUBLE 	if ($tn eq 'double');
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

	$NC{id} = NetCDF::open($ARGV[0],NetCDF::NOWRITE);	# open

	my($nd,$nv,$nga,$udi);								# get nelts
	NetCDF::inquire($NC{id},$nd,$nv,$nga,$udi);
	$NC{unlim_dimId} = $udi;

	for (my($d)=0; $d<$nd; $d++) {						# dimensions
		my($dnm,$ln);
		NetCDF::diminq($NC{id},$d,$dnm,$ln);
		$NC{dimName}[$d] = $dnm;
		$NC{dimId}{$dnm} = $d;
		$NC{dimLen}{$dnm} = $ln;
	}

	for (my($v)=0; $v<$nv; $v++) {						# vars & var-attribs
		my($vnm,$vtp,$nvd,$nva);
		my(@dids) = ();
		NetCDF::varinq($NC{id},$v,$vnm,$vtp,$nvd,\@dids,$nva);
		$NC{varName}[$v] = $vnm;
		$NC{varId}{$vnm} = $v;
		$NC{varType}{$vnm} = $vtp;
		@{$NC{varDimIds}{$vnm}} = @dids[0..$nvd-1];
		
		for (my($a)=0; $a<$nva; $a++) {					# var-attribs
			my($anm,$atp,$aln);
			NetCDF::attname($NC{id},$v,$a,$anm);
			$NC{varAttrName}{$vnm}[$a] = $anm;
			NetCDF::attinq($NC{id},$v,$anm,$atp,$aln);
			$NC{varAttrType}{$vnm}{$anm} = $atp;
			$NC{varAttrLen}{$vnm}{$anm} = $aln;
			if ($atp == NetCDF::BYTE || $atp == NetCDF::CHAR || $aln == 1) {
				my($val) = "";
				NetCDF::attget($NC{id},$v,$anm,\$val);
				$val =~ s{\0+$}{} if ($atp == NetCDF::CHAR);	# trailing \0
				$NC{varAttr}{$vnm}{$anm} = $val;
			}		
		}
	}

	for (my($a)=0; $a<$nga; $a++) {						#  global attribs
		my($anm,$atp,$aln);
		NetCDF::attname($NC{id},NetCDF::GLOBAL,$a,$anm);
		$NC{attrName}[$a] = $anm;
		NetCDF::attinq($NC{id},NetCDF::GLOBAL,$anm,$atp,$aln);
		$NC{attrType}{$anm} = $atp;
		$NC{attrLen}{$anm} = $aln;
		if ($atp == NetCDF::BYTE || $atp == NetCDF::CHAR || $aln == 1) {
			my($val) = "";
			NetCDF::attget($NC{id},NetCDF::GLOBAL,$anm,\$val);
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

	my($ncId) = NetCDF::create($fn,NetCDF::CLOBBER);
	NetCDF::setfill($ncId,NetCDF::NOFILL);				# NetCDF library bug

														# DIMENSIONS
	my($aid) = NetCDF::dimdef($ncId,$abscissa,NetCDF::UNLIMITED);

	for (my($f)=0; $f<=$#antsLayout; $f++) {			# types
		my($tpa) = $antsLayout[$f] . ':NC_type';
		my($sl) = ($P{$tpa} =~ m{^string(\d+)$});
		if ($sl > 0) {									# string
			$slDim[$f] = NetCDF::dimdef($ncId,"$antsLayout[$f]:strlen",$sl);
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
			$vid = NetCDF::vardef($ncId,$antsLayout[$f],$NCtype[$f],[$aid,$slDim[$f]]);
		} else {
			$vid = NetCDF::vardef($ncId,$antsLayout[$f],$NCtype[$f],[$aid]);
		}
		croak("$0: varid != fnr (implementation restriction)")
			unless ($vid == $f);
		foreach my $anm (keys(%P)) {					# variable attributes
			next unless defined($P{$anm});
			my($var,$attr) = ($anm =~ m{([^:]+):(.*)});
			next unless ($var eq $antsLayout[$f]);
			$attrDone{$anm} = 1;						# mark
			if (numberp($P{$anm}) || lc($P{$anm}) eq nan) {
				NetCDF::attput($ncId,$f,$attr,NetCDF::DOUBLE,$P{$anm});
			} else {
				NetCDF::attput($ncId,$f,$attr,NetCDF::CHAR,$P{$anm});
			}
        }		                  
	}

	unless ($suppress_params) {
		foreach my $anm (keys(%P)) {					# GLOBAL ATTRIBUTES
			next unless defined($P{$anm});
			next if ($anm eq 'FILENAME' || $anm eq 'DIRNAME' || # skip pseudo 
					 $anm eq 'BASENAME' || $anm eq 'EXTN' ||
					 $anm eq 'PATHNAME' || 
					 $anm eq 'RECNO'	|| $anm eq 'LINENO');
			next if $attrDone{$anm};
			if (numberp($P{$anm}) || lc($P{$anm}) eq nan) {
				NetCDF::attput($ncId,NetCDF::GLOBAL,$anm,NetCDF::DOUBLE,$P{$anm});
			} else {
				NetCDF::attput($ncId,NetCDF::GLOBAL,$anm,NetCDF::CHAR,$P{$anm});
			}
	    }
	}

	NetCDF::endef($ncId);

	return $ncId;
}

1;
