#!/bin/bash
####################################################
#
# Driver for cron to run chgbarredpin.pl
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
# Copyright (c) Wed Apr 29 14:16:46 MDT 2016
# Rev:  
#          0.1 - Cronned version. 
#          0.0 - Dev. 
#
####################################################

# Environment setup required by cron to run script because its daemon runs
# without assuming any environment settings and we need to use sirsi's.
###############################################
# *** Edit these to suit your environment *** #
source /s/sirsi/Unicorn/EPLwork/cronjobscripts/setscriptenvironment.sh
###############################################
VERSION=0.1
export WORK_DIR=/s/sirsi/Unicorn/EPLwork/cronjobscripts/ChangeBarredPINs
APP=chgbarredpin.pl
ADDRESSES=ilsadmins\@epl.ca
cd $WORK_DIR
if [ -s "$APP" ]
	./$APP -rUt
	echo "Ran '$APP'." | mailx -s"Change PINS report." $ADDRESSES
else
	echo "** Error can't find the script '$APP' to run! **" | mailx -s"Change PINS report." $ADDRESSES
	exit 1
find
#EOF

