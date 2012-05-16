#======================================================================
#                    L I B U B T E S T . P L 
#                    doc: Sun Mar 21 09:35:05 1999
#                    dlm: Mon Jul 24 15:10:05 2006
#                    (c) 1999 A.M. Thurnherr
#                    uE-Info: 10 32 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# overloaded equal() routine for ubtest
#	NB: tests relative errors!!!

# HISTORY:
#	Mar 21, 1999: - created
#	Sep 18, 1999: - argument typechecking

$error = 1e-6;

sub equal($$)
{
	my($target,$val) = &antsFunUsage(2,"ff","target, val",@_);
	my($abserr) = $target-$val;
	my($relerr) = abs($abserr / ($target ? $target : 1));
	if ($relerr > $error) {
		print(STDERR "Equality failure --- abs err = $abserr, rel err = $relerr\n");
		exit(1);
	}
	exit(0);
}

1;
