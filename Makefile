#======================================================================
#                    M A K E F I L E 
#                    doc: Tue May 15 18:12:31 2012
#                    dlm: Thu May  7 13:18:58 2015
#                    (c) 2012 A.M. Thurnherr
#                    uE-Info: 16 0 NIL 0 0 72 0 2 4 NIL ofnI
#======================================================================

.PHONY: version
version:
	@sed -n '/^description =/s/description = //p' .hg/hgrc

.PHONY: publish
publish:
	cd ..; \
	scp -Cr ANTSlib miles:public_hg/
