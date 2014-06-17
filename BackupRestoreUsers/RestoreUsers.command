#!/bin/bash
####################################################################
#
# a basic wrapper script for backup and restore users
#
# .command so that it can be launched by double clicking
# and it will sudo the script it's calling to ensure that the we
# execute as root!
#
####################################################################
script="BackupRestoreUsers.sh"

### go ###
basedir=`dirname "$0"`

clear
echo ""
echo "** Running $script **"
echo ""
echo "This script must be excuted with root privleges"
echo ""
echo ""
echo "	Please ensure you have:"
echo ""
echo "			1. READ THE DOCs"
echo "			2. Configured $script for your environment"
echo ""
echo ""
echo "To continue please enter your admin password and press <enter>"
echo ""
sudo "$basedir/$script" / --restore
exit
