#!/bin/bash

# home network share mapping script
# run at login, scoped to LDAP groups in casper

# we may be running this via self service $3 may not be populated
userloggedin="$(who | grep console | awk '{print $1}')"

adcheck=$(dscl . read /Users/${userloggedin} AuthenticationAuthority | grep LocalCachedUser)
[ -z "${adcheck}" ] && exit 0

homepath=$(dscl . read /Users/${userloggedin} SMBHome | awk '{print $2}' | tr '\\' '/')
[ -z "${homepath}" ] && exit 0

homepath="smb:${homepath}" # append smb://

mountShare()
{
	share="${1}"
	urlshare="${share// /%20}" # swap out ' ' for %20
	echo "mounting ${share} ..."
	# we are assuming all is kerberized, but Finder can take care of credentials that aren't
	#osascript -e "tell app \"Finder\"" -e "activate" -e "open location \"${urlshare}\"" -e "end tell"
	osascript -e "try" -e "mount volume \"${urlshare}\"" -e "on error" -e "end try"
}

# wait for the Finder (we are running a login trigger)

until pgrep Finder > /dev/null
do
	sleep 2
done

mountShare "${homepath}"

exit 0
