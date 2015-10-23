#!/bin/bash
#
# turn on vnc for Mac

vncpassword="${4}"

if [ -n "${vncpassword}" ]
then
	echo "Kickstarting ARD enabling VNC..."
	/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -clientopts -setvnclegacy -vnclegacy yes -setvncpw -vncpw ${vncpassword} -restart -agent
fi
exit 0