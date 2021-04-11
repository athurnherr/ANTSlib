#======================================================================
#                    L I B G M T . P L 
#                    doc: Sun Jun 14 13:45:47 2015
#                    dlm: Sun Apr 11 09:55:22 2021
#                    (c) 2015 A.M. Thurnherr
#                    uE-Info: 47 34 NIL 0 0 72 2 2 4 NIL ofnI
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
#	Mar 16, 2016: - adapted to GMT5
#	Mar 17, 2016: - added check for gmt5 on load
#	Apr 10, 2021: - adapted to GMT6 (suppress warnings)
#	Apr 11, 2021: - added gmt set GMT_AUTO_DOWNLOAD off

$DEBUG = 0;

#----------------------------------------------------------------------
# Make sure gmt6 is installed
#----------------------------------------------------------------------

if (`which gmt` eq '') {
	if (`which psxy` eq '') {
		croak("$0: [libGMT.pl] GMT version 6 required\n");
	} else {
		croak("$0: [libGMT.pl] GMT version 6 required (gmt4 installed)\n");
	}
} else {
	my($GMTversion) = `gmt --version`; chomp($GMTversion);
	croak("$0: [libGMT.pl] GMT version 6 required (version $GMTversion installed)\n")
		unless ($GMTversion =~ '^6');
}

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
	GMT_spawn("| gmt set @_");
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
			gmt set PROJ_LENGTH_UNIT cm PS_MEDIA letter \\
			        FONT_LABEL ${LABEL_FONT_SIZE} \\
	                FONT_ANNOT_PRIMARY ${ANNOT_FONT_SIZE} \\
					GMT_AUTO_DOWNLOAD off \\
	                FORMAT_GEO_MAP ddd:mm:ssF") &&
		croak("gmt set failed\n");
	$GMT_plotfile = "$ENV{PWD}/$pfn";
	GMT_setJ($J); GMT_setR($R);
	GMT_spawn("| gmt psxy -Ve -K $J $R $extra > $GMT_plotfile");
	close(GMT);
}

sub GMT_setAnnotFontSize($)
{
	GMT_set("FONT_ANNOT_PRIMARY $_[0]");
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
	if (defined($opt)) {
		GMT_spawn("| gmt psbasemap -Ve -O $GMT_J $GMT_R $opt >> $GMT_plotfile");
	} else {
		GMT_spawn("| gmt psxy -Ve -O $GMT_J $GMT_R -Sc0.1 >> $GMT_plotfile");
	}
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
#	GMT_spawn("| gmt psxy -O -K $GMT_J $GMT_R >> $GMT_plotfile");
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
	GMT_spawn("| gmt psxy -Ve -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

sub GMT_psbasemap(@)
{
	my($opts) = @_;
	GMT_spawn("| gmt psbasemap -Ve -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

sub GMT_pstext(@)
{
	my($opts) = @_;
	GMT_spawn("| gmt pstext -Ve -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

sub GMT_psscale(@)
{
	my($opts) = @_;
	GMT_spawn("| gmt psscale -Ve -O -K $GMT_J $GMT_R $opts >> $GMT_plotfile");
}

1;
