#!/bin/bash

echo "Licenses checking..."

manifestfilename=$LC_MANIFESTFILE
excludefilename="./licensewhitelist.txt"
search="L\?GPL-\?3\.0"

if ! test -f "$manifestfilename"
then
	echo "[ERROR] $manifestfilename not found. Check filepath or run \"make legal-info\" command before script."
	exit 1
fi


IFS=$'\n'
set -f

# Replacing collumn separator from , to |
lines=$(sed 's/","/"|"/g' "$manifestfilename")

res=false

for line in $lines
do
	progname="$(cut -d'|' -f1 <<< $line | sed 's/"//g')" # get first collumn with module name
	version="$(cut -d'|' -f2 <<< $line | sed 's/"//g')" # get first collumn with module name
	lictype="$(cut -d'|' -f3 <<< $line | sed 's/"//g')"  # get third collumn with licenses list

	if $(echo "$lictype" | grep -q $search) # Does the line has a pattern?
	then
		if (! test -e "$excludefilename" || ! $(grep -q ^$progname-$version$ "$excludefilename")) # Is in ignore list?
		then
			res=true
			echo "[ERROR] Found \"$progname\" version: \"$version\" with license \"$lictype\". Add \"$progname-$version\" to $excludefilename for ignoring."
		else
			echo "\"$progname\" ignored."
		fi
	fi
done

if $res
then
	echo "[FAIL]"
	exit 1
else
	echo "[PASS]"
	exit 0
fi

