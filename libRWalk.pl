#======================================================================
#                    L I B R W A L K . P L 
#                    doc: Tue Oct  5 21:34:37 2010
#                    dlm: Tue Oct  5 21:47:28 2010
#                    (c) 2010 A.M. Thurnherr
#                    uE-Info: 26 26 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

sub fac($)
{ return ($_[0] < 2) ? $_[0] : $_[0]*fac($_[0]-1); }

#----------------------------------------------------------------------
# From: http://mathworld.wolfram.com/RandomWalk1-Dimensional.html
# Let N steps of equal length be taken along a line. Let p be the
# probability of taking a step to the right, q the probability of taking a
# step to the left, n1 the number of steps taken to the right, and  n2 the
# number of steps taken to the left.
# The following calculates the probability of taking exactly n1 steps out
# of N (= n1+n2) to the right.
#----------------------------------------------------------------------

sub pNSteps(@)
{
	my($n1,$N,$p,$q) = @_;
	$p = $q = 0.5 unless defined($p);
	return fac($n1+($N-$n1)) / (fac($n1)*fac($N-$n1)) * $p**$n1 * $q**($N-$n1);
}

1;
