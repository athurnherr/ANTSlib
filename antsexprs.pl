#======================================================================
#                    A N T S E X P R S . P L 
#					 (c) 2005 Andreas Thurnherr
#                    doc: Sat Dec 31 18:35:33 2005
#                    dlm: Tue Sep 19 15:16:26 2023
#                    uE-Info: 47 63 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Dec 31, 2005: - extracted from [list]
#	Jan  2, 2006: - re-written to use anonymous funs instead of eval()
#	Jan  3, 2006: - added $DEBUG
#	Jan  4, 2006: - removed NaN_handling_out
#	Jan  9, 2006: - made $bufvar param to antsCompileExpr optional
#	Jan 13, 2006: - separated AddrExpr from EditExpr
#				  - implemented abbreviated addr exprs
#	Jan 14, 2006: - added old -G syntax to -S
#	Jan 17, 2006: - BUG: $1, $2, did not work in abbrevs
#	Jan 31, 2006: - added de-octalization code for abbrevs
#	Apr 11, 2006: - added ,-separated list (again?)
#	May 18, 2006: - fiddled
#	Jun 20, 2006: - simplified regexprs; fields can now begin with _
#   Jul  1, 2006: - Version 3.3 [HISTORY]
#	Jul 24, 2006: - BUG: $$ did not work as advertised
#	Dec 11, 2006: - BUG: 1e-3 was not recognized as a valid number in
#						 abbreviations
#	Dec  1, 2007: - improved to allow -S%PARAM:... (mainly for %RECNO)
#	Jan 20, 2007: - pointless debugging (BUGs in [fnr] [list])
#	Mar 26, 2008: - BUG: . were not allowed in field names
#	Mar 27, 2008: - added &antsCompileConstExpr()
#	Mar 28, 2008: - made compile funs bomb on undefined %PARAMs
#	Aug 27, 2008: - generate error on list(1)-specific address expressions
#	Oct 12, 2008: - BUG: -S%RECNO%%6==1 did not work because %-escape magic
#						 word continued RECNO word to form undefined PARAM
#						 name. Solution: begin/end escape magic words for %
#					     and $ with a space (nonword character)
#	Oct  5, 2009: - improved documentation
#				  - added $antsEditExprUsesFields flag
#	Dec 10, 2009: - BUG: debug output had been wrong for ConstExprs
#				  - modified semantics to allow for : in param names
#	May 21, 2011: - added support for $antsFnrNegativeOk
#	May 22, 2011: - made it work
#	Feb 20, 2012: - BUG: quoting had not been implemented
#	Mar 10, 2012: - added ${field..field} syntax to edit exprs
#	May 15, 2015: - BUG: -S did not work with :: %PARAMs
#	Mar  9, 2017: - removed perl 5.22 warning about re (non-quoted braces)
#	Sep 19, 2023: - BUG: %params did not allow :: in their name

$DEBUG = 0;

#----------------------------------------------------------------------
# Address Expressions
#	- return value indicates whether current record matches
# 	- any valid PERL expression can be an addr expr
# 	- $id are assumed to be fields (use $$id for perl vars)
# 	- %id are assumed to be PARAMs (use %% to get %)
# 	- ABBREVIATIONS:
#		- id1 relop id2 becomes numberp(id1) && numberp(id2) && $id1 relop $id2
#		- id1 relop id2 relop id3 is analogous
#		- id? can only be restricted field name ([\w\.] chars and, possibly, leading %)
#		- non-perl relops ~=, <> become !=
#----------------------------------------------------------------------

