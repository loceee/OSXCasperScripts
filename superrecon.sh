#!/bin/bash
#
# superrecon.sh
#
# scrape directory for user & location info - add it to recon
# lachlan.stewart@interpublic.com
# 0.1 - first release 
# 0.2 - jaymes.brimmer@mccannsf.com - Updated code for user info parsing
# 0.3 - thanks Jaymes, querying attrib direct via dscl is a much better approach! removed extraneous echos
# 	 	directed stderr to null so we don't see errors for unpopualted atributes (tidier) 

loggedinuser=$(ls -l /dev/console | awk '{ print $3 }')
accounttype=$(dscl . -read /Users/$loggedinuser OriginalNodeName 2> /dev/null | tail -1 | cut -c 2-)

echo "Reconning and submitting user information for $loggedinuser..."
echo "------------------------------------------------------------------------"

if [ "$accounttype" == "" ]
then
	userposition="Local Account"
	echo "Local Account"
	echo "------------------------------------------------------------------------"
	jamf recon -endUsername $loggedinuser -position "$userposition"
else
	userrealname=$(dscl . -read /Users/$loggedinuser original_realname 2> /dev/null | tail -1 | cut -d ' ' -f 2-)
	useremail=$(dscl . -read /Users/$loggedinuser EMailAddress 2> /dev/null | cut -d ' ' -f 2-)
	userposition=$(dscl . -read /Users/$loggedinuser JobTitle 2> /dev/null | tail -1 | cut -d ' ' -f 2-) # these keys may not be filed
	userphone=$(dscl . -read /Users/$loggedinuser PhoneNumber 2> /dev/null | cut -d ' ' -f 2-)
	echo "realname: 	$userrealname"
	echo "emailaddress: 	$useremail"
	echo "position: 	$userposition"
	echo "phone: 	$userphone"
	echo "------------------------------------------------------------------------"
	jamf recon -endUsername "$loggedinuser" -realname "$userrealname" -email "$useremail" -position "$userposition" -phone "$userphone"
fi

exit
