#!/bin/bash
# Titta på om webbsidor har uppdaterat sig
# © 2001 Peter Karlsson <peter@softwolves.pp.se>

# Inställningar
export LC_ALL="sv_SE.ISO8859-1"
export TERM=vt100
AGENT="MyPersonalNetMind/1.0 (Using Lynx)"

# Kolla integritet
cd /home/peter/bin/netmind
test -e netmind.urls || exit 1

# Gå igenom listan över URLer
for data in $(<netmind.urls); do
	# Dela på värdena
	TAG="${data%%=*}"
	URL="${data#*=}"

	case "$URL" in
	http://*)

		# Filnamn
		SAVED="$TAG.current"
		TMPFILE=$(/bin/tempfile --prefix=netmind)
		test -e "$TMPFILE" || exit 1

		# Hämta aktuell sida
		lynx -dump -useragent="$AGENT" "$URL" >> "$TMPFILE" 2> /dev/null

		if [ "$?" = "0" -a -e "$SAVED" ]; then
			# Filtrera sidor
			if [ -e "$TAG.sed" ]; then
				TMPFILE2=$(/bin/tempfile --prefix=netmind)
				sed -f "$TAG.sed" "$TMPFILE" >> "$TMPFILE2"
				rm -f "$TMPFILE"
				mv "$TMPFILE2" "$TMPFILE"
				unset TMPFILE2
			fi

			# Jämför med undansparad sida
			if diff -qwbB "$SAVED" "$TMPFILE" > /dev/null; then
				# Lika, kasta bort temporärfil
				rm -f "$TMPFILE"
			else
				# E-posta jämförelsen
				OLD=$(/home/peter/src/filedate "$SAVED")

				(
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
				) | mailx -s "Ändringar i $URL" peter@softwolves.pp.se
				test -e "$SAVED.2" && rm "$SAVED.2"
				test -e "$SAVED.1" && mv "$SAVED.1" "$SAVED.2"
				mv "$SAVED" "$SAVED.1"
				mv "$TMPFILE" "$SAVED"
			fi
		else
			# Första gången, spara undan filen
			if [ $(/home/peter/src/filesize "$TMPFILE") = "0" ]; then
				rm "$TMPFILE"
			else
				# Filtrera sidor
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
