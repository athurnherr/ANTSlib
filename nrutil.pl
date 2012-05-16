#======================================================================
#                    N R U T I L . P L 
#                    doc: Wed Feb 24 17:44:49 1999
#                    dlm: Sun Jul  2 00:47:04 2006
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 45 31 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# extract from nrutil.c/nrutil.h (Numerical Recipes) adapted for ANTS

# HISTORY:
#	Feb 24, 1999: -	created from c-source
#	Aug 01, 1999: - added macros from nrutil.h
#	Sep 26, 1999: - added &dumpMatrix()
#   Jul  1, 2006: - Version 3.3 [HISTORY]

# NOTES:
#	- allocation routines &vector, &matrix needed to make sure
#	  right number of elts is allocated (for $# op)
#	- array elts are initialized with nan
#	- array indices MUST start with 1 (in the spirit of FORTRAN IV, bless)
#	- instead of pointer return, we use refs

sub vector($$$)
{
	my($vR,$nl,$nh) = @_;
	my($i);

	croak("vector must be 1-relative")
		unless ($nl == 1);
	for ($i=1; $i<=$nh; $i++) {
		$vR->[$i] = nan;
	}
}

sub matrix($$$$$)
{
	my($mR,$nrl,$nrh,$ncl,$nch) = @_;
	my($i,$j);

	croak("matrix must be 1-relative")
		unless ($nrl == 1 && $ncl == 1);
	for ($i=1; $i<=$nrh; $i++) {
		for ($j=1; $j<=$nch; $j++) {
			$mR->[$i][$j] = nan;
		}
	}
}

#----------------------------------------------------------------------

sub dumpMatrix($$)
{
	my($msg,$mR) = @_;
	my($rows) = $#{$mR};
	my($cols) = $#{$mR->[1]};
	my($r,$c);

	print(STDERR "$msg: $rows x $cols (rows x cols)\n");
	for ($r=1; $r<=$rows; $r++) {
		for ($c=1; $c<=$cols; $c++) {
			printf(STDERR "%.3e\t",$mR->[$r][$c]);
		}
		print(STDERR "\n");
	}
}

#----------------------------------------------------------------------
# Macros
#----------------------------------------------------------------------

sub SQR($) { return $_[0] * $_[0]; }						# D?SQR
sub MAX($$) { return ($_[0] > $_[1]) ? $_[0] : $_[1]; }		# [DF]MAX
sub MIN($$) { return ($_[0] < $_[1]) ? $_[0] : $_[1]; }		# [DF]MIN
sub SIGN($$) { return ($_[1] >= 0) ? $_[0] : -$_[0]; }		# SIGN

1;
