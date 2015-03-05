#!/bin/bash
# dockBuilder.sh - build a new Dock with dockutil
# https://github.com/loceee/OSXCasperScripts 
#
# dockutil is awesome - https://github.com/kcrawford/dockutil
# 				- https://patternbuffer.wordpress.com

# dockBuilder is a helper to progmatically build docks
# use as part of your build process, or nuke all users docks if you are a meanie.
#
#
# not enough param slots? chain scripts together --set xx xx xx xx --end

IFS=$'\n'

dockutil="/Library/Management/bin/dockutil"
template="/System/Library/User Template/English.lproj"

paramarray=(
	"${4}"
	"${5}"
	"${6}"
	"${7}"
	"${8}"
	"${9}"
	"${10}"
	"${11}"
	)

# dockutil freaks out without an existing pref file, copy in the default
[ ! -f "${template}/Library/Preferences/com.apple.dock.plist" ] && \
	cp "/System/Library/CoreServices/Dock.app/Contents/Resources/en.lproj/default.plist" \
	"${template}/Library/Preferences/com.apple.dock.plist"

for param in ${paramarray[@]}
do
	if [ -n "${param}" ]
	then
		case "${param}" in

			"--reset" )
				echo "dockBuilder! resetting user template"
				"${dockutil}" --remove all --no-restart "${template}"
			;;

			"--reset-allhomes" )
				touch "/tmp/.dockbuilder-allhomes"
				echo "dockBuilder! resetting user template"
				"${dockutil}" --remove all --no-restart "${template}"
				echo "resetting all users docks"
				"${dockutil}" --remove all --no-restart --allhomes
			;;

			"--end" )
				# if we are nuking all docks, restart if users logged in.
				if [ -f "/tmp/.dockbuilder-allhomes" ] 
				then
					[ -n "$(pgrep Dock)" ] && killall Dock
					rm "/tmp/.dockbuilder-allhomes" 
				fi
			;;

			* )
				# everything else must be items to go in the dock
				echo "adding ${param} ..."
				"${dockutil}" --add "${param}" --no-restart "${template}"
				[ -f "/tmp/.dockbuilder-allhomes" ] && "${dockutil}" --add "${param}" --no-restart --allhomes
			;;

		esac
	fi
done

exit
