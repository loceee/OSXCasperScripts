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
		defdatesecs=$(date -j -f "%b %d, %Y" "$(grep -e "Symantec Security" "${defdir}/whatsnew.txt" | awk '{print $5, $6, $7}')" "+%s")
	fi
done

# if defdate isn't blank we've got a date
if [ ${defdatesecs} ]
then
  currentdatesecs=$(date "+%s")
  # subtract from current date and convert back to days
  result=$(((currentdatesecs - defdatesecs)/60/60/24))
else
  # return a bogus days if missing
  result=999999
fi

echo "<result>${result}</result>"
exit
