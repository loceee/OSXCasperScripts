#!/bin/bash
#
# superrecon2.sh
#
# scrape directory for user & location info - add it to recon (jss will now look up AD info, we don't need to)


userloggedin="$(who | grep console | awk '{print $1}')"
adcheck=$(dscl . read /Users/${userloggedin} AuthenticationAuthority | grep LocalCachedUser)

if [ -z "${adcheck}" ]
then
	echo "superRecon - ${userloggedin} is a Local Account"
	echo "------------------------------------------------------------------------"
	jamf recon -endUsername "${userloggedin}" -position "Local Account"
else
	echo "supeRecon - ${userloggedin} is an AD Account"	
	echo "------------------------------------------------------------------------"
	jamf recon -endUsername "${userloggedin}"
fi

exit 0