sub antsCompileAddrExpr($)								# subst fields/%PARAMs
{
	my($expr,$bufVar) = @_;
	$bufVar = '$ants_[0]' unless (length($bufVar) > 0);

	#---------------------
	# handle abbreviations
	#---------------------
	print(STDERR "IN  AddrExpr = $expr\n") if ($DEBUG);

	goto QUOTED_ADDR_EXPR
		if ((substr($expr,0,1) eq "'" || substr($expr,0,1) eq '"') &&
		    (substr($expr,0,1) eq substr($expr,-1)));

	# NB: update following code if -S extensions in [list] change
	croak("$0: unsupported list(1)-specific address expression <$expr>\n")
		if ($expr =~ /^\$?([\w\.]+)\s*~(([nN][aA][nN])|(([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?))/ ||
			$expr =~ /^\$?([\w\.]+)\s*<$/ ||
			$expr =~ /^<\$?([\w\.]+)$/ ||
			$expr =~ /^\$?([\w\.]+)\s*>$/ ||
			$expr =~ /^>\$?([\w\.]+)$/);

	$expr =~ s/::/QquOte/g;										# new-style :: %PARAMs
	if ($expr =~ /^(%?[\w\.]+):/ || $expr =~ /^(\$\d+):/) {		# old -G syntax
		my($fname) = $1; my($range) = $';
		$fname =~ s/QquOte/::/g;
		if ($range =~ /(.*)\.\.(.*)/) {
			my($min) = ($1 eq '*') ? -1e99 : $1;
			my($max) = ($2 eq '*') ?  1e99 : $2;
			croak("$0: illegal addr-expr $expr\n")
				unless ((numberp($min) || $min =~ /^%/) &&
						(numberp($max) || $max =~ /^%/));
			$expr = "$min<=$fname<=$max";
		} else {
			if ($range eq '*') {
				$expr = "numberp(\$$fname)";
			} else {
				my(@vl) = split(/,/,$range);
				$vl[0] = str2num($vl[0]);
				if (numberp($vl[0]) || $vl[0] =~ /^%/) {
					$expr = "\$$fname==$vl[0]";
				} else {
					$expr = "\$$fname=~/$vl[0]/";
				}
				for (my($vi)=1; $vi<=$#vl; $vi++) {
					$vl[$vi] = str2num($vl[$vi]);
					if (numberp($vl[$vi]) || $vl[$vi] =~ /^%/) {
						$expr .= "||\$$fname==$vl[$vi]";
					} else {
						$expr .= "||\$$fname=~/$vl[$vi]/";
	                }
				}
			}
		}
		print(STDERR "-G  AddrExpr = $expr\n") if ($DEBUG);
	}
	$expr =~ s/QquOte/::/g;

	my($relop) 	  = '<|<=|>|>=|!=|~=|<>|==';		# relational ops
	my($comparee) = '-?%?\$?[\w:\.\+\-]+';			# nums, fields, PARAMs
	my($numvar)	  = '^[\w\.]+$';					# fields

	if ($expr =~ /^($comparee)\s*($relop)\s*($comparee)$/) {
		my($c1) = $1; my($c2) = $3; my($ro) = $2;
		$c1 =~ s/^0*(\d)/\1/; $c2 =~ s/^0*(\d)/\1/;	# de-octalize
		$ro = '!=' if ($ro eq '<>' || $ro eq '~=');
		$expr = '';
		if (!numberp($c1) && $c1 =~ /$numvar/) {
			$c1 = "\$$c1";
			$expr .= "numberp($c1) && ";
		}
		if (!numberp($c2) && $c2 =~ /$numvar/) {
			$c2 = "\$$c2";
			$expr .= "numberp($c2) && ";
		}
		$expr .= "($c1 $ro $c2)";
	}

	elsif ($expr =~ /^($comparee)\s*($relop)\s*($comparee)\s*($relop)\s*($comparee)$/) {
		my($c1) = $1; my($c2) = $3; my($c3) = $5; my($ro1) = $2; my($ro2) = $4;
		$c1 =~ s/^0*(\d)/\1/; $c2 =~ s/^0*(\d)/\1/;	$c3 =~ s/^0*(\d)/\1/;
		$ro1 = '!=' if ($ro1 eq '<>' || $ro1 eq '~=');
		$ro2 = '!=' if ($ro2 eq '<>' || $ro2 eq '~=');
		$expr = '';
		if (!numberp($c1) && $c1 =~ /$numvar/) {
			$c1 = "\$$c1";
			$expr .= "numberp($c1) && ";
		}
		if (!numberp($c2) && $c2 =~ /$numvar/) {
			$c2 = "\$$c2";
			$expr .= "numberp($c2) && ";
		}
		if (!numberp($c3) && $c3 =~ /$numvar/) {
			$c3 = "\$$c3";
			$expr .= "numberp($c3) && ";
		}
		$expr .= "($c1 $ro1 $c2) && ($c2 $ro2 $c3)";
	}

	#-----------------------------------
	# substitute ANTS fields and %PARAMs
	#-----------------------------------
	print(STDERR "MID AddrExpr = $expr\n") if ($DEBUG);
	$expr =~ s{\$%}{%}g;								# allow for $%param
	$expr =~ s{\$\$}{ AnTsDoLlAr }g;					# escape
	while ($expr =~ /\$\{([^}]*)\}/) {					# ${field}
		my($fnr) = cardinalp($1) ? $1-1 : fnr($1);
		croak("$0: unknown field $1\n") unless ($fnr >= 0);
		$expr =~ s(\${$1})(AnTsDtArEf\[$fnr\]);
	}
	while ($expr =~ /\$([\w\.]+)/) {					# $field
		my($fnr) = cardinalp($1) ? $1-1 : fnr($1);
		croak("$0: unknown field $1\n") unless ($fnr >= 0);
		$expr =~ s{\$$1}{AnTsDtArEf\[$fnr\]};
	}
	while ($expr =~ /\$\+([\w\.]+)/) {					# $+field
		my($fnr) = cardinalp($1) ? $1-1 : fnr($1);
		croak("$0: unknown field $1\n") unless ($fnr >= 0);
		$expr =~ s{\$\+$1}{(AnTsDtArEf\[$fnr\]-AnTsDtArEf0\[$fnr\])};
	}
	$expr =~ s{%%}{ AnTsPeRcEnT }g;						# escape
	while ($expr =~ /%([\w\.:]+)/) {					# %PARAMs
		my($p) = $1;
		croak("$0: Undefined PARAM %$p\n")
			unless defined($P{$p});
		$expr =~ s{%$p}{\$P\{'$p'\}};
    }
	$expr =~ s{AnTsDtArEf}{$bufVar}g;
	$expr =~ s{ AnTsPeRcEnT} {%}g;
	$expr =~ s{ AnTsDoLlAr }{\$}g;

	#--------------------
	# compile and return
	#--------------------
QUOTED_ADDR_EXPR:
	print(STDERR "OUT AddrExpr = $expr\n") if ($DEBUG);
#    my($subR) = eval("sub { print(STDERR \"$P{'LADCPproc::max_depth'}/$in[1]\n\"); return $expr };");
    my($subR) = eval("sub { return $expr };");
	print(STDERR "sub { return $expr };\n") if ($DEBUG);
    croak("sub { return $expr }; => $@\n") if ($@);
    return $subR;
}

#----------------------------------------------------------------------
# Edit Expressions
#	- execute calculation based on and/or modify current record
# 	- any valid PERL expression can be an edit expr
# 	- $id are assumed to be fields (use $$id for perl vars)
# 	- %id are assumed to be PARAMs (use %% to get %)
#	- ${field} are fields
#	- ${field..field} are field ranges
#----------------------------------------------------------------------

$antsEditExprUsesFields;								# flag

sub antsCompileEditExpr($)								# subst fields/%PARAMs
{
	my($expr,$bufVar) = @_;
	$bufVar = '$ants_[0]' unless defined($bufVar);
	$antsEditExprUsesFields = 0;

	print(STDERR "IN  EditExpr = $expr\n") if ($DEBUG);
	goto QUOTED_EDIT_EXPR
		if ((substr($expr,0,1) eq "'" || substr($expr,0,1) eq '"') &&
		    (substr($expr,0,1) eq substr($expr,-1)));

	$expr =~ s{\$%}{%}g;								# allow for $%param
	$expr =~ s{\$\$}{AnTsDoLlAr}g;						# escape
	while ($expr =~ /\$\{([^}]*)\.\.([^}]*)\}/) {			# ${field..field}
		$antsEditExprUsesFields |= 1;
		my($ffnr) = cardinalp($1) ? $1-1 : fnr($1);
		croak("$0: unknown field $1\n") unless ($ffnr >= 0);
		my($lfnr) = cardinalp($2) ? $2-1 : fnr($2);
		croak("$0: unknown field $2\n") unless ($lfnr >= 0);
		croak("$0: empty field range $1..$2\n")
			unless ($lfnr >= $ffnr);
		my($expanded) = '';
		for (my($f)=$ffnr; $f<=$lfnr; $f++) {
			$expanded .= "AnTsDtArEf[$f]";
			$expanded .= "," unless ($f == $lfnr);
		}
		$expr =~ s(\${$1\.\.$2})($expanded);
	}
	while ($expr =~ /\$\{([^}]*)\}/) {					# ${field}
		$antsEditExprUsesFields |= 1;
		my($fnr) = cardinalp($1) ? $1-1 : fnr($1);
		croak("$0: unknown field $1\n") unless ($fnr >= 0);
		$expr =~ s(\${$1})(AnTsDtArEf\[$fnr\]);
	}
	while ($expr =~ /\$(-?[\w\.]+)/) {					# $field
		$antsEditExprUsesFields |= 1;
		my($fnr) = cardinalp($1) ? $1-1 : fnr($1);
		if ($fnr < 0) {									# should only happen on $antsFnrNegativeOk
			$expr =~ s{\$$1}{AnTsDtArEf\[AnTsDtAlEn$fnr\]};
		} else {
			croak("$0: unknown field $1\n") unless ($fnr >= 0);
			$expr =~ s{\$$1}{AnTsDtArEf\[$fnr\]};
		}
	}
	while ($expr =~ /\$\+([\w\.]+)/) {					# $+field
		$antsEditExprUsesFields |= 1;
		my($fnr) = cardinalp($1) ? $1-1 : fnr($1);
		croak("$0: unknown field $1\n") unless ($fnr >= 0);
		$expr =~ s{\$\+$1}{(AnTsDtArEf\[$fnr\]-AnTsDtArEf0\[$fnr\])};
	}
	$expr =~ s{%%}{AnTsPeRcEnT}g;						# escape
	while ($expr =~ /%([\w\.:]+)/) {					# %PARAMs
		my($p) = $1;
		croak("$0: Undefined PARAM %$p\n")
			unless defined($P{$p});
		$expr =~ s{%$p}{\$P\{"$p"\}};
    }
    if ($bufVar =~ m{\]$}) {
    	my($adl) = '@{' . $bufVar . '}';
		$expr =~ s{AnTsDtAlEn}{$adl}g;
    } else {
    	my($adl) = '@' . substr($bufVar,1);
		$expr =~ s{AnTsDtAlEn}{$adl}g;
    }
	$expr =~ s{AnTsDtArEf}{$bufVar}g;
	$expr =~ s{AnTsDtArEf}{$bufVar}g;
	$expr =~ s{AnTsPeRcEnT}{%}g;
	$expr =~ s{AnTsDoLlAr}{\$}g;

