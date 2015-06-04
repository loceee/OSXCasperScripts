#!/bin/bash
#
# superrecon2.sh
#
# scrape directory for user & location info

userloggedin="$(who | grep console | awk '{print $1}')"
adcheck=$(dscl . read /Users/${userloggedin} AuthenticationAuthority | grep LocalCachedUser)

if [ -z "${adcheck}" ]
then
	echo "superRecon - ${userloggedin} is a Local Account"
	echo "------------------------------------------------------------------------"
	jamf recon -endUsername "${userloggedin}" -position "Local Account" -realname "" -email "" -position "" -phone "" # blank out empty fields in jss.
else
	echo "supeRecon - ${userloggedin} is an AD Account"	
	echo "------------------------------------------------------------------------"
	userrealname=$(dscl . -read /Users/${userloggedin} original_realname 2> /dev/null | tail -1 | cut -d ' ' -f 2-)
	useremail=$(dscl . -read /Users/${userloggedin} EMailAddress 2> /dev/null | cut -d ' ' -f 2-)
	userposition=$(dscl . -read /Users/${userloggedin} JobTitle 2> /dev/null | tail -1 | cut -d ' ' -f 2-) # these keys may not be filed
	userphone=$(dscl . -read /Users/${userloggedin} PhoneNumber 2> /dev/null | tail -1 | cut -c 2-)
	jamf recon -endUsername "${userloggedin}" -realname "${userrealname}" -email "${useremail}" -position "${userposition}" -phone "${userphone}"
fi

exit 0
