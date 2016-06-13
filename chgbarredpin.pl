#!/usr/bin/perl -w
#########################################################################
#
# Perl source file for project chgbarredpin.pl
#
# Changes the PIN on barred account.
#    Copyright (C) 2016  Andrew Nisbet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.
#
# Author:  Andrew Nisbet, Edmonton Public Library
# Created: Wed May 11 09:54:40 MDT 2016
# Rev: 
#          0.2 - Check-and-skip previously changed PINs. 
#          0.1 - -R, -U, -t, -x, -r tested on production. 
#          0.0 - Dev. 
#
#####################################################################

use strict;
use warnings;
use vars qw/ %opt /;
use Getopt::Std;

# Environment setup required by cron to run script because its daemon runs
# without assuming any environment settings and we need to use sirsi's.
###############################################
# *** Edit these to suit your environment *** #
$ENV{'PATH'}  = qq{:/s/sirsi/Unicorn/Bincustom:/s/sirsi/Unicorn/Bin:/usr/bin:/usr/sbin};
$ENV{'UPATH'} = qq{/s/sirsi/Unicorn/Config/upath};
###############################################
my $VERSION            = qq{0.2};
my $TEMP_DIR           = `getpathname tmp`;
chomp $TEMP_DIR;
my $TIME               = `date +%H%M%S`;
chomp $TIME;
my $DATE               = `date +%m/%d/%Y`;
chomp $DATE;
my @CLEAN_UP_FILE_LIST = (); # List of file names that will be deleted at the end of the script if ! '-t'.
my $BINCUSTOM          = `getpathname bincustom`;
chomp $BINCUSTOM;
my $PIPE               = "$BINCUSTOM/pipe.pl";
my $PIN_PREFIX         = "ILS_";
my $NEW_PIN            = $PIN_PREFIX . "4617";  # Choose -r to change this to a random value for each PIN changed.
# Let's restrict profiles so we don't change pins on system cards.
my $PROFILES           = "EPL_ADLTNR,EPL_ADULT,EPL_JUVGR,EPL_CORP,EPL_ADU05,EPL_JMDCRT,EPL_ADU10,EPL_JRECIP,EPL_JUV,EPL_JUVIND,EPL_JUVNR,EPL_JUV05,EPL_LAD,EPL_JUV10,EPL_MEDCRT,EPL_RECIP,EPL_STAFF,EPL_VOL,EPL_THREE,EPL_VISITR,EPL_TAL,EPL_UAL,EPL_JUV01,EPL_LIFE,EPL_WINNER,EPL_INVPJT,EPL_ADU01,EPL_HOME,EPL_ADU1FR,EPL_XDLOAN,EPL_METRO,EPL_METROJ,EPL_CONCOR,EPL_NORQ,EPL_PRTNR,EPL_JPRTNR,EPL_ONLIN,EPL_JONLIN,EPL_ACCESS";
my $SHELL_SCRIPT       = "change_barred_pins.sh";

#
# Message about this program and how to use it.
#
sub usage()
{
    print STDERR << "EOF";

	usage: $0 [-rRtUx]
SSO will authenticate library customers through EZproxy to provide access to most of the library's online 
resources. BC refuses to amend their code to test the status of a customer before approving authentication. 
The result is that BARRED customers are still allowed to use online resources. To accommodate BC  this 
script will change the PINs on all BARRED customer accounts.

All pins, random or fixed, are prefixed with 'ILS_' to denote that this pin has been changed and doesn't need
to be revisited by the script. This is done to improve temporal performance.

 -r: Change PINs for all customers affected this run to a common, but random number.
 -R: Change PINs for all customers affected this run to a unique, and random number. Slower.
 -t: Preserve temporary files in $TEMP_DIR.
 -U: Actually change the pins, otherwise just produce selection in temp files. See -t.
     If you also choose -R, you will have to change the file '$SHELL_SCRIPT' to executable,
     and then run that shell script to make the desired PIN changes.
 -x: This (help) message.

example:
  $0 -RUt will create a shell script to change large numbers of PINs each to a unique random 4 character value.
          You will need to make this executable and run it to change all the accounts. This will be slower.
  $0 -rUt will change all the barred customer account PINs to the same random number. This will be quicker, and automatic.
  $0 -Ut  will change all the barred customer account PINs to the same default PIN of $NEW_PIN.
  $0 -t   will create a selection list of all barred customers in $TEMP_DIR.
  
Version: $VERSION
EOF
    exit;
}

# Removes all the temp files created during running of the script.
# param:  List of all the file names to clean up.
# return: <none>
sub clean_up
{
	foreach my $file ( @CLEAN_UP_FILE_LIST )
	{
		if ( $opt{'t'} )
		{
			printf STDERR "preserving file '%s' for review.\n", $file;
		}
		else
		{
			if ( -e $file )
			{
				unlink $file;
			}
			else
			{
				printf STDERR "** Warning: file '%s' not found.\n", $file;
			}
		}
	}
}

