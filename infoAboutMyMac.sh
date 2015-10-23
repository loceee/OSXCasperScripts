#!/bin/bash
#
# what's my ip and stuff
#
# run me from a self service policy (handy if windows guys need to VNC on for remote support)

displayDialog()
{
	osascript -e "tell app \"System Events\"" -e "activate" -e "display dialog \"$message\" with title \"Information about your Mac\" buttons {\"OK\"}" -e "end tell"
}

makeMessage()
{
	message="$message\n$1"
}

myip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
compname=$(scutil --get ComputerName)
username=$(who | grep console | awk '{print $1}')

makeMessage "User:			$username"
makeMessage "IP address: 		$myip"
makeMessage "Computer Name:	$compname"

displayDialog "$message" &

exit
