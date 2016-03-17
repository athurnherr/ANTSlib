#======================================================================
#                    L I B G M T . P L 
#                    doc: Sun Jun 14 13:45:47 2015
#                    dlm: Sun Sep 27 09:23:46 2015
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 45 10 NIL 0 0 72 2 2 4 NIL ofnI
#======================================================================

# perl implementation of /Data/Makefiles/Makefile.GMT

#----------------------------------------------------------------------
# USAGE
#----------------------------------------------------------------------
#
# Basic Example
# -------------
# GMT_begin('temp_prof.ps','-JX10/-10','-R0/30/0/5000');
# GMT_psxy('-W1,red');
# print(GMT "$temp $depth\n");
# GMT_end('-Ba5f1:"Temperature [degC]":/a500f100:"Depth [m]":WeSn');
#
# Other GMT Utilities
# -------------------
# GMT_pstext(<opts>)			x y size angle fontno justify(ML,BC,TR,...) "text"
# GMT_psbasemap(<opts>)			often implies GMT_end() w/o args
# GMT_psscale(<opts>)			scale bar
#
# Other Extensions
# ----------------
# GMT_unitcoords();				afterwards, x and y range from 0 to 1; useful for legends
# GMT_setR('-R0/1/0/1')			subsequent GMT utilities use this ROI
# GMT_setJ('-JX10/-1-')			subsequent GMT utilities use this projection
# GMT_setAnnotFontSize(7)		set primary annotation font size
#
#----------------------------------------------------------------------

# HISTORY:
#	Jun 14, 2015: - created
#	Jun 16, 2015: - BUG: forgot to return to PWD
#	Jun 18, 2015: - added $DEBUG
#	Jul 26, 2015: - added usage documentation
#				  - simplified GMT_unitcoords()
#	Jul 28, 2015: - added GMT_setAnnotFontSize(), GMT_psscale()

$DEBUG = 0;

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

sub GMT_setAnnotFontSize($)
{
	GMT_set("ANNOT_FONT_SIZE_PRIMARY $_[0]");
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
	GMT_setR('-R0/1/0/1');
}

sub GMT_unitcoords_logscale()
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
#	GMT_spawn("| psxy -O -K $GMT_J $GMT_R >> $GMT_plotfile");
#	close(GMT);
}

#----------------------------------------------------------------------
# GMT_psxy(opts)
# GMT_psbasemap(opts)
# GMT_pstext(opts)
# GMT_psscale(opts)
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

sub GMT_psscale(@)
{
	my($opts) = @_;
	GMT_spawn("| psscale -O -K $opts >> $GMT_plotfile");
}

1;
