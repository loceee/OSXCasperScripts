#!/bin/bash

# Get age of SEP definitions

sepPath="/Library/Application Support/Symantec/Antivirus"

if [ -f "$sepPath/Engine/WHATSNEW.TXT" ]; then
result=`/bin/date -j -f "%b %d, %Y" "$(cat "/Library/Application Support/Symantec/AntiVirus/Engine/WHATSNEW.TXT"
 | grep "Symantec Security Response" | awk '{print $5, $6, $7}')" "+%s"`
else

for subDir in `ls "$sepPath"`; do
if [ -d "$sepPath/$subDir" ] && [ -f "$sepPath/$subDir/whatsnew.txt" ] ; then
subdefDate=`/bin/date -j -f "%b %d, %Y" "$(cat "$sepPath/$subDir/whatsnew.txt" | grep "Symantec Security
 Response" | awk '{print $5" " $6" " $7}')" "+%s"`
fi
if [ $result ]; then
if [ $subdefDate -gt $result ]; then
result=$subdefDate
fi
else
result=$subdefDate
fi
done
fi

curDate=`date "+%s"`

defAge=`echo $(((curDate - result)/60/60/24))`

echo "<result>$defAge</result>"
