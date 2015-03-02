#!/bin/bash
#
# set ARD and lock to user

adminuser="${4}"

[ -z "${adminuser}" ] && adminuser="admin"

echo "Kickstarting ARD and locking to ${adminuser}..."
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -allowAccessFor -specifiedUsers
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -users ${adminuser} -access -on -privs -all -agent -restart
exit 0