# Writes data to a temp file and returns the name of the file with path.
# param:  unique name of temp file, like master_list, or 'hold_keys'.
# param:  data to write to file.
# return: name of the file that contains the list.
sub create_tmp_file( $$ )
{
	my $name    = shift;
	my $results = shift;
	my $sequence= sprintf "%02d", scalar @CLEAN_UP_FILE_LIST;
	my $master_file = "$TEMP_DIR/$name.$sequence.$TIME";
	# Return just the file name if there are no results to report.
	return $master_file if ( ! $results );
	open FH, ">$master_file" or die "*** error opening '$master_file', $!\n";
	print FH $results;
	close FH;
	# Add it to the list of files to clean if required at the end.
	push @CLEAN_UP_FILE_LIST, $master_file;
	return $master_file;
}

# Kicks off the setting of various switches.
# param:  
# return: 
sub init
{
    my $opt_string = 'rRtUx';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if ( $opt{'x'} );
}

# Creates a random 4 digit PIN.
# param:  none
# return: 4 digit PIN.
sub getRandomPIN()
{
	my @value = ( map { sprintf q|%X|, rand(16) } 1 .. 4 );
	return $PIN_PREFIX . join '', @value;
}

init();
### code starts

### List of status in Symphony. These map to seluserstatus -t or -j to the text version of status (field 3).
# USTN|1|BARRED|$<barred>|$<USTN_msg_barred>|BARRED|REPLACE_ALWAYS|N|
# USTN|2|OK|$<OK>||OK|REPLACE_ALWAYS|N|
# USTN|3|BLOCKED|$<blocked>|$<USTN_msg_blocked>|BLOCKED|REPLACE_ALWAYS|N|
# USTN|4|DELINQUENT|$<delinquent>|$<USTN_msg_delinquent>|DELINQUENT|REPLACE_ALWAYS|N|
# USTN|5|COLLECTION|$<collection_agency>|$<USTN_msg_collection>|BLOCKED|REPLACE_REPORT|N|
### Selection stage
printf STDERR "starting user selection.\n";
my $results = ` seluserstatus -tBARRED -oUt | seluser -iU -p"$PROFILES" -oUSpw | "$PIPE" -G"c3:^$PIN_PREFIX"`;
printf STDERR "done.\n";
# Produces:
# 309|BARRED|EPL_LAD|6089|
# 1386|BARRED|EPL_ADULT|23339|
# 1439|BARRED|EPL_ADULT|3489|
# 1756|BARRED|EPL_ADULT|7889|
# 2255|BARRED|EPL_XDLOAN|1234|
### Let's save the results.
my $barredUserKeys = create_tmp_file( "chgbarredpin_user_selection", $results );
### -r gives the same random PIN to all accounts affected by this run. 
my $new_pin = $NEW_PIN;
### If ILS admin used -r set the new PIN to the value.
$new_pin = getRandomPIN() if ( $opt{'r'} );
printf STDERR "->%s<-\n", $new_pin;
## Now let's change the PIN.
if ( $opt{'U'} )
{
	if ( $opt{'R'} )
	{
		# This will create a new file with all the commands required to change the PINs on all the accounts to 
		# uniquely random numbers.
		unlink $SHELL_SCRIPT if ( -s $SHELL_SCRIPT ); # Get rid of the old one if data in it.
		open FH_IN, "<$barredUserKeys" or die "*** error opening '$barredUserKeys', $!\n";
		while (<FH_IN>)
		{
			$new_pin = getRandomPIN();
			my $userKeyLine = $_;
			chomp $userKeyLine;
			`echo "$userKeyLine" |  "$PIPE" -oc0 | "$PIPE" -m'c0:echo ######## \| edituser -R$new_pin' >> "$SHELL_SCRIPT"`;
		}
		printf STDERR "shell script '%s' to change all barred users' PINs to unique random values created, but not run.\n", $SHELL_SCRIPT;
		close FH_IN;
	}
	else ## Not -R, but possibly either the default PIN or a pre-picked random PIN. 
	{
		# This will make all the barred users for this run have the same random PIN. This is reasonable temporally
		# since the original run would affect 12559 accounts. Future, more frequent runs will naturally take less time
		# so changing accounts one-at-a-time may not be unreasonable.
		`cat "$barredUserKeys" | edituser -R$new_pin`;
	}
}
### code ends
if ( $opt{'t'} )
{
	printf STDERR "Temp files will not be deleted. Please clean up '%s' when done.\n", $TEMP_DIR;
}
else
{
	clean_up();
}
# EOF
