#!/bin/bash
#
# cfgCasper
# 
# i disable the setup assistant and registration wizards 
#

target=$1
computername=$2
username=$3

echo "Disabling setup and reg assistant..."
touch $target/Library/Receipts/.SetupRegComplete
touch $target/private/var/db/.AppleSetupDone

exit 0
