#!/bin/bash
#
# days since last Time Machine backup, 0 if not enabled
# scope < smart group to catch devices that are not backing up promptly
#
# - known issue with multiple destinations -
# - thanks here - https://jamfnation.jamfsoftware.com/discussion.html?id=8814

OS=$(sw_vers | awk '/ProductVersion/{print substr($2,1,5)}' | tr -d ".")

# check the OS
if [ "$OS" -ge "109" ]
then
	lastBackupTime=$(defaults read /Library/Preferences/com.apple.TimeMachine Destinations 2> /dev/null | sed -n '/SnapshotDates/,$p' | grep -e '[0-9]' | awk -F '"' '{print $2}' | sort | tail -n1 | cut -d" " -f1,2)
	#lastBackupTime=$(defaults read /Library/Preferences/com.apple.TimeMachine Destinations  2> /dev/null | sed -n '/SnapshotDates/,$p' | grep -A 1 -v "DestinationUUIDs" | grep -v "DestinationID" | grep -v "RootVolumeUUID" | grep -e '[0-9]' | awk -F '"' '{print $2}' | sort | tail -n1 | cut -d" " -f1,2)
else
	[ -f /private/var/db/.TimeMachine.Results.plist ] && lastBackupTime=$(defaults read /private/var/db/.TimeMachine.Results "BACKUP_COMPLETED_DATE" 2> /dev/null )
fi

if [ "${lastBackupTime}" != "" ]
then
	lastBackupSec=$(date -jf "%Y-%m-%d %H:%M:%S" "${lastBackupTime}" +"%s")
	curDate=$(date "+%s") # in seconds
	lastBackupAge=$(((curDate - lastBackupSec)/60/60/24)) # seconds to days
else
	lastBackupAge="0"
fi

# return days since last backup to JSS
echo "<result>${lastBackupAge}</result>"

