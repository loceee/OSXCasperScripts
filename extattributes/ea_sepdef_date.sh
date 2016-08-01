#!/bin/bash
#
# get date of SEP defs
# http://github.com/loceee
#

sepsupportpath="/Library/Application Support/Symantec/Antivirus"

for defdir in "${sepsupportpath}"/*
do
	# if we've found the folder with the whatnew.txt - start scraping date
	if [ -d "${defdir}" ] && [ -f "${defdir}/whatsnew.txt" ]
	then
		defdate=$(date -j -f "%b %d, %Y" "$(grep -e "Symantec Security" "${defdir}/whatsnew.txt" | awk '{print $5, $6, $7}')" "+%Y-%m-%d")
	fi
done

# if defdate isn't blank we've got a date
if [ ${defdate} ]
then
	result=${defdate}
else
	result="Unknown"
fi

echo "<result>${result}</result>"
exit
