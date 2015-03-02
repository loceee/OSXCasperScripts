#!/bin/bash
#
# enable ssh admin lock to adminuer

adminuser="${4}"

[ -z "${adminuser}" ] && adminuser="admin"


# turn on ssh
systemsetup -setremotelogin on

# create the sacl group
dseditgroup -o create -q com.apple.access_ssh

# add adminuser to the sacl group
dseditgroup -o edit -a ${adminuser} -t user com.apple.access_ssh

exit 0