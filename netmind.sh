#!/bin/bash
# Titta p� om webbsidor har uppdaterat sig
# � 2001 Peter Karlsson <peter@softwolves.pp.se>

# Inst�llningar
export LC_ALL="sv_SE.ISO8859-1"
export TERM=vt100
AGENT="MyPersonalNetMind/1.0 (Using Lynx)"

# Kolla integritet
cd /home/peter/bin/netmind
test -e netmind.urls || exit 1

# G� igenom listan �ver URLer
for data in $(<netmind.urls); do
	# Dela p� v�rdena
	TAG="${data%=*}"
	URL="${data#*=}"

	case "$URL" in
	http://*)

		# Filnamn
		SAVED="$TAG.current"
		TMPFILE=$(/bin/tempfile --prefix=netmind)
		test -e "$TMPFILE" || exit 1

		# H�mta aktuell sida
		lynx -dump -useragent="$AGENT" "$URL" >> "$TMPFILE" 2> /dev/null

		if [ "$?" = "0" -a -e "$SAVED" ]; then
			# J�mf�r med undansparad sida
			if diff -qwbB "$SAVED" "$TMPFILE" > /dev/null; then
				# Lika, kasta bort tempor�rfil
				rm -f "$TMPFILE"
			else
				# E-posta j�mf�relsen
				OLD=$(/home/peter/src/filedate "$SAVED")

				(
					echo "�ndringar har detekterats i $URL"
					echo "Tidigare fil daterad $OLD"
					echo
					echo "Dessa �ndringar finns:"
					diff -u "$SAVED" --label "Version per den $OLD" "$TMPFILE" --label "Aktuell $URL"
					echo
					echo "Sidan i sin helhet:"
					cat "$TMPFILE"
				) | mailx -s "�ndringar i $URL" peter@softwolves.pp.se
				rm "$SAVED.2"
				mv "$SAVED.1" "$SAVED.2"
				mv "$SAVED" "$SAVED.1"
				mv "$TMPFILE" "$SAVED"
			fi
		else
			# F�rsta g�ngen, spara undan filen
			mv "$TMPFILE" "$SAVED"
		fi
		;;
	*)
		echo "Ogiltig URL i netmaind.urls: $data"
		;;
	esac
done
