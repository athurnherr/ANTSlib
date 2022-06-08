#======================================================================
#                    L I B W A T E R D E P T H . P L 
#                    doc: Mon Feb  7 16:06:56 2022
#                    dlm: Mon Feb  7 16:20:09 2022
#                    (c) 2022 A.M. Thurnherr
#                    uE-Info: 10 27 NIL 0 0 70 0 2 4 NIL ofnI
#======================================================================

# HISTORY:
#	Feb  7, 2022: - created

sub waterdepth(@)
{
	my($lon,$lat) = &antsFunUsage(2,"ff","lon, lat",@_);
	open(my $F, "-|", "waterdepth $lon $lat") || croak("waterdepth: $!\n");
	my($wd);
	chomp($wd = <$F>);
	croak("Cannot decode waterdepth output ($wd)\n")
		unless numberp($wd);
	close($F);
	return $wd;
}

1;
