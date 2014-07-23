#!/bin/bash
# get date of SEP defs

seppath="/Library/Application Support/Symantec/Antivirus"

for defdir in $(ls -tr "$seppath")
do
	if [ -d "$seppath/$defdir" ] && [ -f "$seppath/$defdir/whatsnew.txt" ]
	then
		defdate=$(date -j -f "%b %d, %Y" "$(cat "$seppath/$defdir/whatsnew.txt" | grep "Symantec Security" | awk '{print $5, $6, $7}')" "+%Y-%m-%d")
	fi
done
if [ $defdate ]
then
	result=$defdate
else
	result="unknown"
fi

echo "<result>$result</result>"
