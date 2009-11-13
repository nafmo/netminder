#!/bin/bash
# Check if web pages have been updated
#
# Copyright © 2001-2009 Peter Krefting <peter@softwolves.pp.se>
#
# ------------------------------------------------------------------------
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# ------------------------------------------------------------------------

# Settings
export LC_ALL="sv_SE.ISO8859-1"
export TERM=vt100
AGENT="MyPersonalNetMind/1.0 (Using Lynx)"
DIRECTORY="/home/peter/bin/netmind"

# Check integrity
cd "$DIRECTORY"
if [ ! -e netmind.urls -o ! -e netmind.config ]; then
  echo "Cannot find netmind.urls or netmind.config in $DIRECTORY"
  echo
  echo "Populate netmind.urls with the list of web pages to monitor on the form"
  echo "   key=url"
  echo
  echo "To post-edit the output of lynx, create a file on the name key.sed with"
  echo "a script that can be called from sed. For example:"
  echo "   echo '/Comments:/,$ d' > key.sed"
  echo
  echo "The file netmind.config should contain your e-mail address"
  echo "   echo me@example.com > netmind.config"
  echo
  echo "Now call netmind.sh once to set up the initial files, and then set up"
  echo "(for instance) a daily run through cron."
  echo
  echo "Requires: lynx, sed, GNU date, GNU diff, sendmail (or compatible)"
  exit 1
fi

# Read settings
read EMAIL < netmind.config

# Iterate over the list of URLs
for data in $(<netmind.urls); do
	# Split values
	TAG="${data%%=*}"
	URL="${data#*=}"

	case "$URL" in
	http://*|https://*)

		# File name
		SAVED="$TAG.current"
		TMPFILE=$(/bin/tempfile --prefix=netmind)
		test -e "$TMPFILE" || exit 1

		# Get the current page
		lynx -dump -nolist -useragent="$AGENT" "$URL" >> "$TMPFILE" 2> /dev/null

		if [ "$?" = "0" -a -e "$SAVED" ]; then
			# Filter pages
			if [ -e "$TAG.sed" ]; then
				TMPFILE2=$(/bin/tempfile --prefix=netmind)
				sed -f "$TAG.sed" "$TMPFILE" >> "$TMPFILE2"
				rm -f "$TMPFILE"
				mv "$TMPFILE2" "$TMPFILE"
				unset TMPFILE2
			fi

			# Compare to the saved page
			if diff -qwbB "$SAVED" "$TMPFILE" > /dev/null; then
				# Equal, throw away the temporary file
				rm -f "$TMPFILE"
			else
				# Send comparison by e-mail
				OLD=$(/bin/date -r "$SAVED" +"%Y-%m-%d")

				(
					echo "From: MyNetMind <$EMAIL>"
					echo "To: Peter Krefting <$EMAIL>"
					echo "Subject: =?ISO-8859-1?Q?=C4ndringar?= i $URL"
					echo "X-Netmind: clear"
					echo "MIME-Version: 1.0"
					echo "Content-Type: text/plain;charset=iso-8859-1"
					echo "Content-Transfer-Encoding: 8bit"
					echo
					echo "Ändringar har detekterats i $URL"
					echo "Tidigare fil daterad $OLD"
					echo
					echo "Dessa ändringar finns:"
					echo "---------------------------------------------------------------------------"
					diff -u "$SAVED" --label "Version per den $OLD" "$TMPFILE" --label "Aktuell $URL"
					echo "---------------------------------------------------------------------------"
					echo
					echo "Sidan i sin helhet:"
					echo "---------------------------------------------------------------------------"
					cat "$TMPFILE"
					echo "---------------------------------------------------------------------------"
				) | /usr/lib/sendmail -oem -t -oi
				test -e "$SAVED.2" && rm "$SAVED.2"
				test -e "$SAVED.1" && mv "$SAVED.1" "$SAVED.2"
				mv "$SAVED" "$SAVED.1"
				mv "$TMPFILE" "$SAVED"
			fi
		else
			# First run, save the complete file
			if [ ! -s "$TMPFILE" ]; then
				rm "$TMPFILE"
			else
				# Filter pages
				if [ -e "$TAG.sed" ]; then
					TMPFILE2=$(/bin/tempfile --prefix=netmind)
					sed -f "$TAG.sed" "$TMPFILE" >> "$TMPFILE2"
					rm -f "$TMPFILE"
					mv "$TMPFILE2" "$TMPFILE"
					unset TMPFILE2
				fi
				mv "$TMPFILE" "$SAVED"
			fi
		fi
		;;
	*)
		echo "Ogiltig URL i netmaind.urls: $data"
		;;
	esac
done