QUOTED_EDIT_EXPR:
	$expr = "return $expr";

	print(STDERR "OUT EditExpr = $expr\n") if ($DEBUG);
    my($subR) = eval("sub { $expr };");
    croak("sub { $expr }; => $@\n") if ($@);
    return $subR;
}

#----------------------------------------------------------------------
# Constant Expressions
#	- carry out calculation based on const and %PARAMs only
# 	- same as edit expressions without field substitutions (%PARAMs ok, though)
#	- $ must still be escaped ($$), although this is unlikely to be used ever
#----------------------------------------------------------------------

sub antsCompileConstExpr($)								# subst fields/%PARAMs
{
	my($expr) = @_;

	print(STDERR "IN  ConstExpr = $expr\n") if ($DEBUG);

	unless ((substr($expr,0,1) eq "'" || substr($expr,0,1) eq '"') &&
		(substr($expr,0,1) eq substr($expr,-1))) {		# quoted string
		$expr =~ s{\$%}{%}g;							# allow for $%param
		$expr =~ s{\$\$}{AnTsDoLlAr}g;					# escape
		$expr =~ s{%%}{AnTsPeRcEnT}g;					# escape
		while ($expr =~ /%([\w\.:]+)/) {				# %PARAMs
			my($p) = $1;
			croak("$0: Undefined PARAM %$p\n")
				unless defined($P{$p});
			$expr =~ s{%$p}{\$P\{"$p"\}};
		}
		$expr =~ s{AnTsPeRcEnT}{%}g;
	    $expr =~ s{AnTsDoLlAr}{\$}g;
	}

	$expr = "return $expr";

	print(STDERR "OUT ConstExpr = $expr\n") if ($DEBUG);
    my($subR) = eval("sub { $expr };");
    croak("sub { $expr }; => $@\n") if ($@);
    return $subR;
}

1;
