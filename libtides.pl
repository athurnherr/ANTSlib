#======================================================================
#                    L I B T I D E S . P L 
#                    doc: Thu Aug 24 21:37:14 2006
#                    dlm: Thu Apr 26 10:22:53 2012
#                    (c) 2006 A.M. Thurnherr
#                    uE-Info: 17 0 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# tidal calculations

# HISTORY:
#   Aug 24, 2006: - created during GRAVILUCK
#   Jan 22, 2008: - renamed M2() to M2_bias()
#                 - added M2_phase()
#   Apr 26, 2012: - added K1 & M2 tidal frequencies

#----------------------------------------------------------------------
# tidal frequencies
#   - taken from thesis Makefile
#   - according to my memory, the values are from Apel's book
#----------------------------------------------------------------------

$M2 = 24/1.9322;
$K1 = 24/1.0027;

#----------------------------------------------------------------------
# given t0, a decimal day at the beginning of "flood", return a scale
# between -1 and 1 that can be multiplied with the max tidal flow amplitude
# to estimate tidal velocity at time t. 
#----------------------------------------------------------------------

sub M2_bias(@)
{
	my($t0,$t) = &antsFunUsage(2,'ff','time-origin, time',@_);
	return sin(2*3.14159265358979 * ($t-$t0) / ($M2/24));
}

sub M2_phase(@)
{
	my($t0,$t) = &antsFunUsage(2,'ff','time-origin, time',@_);
	return round(360 * frac(($t-$t0) / ($M2/24)));
}

1;
