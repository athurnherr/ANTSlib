#======================================================================
#                    L I B D E I N E S 9 9 . P L 
#                    doc: Wed Apr 15 11:57:01 2020
#                    dlm: Thu May  7 16:06:56 2020
#                    (c) 2020 A.M. Thurnherr
#                    uE-Info: 9 34 NIL 0 0 70 0 2 4 NIL ofnI
#======================================================================

# Acoustic Backscatter Coefficient [db]

sub Sv($$$$$)		  
{
	my($temp,$pulse_length,$noise_level,$range,$echo_amplitude) = @_;
	my($C)		= -143; 				# RDI WHM300 (from Deines)
	my($Ldbm)	= 10 * log10($pulse_length);
	my($PdbW)	= 14.0;
	my($alpha)	= 0.069;
	my($Kc) 	= 0.45;
		    
	return $C + 10*log10(($temp+273)*$range**2) - $Ldbm - $PdbW
			  + 2*$alpha*$range + $Kc*($echo_amplitude-$noise_level);
}

1;
