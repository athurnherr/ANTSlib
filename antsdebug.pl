#======================================================================
#                    A N T S D E B U G . P L 
#                    doc: Sat Mar 21 14:18:37 2009
#                    dlm: Thu Aug 20 22:41:38 2009
#                    (c) 2009 A.M. Thurnherr
#                    uE-Info: 11 55 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# HISTORY:
#  Mar 21, 2009: - created from [abc]
#  Aug 20, 2009: tried to change prompt, to no avail...

{ my($term);

sub debug()
{
	unless (defined($term)) {
		use Term::ReadLine;
		$term = new Term::ReadLine 'debug';
    }
	do {
		my($expr) = $term->readline;
		return if ($expr eq 'return');
		$res = eval($expr);
		if 	(defined($res)) {						# no error
			print(STDERR "$res\n");
		} else {									# error
			print(STDERR "$@");
		}
	}
}

}
1;
