#======================================================================
#                    L I B G M T . P L 
#                    doc: Sun Jun 14 13:45:47 2015
#                    dlm: Thu Jun 18 20:13:24 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 16 1 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# perl implementation of /Data/Makefiles/Makefile.GMT

# HISTORY:
#	Jun 14, 2015: - created
#	Jun 16, 2015: - BUG: forgot to return to PWD
#	Jun 18, 2015: - added $DEBUG

#$DEBUG = 1;

#----------------------------------------------------------------------
# Library
#----------------------------------------------------------------------

my($GMT_plotfile);
my($GMT_J);
my($GMT_R);

sub GMT_setR($) { ($GMT_R) = @_; }						# (re-)define -R
sub GMT_setJ($) { ($GMT_J) = @_; }						# (re-)define -J

sub GMT_spawn($)										# spawn GMT command in temp dir
{
	my($cmd) = @_;
	close(GMT);
	chdir("/tmp/antsGMT.$$") ||
		croak("/tmp/antsGMT.$$: $!\n");
	print(STDERR "$cmd\n") if ($DEBUG);
	open(GMT,$cmd) || croak("$cmd: $!\n");
	chdir("$ENV{PWD}") ||
		croak("$ENV{PWD}: $!\n");
}

sub GMT_set(@)											# set GMT defaults
{
	GMT_spawn("| gmtset @_");
}

#----------------------------------------------------------------------
# GMT_begin(plot_file,J,R,extra_opts),
#	e.g. GMT_begin('temp_prof.ps','-JX10/-10','-R0/30/0/5000');
#		1) create temp directory
#		2) set GMT defaults
#		3) create plot file with empty psxy
#----------------------------------------------------------------------

my($LABEL_FONT_SIZE) = 14 unless defined($LABEL_FONT_SIZE);
my($ANNOT_FONT_SIZE) = 14 unless defined($ANNOT_FONT_SIZE);

sub GMT_begin(@)
{
	my($pfn,$J,$R,$extra) = @_;
	mkdir("/tmp/antsGMT.$$");
	chdir("/tmp/antsGMT.$$") ||
		croak("/tmp/antsGMT.$$: $!\n");
	system("rm -f .gmt*
			gmtset MEASURE_UNIT cm PAPER_MEDIA letter \\
			       LABEL_FONT_SIZE ${LABEL_FONT_SIZE} \\
	               ANNOT_FONT_SIZE_PRIMARY ${ANNOT_FONT_SIZE} \\
	               WANT_EURO_FONT true \\
	               PLOT_DEGREE_FORMAT ddd:mm:ssF") &&
		croak("gmtset failed\n");
	$GMT_plotfile = "$ENV{PWD}/$pfn";
	GMT_setJ($J); GMT_setR($R);
	GMT_spawn("| psxy -K $J $R $extra > $GMT_plotfile");
	close(GMT);
}

#----------------------------------------------------------------------
# GMT_end(B)
#	1) chdir to temp-dir
#	2) psbasemap w/o -K
#	3) close GMT file
#	4) remove GMT temp dir
#----------------------------------------------------------------------

sub GMT_end(@)
{
	my($opt) = @_;
	$opt = '-G' unless defined($opt);
	
	GMT_spawn("| psbasemap -O $GMT_J $GMT_R $opt >> $GMT_plotfile");
	close(GMT);
	chdir("$ENV{PWD}") || croak("ENV{PWD}: $!\n");
	system("rm -rf /tmp/antsGMT.$$") &&
		croak("Offending command: rm -rf /tmp/antsGMT.$$\n");
}

#----------------------------------------------------------------------
# GMT_unitcoords()
#	- set unit coordinate system
#----------------------------------------------------------------------

sub GMT_unitcoords()
{
	($jx,$jy) = ($GMT_J =~ m{-J.-?(\d+)[a-z]*/-?(\d+)});
	if (defined($jy)) {
		GMT_setJ("-JX$jx/$jy");
	} else {
		($jx) = ($GMT_J =~ m{-J.-?(\d+)});
		if (defined($jx)) {
			GMT_setJ("-JX$jx");
		} else {
			croak("cannot decode $GMT_J ($jx,$jy)");
		}
	}
	GMT_setR('-R0/1/0/1');
	GMT_spawn("| psxy -O -K $GMT_J $GMT_R >> $GMT_plotfile");
	close(GMT);
}

#----------------------------------------------------------------------
# GMT_psxy(opts)
# GMT_psbasemap(opts)
# GMT_pstext(opts)
#----------------------------------------------------------------------

sub GMT_psxy(@)
{
	my($opts) = @_;
	GMT_spawn("| psxy -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

sub GMT_psbasemap(@)
{
	my($opts) = @_;
	GMT_spawn("| psbasemap -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

sub GMT_pstext(@)
{
	my($opts) = @_;
	GMT_spawn("| pstext -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

1;
