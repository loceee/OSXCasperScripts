#!/bin/bash
#
# postinstall-profileInstaller.sh
#
# because, derp - https://jamfnation.jamfsoftware.com/discussion.html?id=13997
IFS=$'\n'

for mobileconfig in /tmp/profiles/*
do
	profiles -I -F ${mobileconfig}
done

rm -R /tmp/profiles/

exit 0
