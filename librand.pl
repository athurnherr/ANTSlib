#======================================================================
#                    L I B R A N D . P L 
#                    doc: Thu Nov 19 14:27:19 2015
#                    dlm: Tue Mar  8 15:50:35 2016
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 10 27 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Nov 19, 2015: - created

sub gauss_rand($$)
{
	my($mu,$sigma) = &antsFunUsage(2,'ff','mu, sigma',@_);
}

#----------------------------------------------------------------------------------------------------
# From info found at [http://www.mathworks.com/matlabcentral/newsreader/view_thread/301276]
#
# verified with:
#   plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(-2) | Hist -s 100 r | Cat -S $2>2' lt 3,x**-2*1e7
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(-3) | Hist r',x**-3*7e3
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(0) | Hist -s 0.01 r'
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(1) | Hist -s 0.01 r'
#	plot '<Cat -Lrand -f =1,1,1e5 -F r=pwrlaw_rand(2) | Hist -s 0.01 r'
#----------------------------------------------------------------------------------------------------

sub pwrlaw_rand($)		
{
	my($p) = &antsFunUsage(1,'f','exponent',@_);
	return rand() ** (1/($p+1));
}

1;
