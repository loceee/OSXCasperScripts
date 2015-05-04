#!/bin/bash
#
# start casperimaging

casperimaging="/tmp/Casper Imaging.app"

cleanUpWhenDone()
{
	# wait for casperimaging to start, then kill installer.app
	while [ "$(pgrep "Casper Imaging")" == "" ]
	do
		sleep 1
	done
	sleep 3
	killall Installer

	# wait for casperimaging to close then delete tmp app
	while [ "$(pgrep "Casper Imaging")" != "" ]
	do
		sleep 1
	done
	rm -r "${casperimaging}"	
}

sudo open "${casperimaging}" &

#cleanUpWhenDone & # spawn this

exit 0
