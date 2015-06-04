#!/bin/bash
# cfguserShareAlias.sh
# this script will create aliases for all mounted shares (grep username) in target
# default ~/Documents/Servers
# 

loggedinuser="${3}"
target="${4}"

# if you'd like to add your target to dock, point me a dockutil
dockutil="/Library/Management/bin/dockutil"

IFS=$'\n'

[ -z "${target}" ] && target="~/Documents/Servers"

abshome=$(dscl . read /Users/${loggedinuser} NFSHomeDirectory | awk '{print $2}') 

target=$(echo ${target} | sed "s|~|${abshome}|g") # switch to abs path, applescript and ~  = blerg

[ ! -d "${target}" ] && sudo -u ${loggedinuser} mkdir -p "${target}"

mountedsharearray=( $(mount | grep ${loggedinuser}@ | cut -d' ' -f3- | rev | cut -d'(' -f2- | rev | sed 's/ *$//') )

# no shares mounted, exit without deleting aliases
[ ${#mountedsharearray[@]} == 0 ] && exit 

# remove existing symlinks - don't delete an icon file if it's there
find "${target}/" -type f -not \( -name "Icon*" -xattrname com.apple.ResourceFork \) -delete

sleep 2

# ensure the finder has started
until pgrep Finder > /dev/null
do
	sleep 2
done


for volname in ${mountedsharearray[@]}
do
	echo "creating alias for ${volname} .."
	sudo -u ${loggedinuser} osascript -e "tell application \"Finder\" to make alias file to POSIX file \"${volname}\" at POSIX file \"${target}\"" > /dev/null
done

# if we have dockutil, add it to the dock
if [ -f "${dockutil}" ]
then
	targettile="$(basename ${target})"
	if [ "$(${dockutil} --find "${targettile}" "${abshome}" | grep "was found")" == "" ]
	then
		echo "Adding ${targettile} to Dock ..."
		${dockutil} --add "${target}" --display folder --view grid "${abshome}"
	fi
fi
exit
