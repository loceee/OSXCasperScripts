#!/bin/bash

# additional network share mapping script
# run at login, scoped to LDAP groups in casper

IFS=$'\n'

# we may be running this via self service $3 may not be populated
userloggedin="$(who | grep console | awk '{print $1}')"

adcheck=$(dscl . read /Users/${userloggedin} AuthenticationAuthority | grep LocalCachedUser)
[ -z "${adcheck}" ] && exit 0

sharearray=( "${4}" "${5}" "${6}" "${7}" "${8}" "${9}" "${10}" )

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


for share in ${sharearray[@]}
do
	[ ! -z "${share}" ] && mountShare "${share}"
done

exit 0
