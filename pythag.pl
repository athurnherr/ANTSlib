#======================================================================
#                    . / P Y T H A G . P L 
#                    doc: Sun Aug  1 10:41:34 1999
#                    dlm: Sun Aug  1 10:46:43 1999
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 23 65 NIL 0 0 72 0 2 4 ofnI
#======================================================================

# PYTHAG routine from Numerical Recipes adapted to ANTS

# HISTORY:
#	Aug 01, 1999: - manually converted from c-source

sub pythag($$)
{
	my($a,$b) = @_;							# params
	my($absa,$absb);						# float 

	$absa = abs($a);
	$absb = abs($b);
	return $absa*sqrt(1.0+SQR($absb/$absa))
		if ($absa > $absb);
	return ($absb == 0 ? 0 : $absb*sqrt(1+$absa*$absa/$absb/$absb)));
}

