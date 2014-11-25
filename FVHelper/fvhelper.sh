#!/bin/bash
#
#
# Filevault Helper
#
#
# FVHelper leverages Casper's built FV handling (so we can use the GUI and key escrow)
# - adds some GUI
# - allows you to skip a management account(s)
# - call it at login trigger so we don't forget to enable FV
# - execute it via self service and it will logout for you
# - give users a few defers now
# - added --selfservice mode, skips user check and spawns (when spawning all runs you don't get meaninful logs back to jss)
# - change to jamfHelper for dialogs, too many broken scripting plugins on our fleet, causing issues displaying dialogs

skipusers=( "admin" ) 		# prevent these users from being prompted (your local management accounts etc.)
#fvpolicy="-id 1234"			# use either the policy id or a custom trigger of your FV policy.
fvpolicy="-trigger filevault"

# users can defer x fv enable prompts
defermode=true
deferthreshold=5

spawned="${1}" # used internally
username="${3}"
selfservice="${4}" # will spawn and skip username trip if not empty
[ "${username}" == "" ] && username="$(who | grep console | awk '{print $1}')" # if running from self service


# localise your prompts

msgprompthead="This Mac requires FileVault Encryption"
msgpromptenable="Enabling FileVault requires a restart.

Would you like to enable for ${username} ?"
msgpromptenableforce="Enabling FileVault requires a restart.

You MUST enable FileVault for ${username} NOW!"
msgenabled="FileVault has been enabled.

Your Mac will now logout, prompt you for your password and then restart to initiate the background encryption process."

dialogicon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FileVaultIcon.icns"
jamfhelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

prefs="/Library/Preferences/com.github.loceee.fvhelper"


checkProcess()
{
	if [ "$(ps aux | grep "${1}" | grep -v grep)" != "" ]
	then
		return 0
	else
		return 1
	fi
}

checkConsoleStatus()
{
	userloggedin="$(who | grep console | awk '{print $1}')"
	consoleuser="$(ls -l /dev/console | awk '{print $3}')"
	screensaver="$(ps aux | grep ScreenSaverEngine | grep -v grep)"

	if [ "${screensaver}" != "" ]
	then
		# screensaver is running
		echo "screensaver"
		return
	fi
	
	if [ "${userloggedin}" == "" ]
	then
		# no users logged in (at loginwindow)
		echo "nologin"
		return
	fi
	
	if [ "${userloggedin}" != "${consoleuser}" ]
	then
		# a user is loggedin, but we are at loginwindow or we have multiple users logged in with switching (too hard for now)
		echo "loginwindow"
		return
	fi

	# if we passed all checks, user is logged in and we are safe to prompt or display bubbles
	echo "userloggedin"
}


logoutUser()
{
	waitforlogout=30
	# sending appleevent seems most robust and fastest way, can still be blocked by stuck app (I'm looking at you MS Office and Lync)
	echo "sending logout ..."
	osascript -e "ignoring application responses" -e "tell application \"loginwindow\" to $(printf \\xc2\\xab)event aevtrlgo$(printf \\xc2\\xbb)" -e "end ignoring"

	while [ "$(checkConsoleStatus)" != "nologin" ]
	do
		for (( c=1; c<=${waitforlogout}; c++ ))
		do
			sleep 1
			# check if we've logged out yet, break if so, otherwise check every second
			[ "$(checkConsoleStatus)" == "nologin" ] && break
		done
		if [ "$(checkConsoleStatus)" != "nologin" ]
		then
			osascript -e "ignoring application responses" -e "tell application \"loginwindow\" to $(printf \\xc2\\xab)event aevtrlgo$(printf \\xc2\\xbb)" -e "end ignoring"
		fi
	done
	# we should have really logged out by now!
}

spawnScript()
{
	# we use this so we can execute from self service.app and call a logout with out breaking policy execution.
	# the script copies, then spawns itself 
	if [ "$spawned" != "--spawned" ]
	then
		tmpscript="$(mktemp /tmp/fvhelper.XXXXXXXXXXXXXXX)"
		cp "${0}" "${tmpscript}"
		# spawn the script in the background
		echo "spawned script $tmpscript"
		chmod 700 "${tmpscript}"
		"${tmpscript}" --spawned '' ${username} &
		exit 0
	fi
}

cleanUp()
{
	[ "$spawned" == "--spawned" ] && rm "${0}" 	#if we are spawned, eat ourself.
}

#
# Start the bidness
#

exitcode=0

# if self service, spawn and skip username check (perhaps we want to enable for this user)
if [ -n "${selfservice}" ]
then
	spawnScript
else
	for skipuser in ${skipusers[@]}
	do
		if [ "${username}" == "${skipuser}" ]
		then
			echo "${username} shouldn't be filevaulted by fvhelper, bye."
			cleanUp
			exit 0
		fi
	done
fi

# if starting on login trigger, wait for the finder to start

until checkProcess "Finder.app"
do
	sleep 3
done


if [ "$(fdesetup status | grep "FileVault is Off.")" == "FileVault is Off." ] # FV is off, lets prompt
then
	if [ "$(checkConsoleStatus)" == "userloggedin" ] # double check we have logged in user
	then
		if $defermode
		then
			# read defercounter if exists, write if not
			defercount=$(defaults read "${prefs}" DeferCount 2> /dev/null)
			if [ "$?" != "0" ]
			then
				defaults write "${prefs}" DeferCount -int 0
				defercount=0
			fi

			deferremain=$(( deferthreshold - defercount ))
			if [ ${deferremain} -eq 0 ] || [ ${deferremain} -lt 0 ]
			then
				filevaultprompt=$("${jamfhelper}" -windowType utility -heading "${msgprompthead}" -alignHeading center -description "${msgpromptenableforce}" -icon "${dialogicon}" -button1 "Enable..."  -defaultButton 1)
			else
				filevaultprompt=$("${jamfhelper}" -windowType utility -heading "${msgprompthead}" -alignHeading center -description "${msgpromptenable}
(You may defer ${deferremain} more times)" -icon "${dialogicon}" -button1 "Enable..."  -button2 "Later" -defaultButton 1 -cancelButton 2)
			fi
		else
			# no defer mode, just prompt
			filevaultprompt=$("${jamfhelper}" -windowType utility -heading "${msgprompthead}" -alignHeading center -description "${msgpromptenable}" -icon "${dialogicon}" -button1 "Enable..."  -button2 "Later" -defaultButton 1 -cancelButton 2)
		fi
		if [ "$filevaultprompt" == "0" ]
		then
			echo "jamf please call the fv policy"
			jamf policy ${fvpolicy}
			"${jamfhelper}" -windowType utility -description "${msgenabled}" -icon "${dialogicon}" -button1 "Ok" -defaultButton 1
			rm "${prefs}.plist"
			logoutUser
		elif [ "$filevaultprompt" == "2" ]
		then
			if $defermode
			then
				(( defercount ++ ))
				defaults write "${prefs}" DeferCount -int ${defercount}	
				echo "user skipped FV - defercounter: ${defercount}" 
			fi
		else
			echo "user skipped FV"
		fi
	else
		echo "there is no console user active, consolestatus: $(checkConsoleStatus)..."
	fi
else
	# if we've run this policy FV ISN'T off, the JSS isn't up to date so this mac hasn't falled out of the smart group, recon. this will run post-reboot.
	echo "FileVault is ON or encrypting, will recon to update JSS."
	jamf recon
fi

cleanUp
exit $exitcode
