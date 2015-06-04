#!/bin/bash
#
# ADPassMonHelper.sh
#
# run on casper login trigger, check if user is AD
# writes adpassmon prefs and launches ADPassMon if so.
#
# macmule's fork - https://macmule.com/2014/04/01/announcing-adpassmon-v2-fork/
# 

adpassmon="/Applications/Utilities/ADPassMon.app"
userloggedin="${3}"

expireage=${4}
passwordpolicytext="${5}"

uniqueid=$(echo $(dscl . read /Users/${userloggedin} UniqueID 2> /dev/null | awk '{print $2}'))

if [ -z "${uniqueid}" ] || (( ${uniqueid} > 1000 )) # if user doesn't exist in localds, or uid is > 1000 - network user
then
	echo "${userloggedin} is an AD account" 
	if [ -f "${adpassmon}/Contents/MacOS/ADPassMon" ]
	then
		echo "writing ADPassMon preferences ..."
		sudo -u ${userloggedin} defaults write org.pmbuko.ADPassMon expireAge -int ${expireage} 	
		sudo -u ${userloggedin} defaults write org.pmbuko.ADPassMon pwPolicy -string "${passwordpolicytext}"
		sudo -u ${userloggedin} defaults write org.pmbuko.ADPassMon selectedBehaviour -int 2
		sudo -u ${userloggedin} defaults write org.pmbuko.ADPassMon prefsLocked -bool true
		echo "launching ADPassMon ..."
		sudo -u "${userloggedin}" "${adpassmon}/Contents/MacOS/ADPassMon" &
	else
		echo "ADPassMon is NOT installed, doing nothing"
	fi
else
	echo "${userloggedin} is a local user, doing nothing"
fi
exit 0
