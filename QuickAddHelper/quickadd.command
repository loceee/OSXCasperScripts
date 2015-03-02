#!/bin/bash
tmpdir="/tmp/QuickAdd"
vol=$(cat ${tmpdir}/vol.tmp)
echo "ejecting ${vol}"
diskutil eject "${vol}"
echo -en "\007" # beep
echo
echo "Enter local admin password to enroll this Mac"
echo
sudo installer -verbose -pkg "${tmpdir}/QuickAdd.pkg" -target /
rm -R ${tmpdir}

if jamf checkJSSConnection
then
	say "Done"
	killall Terminal
else
	say "Error"
fi
exit 

