#!/bin/bash
version="0.99"
#
# BackupRestoreUsers
#
# INTERACTIVE MODE
# ----------------
# usage:
# 
# configure your backuprepo as below (default: backuproot="$(dirname "$0")/_UserBackups")
#
# or
#
# copy the script folder to a share, then launch script via the xxx.command wrappers.
#
# CASPER IMAGING MODE
#--------------------
# usage:
# as casper imaging is a little difficult with it's scripting workflows it goes like this.
#
# configure your backuprepo as below (either backuproot=/Volume/LocalHD, afpurl, smburl)
# or
# use the network segment section so you can find the nearest backupserver automatically.
#
# set 'caspermode=true'
# uncomment 'mode="backup"'
# 	save as 'BackupRestoreUsers-backup.sh'
# do the same for 'mode="restore"'
# 	save as 'BackupRestoreUsers-restore.sh'
#
# you should now have 2 scripts, a backup and restore mode script.
#
# upload both Casper Admin repo.
#
# allocate it to a configuration
#
# get info set the -backup.sh to run BEFORE, and -restore.sh to run AFTER
#
#
# CDP mode
# ---------
# If you had an additonal UserBackup share on your CDPs, you can set the script
# to cdpmode=true, it will look for a mounted "CasperShare" (set in $caspersharename)
# and then attempt to mount and backup/restore to/from that server/share using the
# supplied credentials. In a multisite install this could be helpful and reduce config
# and admin overhead --- findServer - function assumes afp CDP. adjust as you see fit
#
#
# more info lachlan.stewart@interpublic.com
##############################################################


###############################
#
# configure from here
#
###############################

caspermode=false			# enable casper imaging mode (auto - nooptions to restore a different backup, logs log and doesn't recognise command switches)
#mode="backup"				# set mode for use with casper - set priority to run before
#mode="restore"				# set mode for use with casper - set priority to run after

userfolder="/Users"
altuserpart="/Volumes/Data"	# watch for this user partition/path and use if seen (good if using fstab method to mount a userpartion eg. "/Volumes/UserHD/Users")
excludedusers="^\.|Shared|Deleted Users|admin|Library"	# first line excludes all files starting with "." add anymore here...
restoreto="$userfolder"

showlog=true			# open the log during

rsyncexcludes=( ".Spotlight-V100" ".fseventsd" ".TemporaryItems" "**/Library/Application Support/Google/Chrome/Safe Browsing Download/**" ) # exclude any know troublesome files from copy

debug=false				# dump to debuglog - very verbose - just for me.

###############################
#
# backup repo config
#
###############################

#
# cdp mode
#

cdpmode=false
caspersharename="CasperShare"	# share name to grep mount for, find your cdp mount
userbackupcredentials="userbackup:userbackup"	# username:password to mount userbackup share from mounted cdp
userbackupshare="UserBackup"

#
# manual backuproot
#

backuproot="$(dirname "$0")/_UserBackups"		# backup to ./_UserBackups/ in this script folder

# single network destinations
# ----------------------------
#    afp://[username:password]@rhost[:port]/volume
#afpurl="afp://username:password@servername/backup"
#   //[domain;][user[:password]@]server[/share] path
#smburl="//username:password@servername/backup"

# network segment specific destinations
# --------------------------------------
# edit the xxx.xxx.xxx and associated xxxurl=
# 
# or (comment out networksegment to disable)

#networksegment=$(ipconfig getifaddr en0 | cut -d. -f1-3)	# ip and cut last quad for network segment

if [ "$networksegment" != "" ]
then
	case $networksegment in
		10.132.11 )
			# site1
			afpurl="afp://userbackup:userbackup@server1.domain.com/UserBackup"
			;;
		10.128.15 )
			# site2 
			afpurl="afp://userbackup:userbackup@server2.domain.com/UserBackup"
			;;
		10.132.9 )
			# site3  	
			afpurl="afp://userbackup:userbackup@server3.domain.com/UserBackup"
			;;
		10.132.108 | 10.128.20 | 10.132.3 | 10.132.12 )
			# site4 - handle multi matches like this
			afpurl="afp://userbackup:userbackup@server4.domain.com/UserBackup"
			;;
		*)
			# default fallback
			echo "Unhandled network segment -- $networksegment - using default"
			afpurl="afp://userbackup:userbackup@mainserver/UserBackup"
			;;
	esac
fi

scriptname="BackupRestoreUsers"

#####################################
#
#  End of configurable settings
#
#####################################

#
# some common fuctions
#

secho()
{
	# superecho - writes to log and will display a dialog to gui with timeout (a kludge for UI feedback in CI)
	message="$1"
	dialogtimeout="$2"
	echo "$message"
	echo "$message" >> "$logto/$log"
	[ "$dialogtimeout" != "" ] && osascript -e "tell app \"System Events\"" -e "activate" -e "display dialog \"$message\" buttons {\"...\"} giving up after $dialogtimeout" -e "end tell" > /dev/null
}

errorHander()
{
	# Error function
	message="$1"
	secho "ERROR: $message"
	osascript -e "tell app \"System Events\"" -e "activate" -e "display dialog \"$message\" buttons {\"OK\"} default button {\"OK\"} with title \"Error\"" -e "end tell" > /dev/null
	cp "$logto/$log" "$backuppath/$log.ERROR.log"
	rm "$logto/$log"
	killall "Casper Imaging"
	exit 1
}

askQuestion()
{
	message=$1
	button1=$2	#default
	button2=$3
	timeout=$4	#will return default after
	# we'll follow apple convention... default button should be right bottommost (button1)
	if [ "$timeout" != "" ]
	then
		buttonreturn=$(osascript -e "tell app \"System Events\"" -e "activate" -e "display dialog \"$message\n\n\n(Default: $button1 in $timeout secs)\" buttons {\"$button2\",\"$button1\"} default button {\"$button1\"} giving up after $timeout" -e "end tell")
	else
		# no timeout.. important questions
		buttonreturn=$(osascript -e "tell app \"System Events\"" -e "activate" -e "display dialog \"$message\" buttons {\"$button2\",\"$button1\"} default button {\"$button1\"}" -e "end tell")
	fi	
	[ "$(echo $buttonreturn | grep "gave up:true")" != "" ] && result=1 	# timeout, return default 1
	[ "$(echo $buttonreturn | grep -w "$button1")" != "" ] && result=1
	[ "$(echo $buttonreturn | grep -w "$button2")" != "" ] && result=2
	echo $result
}

#
# core brains
#

findServer()
{
	server=$(mount | grep $caspersharename | cut -d'@' -f2- | cut -d':' -f-1)
	# if there was no mount with caspershare, don't set afp url
	[ "$server" != "" ] && afpurl="afp://$userbackupcredentials@$server/$userbackupshare"
}


mountShare()
{
	# this code is for automounting network shares, if running the script via ARD / Casper Imaging / DeployStudio
	# lets try to mount network volume, no error checking here... expecting properly formed urls to be passed to mount_afp/smb
	secho "Mounting the network share..." 1
	share=$(echo "$networkbackuppath" | cut -d'/' -f 4-)
	mountpath="/Volumes/$share"
	mkdir "$mountpath"
	# check if afp or smb
	if [ "$afpurl" != "" ]
	then
		mount_afp "$afpurl" "$mountpath"
		mounterror="$?"
	fi
	if [ "$smburl" != "" ]
	then
		mount_smb "$smburl" "$mountpath"
		mounterror="$?"
	fi
	if [ "$mounterror" != "0" ]
	then
		errorHander "There was a problem mounting the network share $share - mount_afp/smb returned $mounterror"
		exit 1
	fi
	backuproot="$mountpath/_UserBackups"
	[ ! -d "$backuproot" ] && mkdir "$backuproot"
	# end network mount
}

unmountShare()
{
	 #if we are using a network share, unmount it
	cd /
	secho "Unmounting $mountpath" 1
	sleep 1
	umount "$mountpath"

	if [ "$?" != "0" ]
	then
		echo "Forcing unmount"
		diskutil unmount force "$mountpath"
		if [ "$?" != "0" ]
		then
			errorHander "There was a problem unmounting $backuproot"
		fi
	fi
}

excludeUsers()
{
	while true
	do
		# generate a dialog message for exlusions
		message=$(
			echo -ne "Would you like to exclude any users?\n"
			echo -ne "\n"
			echo -ne " Users to backup\n"
			echo -ne "-------------------------\n"
			echo -ne "\n"
			for user in $(ls $userfolder | grep -vE "$excludedusers")
			do
				echo -ne "$user "
				if [ -f "$userfolder/.$user-excluded" ]
				then
					echo -ne " - EXCLUDED\n"
				else
					echo -ne "\n"
				fi
			done
		)
		answer=$(askQuestion "$message" "Start Backup" "Exclude Users" 15)
		if [ "$answer" == "2" ]
		then
			for user in $(ls $userfolder | grep -vE "$excludedusers")
			do
				answer=$(askQuestion "User:\n\n$user\n" "Include" "Exclude")
				if [ "$answer" == "1" ]
				then
					# remove exclusion if it exists
					[ -f "$userfolder/.$user-excluded" ] && rm "$userfolder/.$user-excluded"
				else
					# flag them as excluded
					touch "$userfolder/.$user-excluded"
				fi
			done
		else
			# don't exclude anymore
			break
		fi
	done
}

chooseUserfolder()
{
	# in case you User partition isn't found, GUI to select a difference backup source
	answer=$(askQuestion "Do you want to backup from:\n\n\n$userfolder" "Yes" "Choose different..." 20)
	if [ "$answer" == "2" ]
	then
		newuserfolder=$(/usr/bin/osascript << EOT
			tell application "Finder"
			    activate
			    set theFolder to (choose folder with prompt "Choose another /Users folder to backup:")
			    return (POSIX path of theFolder)
			end tell
			EOT)
	fi
	# if a new location is chosen, use it
	[ ! -z "$newuserfolder" ] && userfolder="$newuserfolder"
}

chooseBackup()
{
	while true
	do
		# generate a dialog message for backuplist
		message=$(
		echo -ne " Available Backups\n"
		echo -ne "-------------------------\n"
		echo -ne "\n"
		[ -f "$backuproot/.DS_Store" ] && rm "$backuproot/.DS_Store" # just in case someone has been poking around in Users)
		for backupid in $(ls "$backuproot")
		do
			echo -ne "$backupid\n"
		done
		)
		answer=$(askQuestion "$message" "Select a Backup..." "Quit")
		if [ "$answer" == "1" ]
		then
			for backupid in $(ls "$backuproot")
			do
				answer=$(askQuestion "BackupID: $backupid" "Next" "Select")
				if [ "$answer" == "2" ]
				then
					# set new backup
					uniqueid="$backupid"
					backuppath="$backuproot/$uniqueid"
					backupsettings="$backuppath/BackupSettings"
					return 0					
				fi
			done
		else
			# jump out 
			return 2
		fi
	done
}

backupUsers()
{
	[ -d "$altuserpart" ] && userfolder="$altuserpart" # if we find alternate user partion, point at it

	if $caspermode
	then
		# if we wish to run an automated image, skipping backup... touch /Users/.nobackup before executing script
		# but double check before skpping the backup.
		if [ -f "$userfolder/.nobackup" ]
		then
			answer=$(askQuestion "### This Mac has been flagged NOT to Backup ###\n\n($userfolder/.nobackup exists)" "Don't Backup - WIPE IT ALL" "Remove flag and continue..." 30)
			if [ "$answer" == "1" ]
			then
				# flag to save us checking for backups to restore post imaging
				touch "/tmp/.nobackup-$uniqueid"
				return 0
			else	
				# remove the flag and run as normal
				rm "$userfolder/.nobackup"
			fi
		fi

		answer=$(askQuestion "Do you want to backup user data on this Mac?" "Backup" "Don't Backup" 20)
		if [ "$answer" == "2" ]
		then
			answer=$(askQuestion "Are you really sure?\n\nAll user data will be LOST!" "Backup" "Wipe it ALL!")
			if [ "$answer" == "2" ]		
			then
				# flag to save us checking for backups after restore
				touch "/tmp/.nobackup-$uniqueid"
				return 0
			fi
		fi
	fi

	# Check to see if there is an existing backup for this Mac
	if [ -d "$backuppath" ]
	then
		# check to see if it's complete
		if [ "$(defaults read $backupsettings BackupComplete)" != "1" ]
		then
			# if there is an incomplete backup, prompt... default to overwrite.. or give option to abort and sort it out.
			answer=$(askQuestion "There is an INCOMPLETE backup, would you like to overwrite it?" "Backup and Overwrite" "Abort" 20)
			[ "$answer" == "2" ] && errorHander "There is already a backup @ $backuppath ... Aborting..."
		else
			# if there is an COMPLETE backup, prompt... default to abort.. or give option to overwrite...
			if [ "$(defaults read $backupsettings HasBeenRestored)" == "1" ]
			then
				answer=$(askQuestion "There is an existing COMPLETE backup which HAS been restored, would you like to overwrite it?" "Backup and Overwrite" "Abort" 20)
				[ "$answer" == "2" ] && errorHander "There is already a backup @ $backuppath ... Aborting..."
			else
				answer=$(askQuestion "WARNING! There is an existing COMPLETE backup which HAS NOT been restored, would you like to overwrite it?" "Abort"  "Backup and Overwrite" 60)
				[ "$answer" == "1" ] && errorHander "There is already a backup @ $backuppath ... Aborting..."
			fi
		fi
		# remove the old / existing backup
		rm -R "$backuppath"
	fi

	chooseUserfolder

	excludeUsers

	answer=$(askQuestion "Would you like to flush user Trashes?" "Flush" "Don't Flush" 5)
	if [ "$answer" == "1" ]
	then
		flushtrash=true
	else
		flushtrash=false
	fi

	#answer=$(askQuestion "Would you like to flush user Caches?" "Flush" "Don't Flush" 5)
	#if [ "$answer" == "1" ]
	#then
	#	flushcache=true
	#else
	#	flushcache=false
	#fi

	# make paths and copy the logs to the server so we don't run out of space
	mkdir "$backuppath"
	mkdir "$backuppath/logs"
	cp "$logto/$log" "$backuppath/logs/$log"
	rm "$logto/$log"
	logto="$backuppath/logs"

	secho
	secho "Backing up $uniqueid"
	secho
	secho "Scanning and sizing home folders ..." 2
	secho "--------------------------------------"
	secho

	# open the log in console for more feedback
	[ $showlog ] && open "$logto/$log"

	usercount=0
	totalsize=0

	# get all the user folders in /User, process them and get size in bytes
	for user in $(ls $userfolder | grep -vE "$excludedusers")
	do
		if [ ! -f "$userfolder/.$user-excluded" ]	# check if they are excluded
		then
			
			if $flushtrash
			then
				secho "Flushing Trash for $user..."
			 	rm -R "$userfolder/$user/.Trash"
			fi
			
			#if $flushcache
			#then
			#	secho "Flushing Trash for $user..."
			# 	rm -R "$userfolder/$user/Library/Caches/"
			#fi

			secho "Sizing home for $user..."
			size=$(( $(du -sk "$userfolder/$user" | awk '{print $1}') * 1024 ))
			secho "$user - $(($size  / 1024 / 1024 )) MB" 2 
			userarray[$usercount]="$user"
			sizearray[$usercount]="$size"
			totalsize=$(( $totalsize + $size ))
			(( usercount ++ ))
		else
			secho "$user - EXCLUDED"
		fi
	done

	# get free space on back up disk
	backupfree=$(( $(df -k "$backuproot" | tail -n1 | awk '{ print $4 }') * 1024 ))

	secho "----------------------------------------------------------------------------------"
	secho "Total for $usercount user(s) is $(( $totalsize / 1024 / 1024 )) MBs - Free space on backup volume is $(( backupfree / 1024 / 1024 )) MBs" 2
	secho "----------------------------------------------------------------------------------"
	if [ $totalsize -gt $backupfree ]
	then
		answer=$(askQuestion "There may not be enough free space on Backup volume" "Continue" "Stop" 30)
		if [ "$answer" == "2" ]		
		then
			# error out ...
			errorHander "There is not enough space on the backup volume."
		else
			secho "WARNING: Ignoring free space error... I sure hope you know what you are doing!"
		fi
	fi

	before=$(date +%s)
	backuptogo=$totalsize
	for (( i = 0 ; i < $usercount ; i++ ))
	do
		user="${userarray[$i]}"
		usersize="${sizearray[$i]}"
		usersettings="$backuppath/Users/$user/UserSettings"
		# write some details about the user
		defaults write $usersettings UserSize -string $usersize
		# this reads the local ds via localonly (reads ds on target disk - not the system we are booted from)
		networkusertest=$(dscl -f "$dslocal" localonly  -read "/Local/Default/Users/$user" AuthenticationAuthority | grep LocalCachedUser) 
		if [ "$networkusertest" != "" ]
		then
			defaults write $usersettings NetworkUser -bool true
			usertype="Network User"
		else
			defaults write $usersettings NetworkUser -bool false
			usertype="Local User"
		fi
		secho
		secho "Backing up ($(( $i + 1 ))/$usercount): $user - $((  $usersize / 1024 / 1024 ))/$((  $backuptogo / 1024 / 1024 )) MBs - $usertype" 2
		secho "-------------------------------------------------------------------"
		mkdir -p  "$backuppath/Users/$user"
		imagesize=$(( $usersize + (( $usersize / 4 )) )) # add 25% of padding to vol size
		# create a sparse image on the backup store
		secho "Creating image for $user of size $(( $imagesize / 1024 / 1024 )) MBs..." 1
		hdiutil create -size ${imagesize} -type SPARSE -fs HFS+J -volname _backup_$user "$backuppath/Users/$user/$user.sparseimage" 2>> "$logto/$log"
		error="$?"
		if [ "$error" != "0" ]
		then
			errorHander "Error creating backup image for $user - hdiutil returned error: $error"
		fi
		# attach our new image
		hdiutil attach -owners on "$backuppath/Users/$user/$user.sparseimage" 2>> "$logto/$log"
		if [ "$error" != "0" ]
		then
			errorHander "Error attaching backup image for $user - hdiutil returned error: $error"
		fi
		# write our rsync exclude file
		for rsyncexclude in ${rsyncexcludes[@]}
		do
			echo "$rsyncexclude" >> /tmp/rsync-excludes.txt		
		done
		# rsync all data
		rsync $rsyncopts -aE --log-file="$logto/$log" --exclude-from="/tmp/rsync-excludes.txt" "$userfolder/$user/" "/Volumes/_backup_$user/$user/"
		error="$?"
		rm /tmp/rsync-excludes.txt	
		
		# rsync error handler - we can ignore a couple of common errors
		if [ "$error" != "0" ]
		then
			case $error in
				23)
					secho "rsync error 23 - some files were inaccessible (probably in use)"
					;;
				24)
					secho "rsync error 24 - some files disappeared during rsync"
					;;
				12)
					errorHander "Problem backing $user, out of disk space"
					;;
				*)
					errorHander "Problem backing up $user, rsync returned error: $error"
					;;
			esac
		fi
		secho "Ejecting /Volumes/_backup_$user ..."
		diskutil eject "/Volumes/_backup_$user"
		[ "$?" != "0" ] && errorHander "There was a problem ejecting /Volumes/_backup_$user"
		# decrement our backupdata to go...
		backuptogo=$(( $backuptogo - $usersize ))	
	done
	after=$(date +%s)
	totalsecs=$(( $after - $before ))
	#  echo "Completed in $(($diff / 60)):$(($diff % 60)) min:secs"
	totaltime="$(date -r $totalsecs +%M:%S) secs"

	[ $showlog ] && killall Console

	defaults write $backupsettings BackupDate -string "$(date)"
	defaults write $backupsettings TotalTime -string "$totaltime"
	defaults write $backupsettings TotalSize -string "$totalsize"
	defaults write $backupsettings HasBeenRestored -bool false
	defaults write $backupsettings BackupComplete -bool true

	secho
	secho "=========================================="
	secho " Completed $(( $totalsize / 1024 / 1024 )) MBs in $totaltime" 3
	secho "=========================================="
	secho "finished: $(date)"
	secho
	secho "NOTE: this script only backs up User folders in $userfolder"
	secho "      any files outside of this have NOT been backup up."
	secho
}


restoreUsers()
{
	# check for no backup flag
	if [ -f "/tmp/.nobackup-$uniqueid" ]
	then
		secho "No backup performed for $uniqueid..." 2
		rm "/tmp/.nobackup-$uniqueid"
		return 0
	fi

	while true
	do
		if [ -d "$backuppath" ] # if there is a backup for this mac restore
		then
			#if its already been restored, error out
			if [ "$(defaults read $backupsettings HasBeenRestored)" == "1" ]
			then
				answer=$(askQuestion "Backup $uniqueid has already been restored" "Continue with Restore" "Choose another backup..." )
				if [ "$answer" == "2" ]
				then
					# to choose another... reset backup path and reloop
					backuppath=""
					continue
				fi
			fi
			backupdate=$(defaults read $backupsettings BackupDate)
			totaltime=$(defaults read $backupsettings TotalTime)
			totalsize=$(defaults read $backupsettings TotalSize)
			if ! $caspermode
			then
				# if we are in interactive mode.. present options
				# read in backup details and make a dialog message
				message=$(
					echo -ne "Backup Details\n--------------------\n$uniqueid\nTotalsize: $(( $totalsize / 1024 / 1024 )) MBs\nCompleted in: $totaltime"
					echo -ne "\n\n"
					echo -ne "Users\n"
					echo -ne "------\n"
					#
					# read in all the backups on the store
					#
					[ -f "$backuppath/Users/.DS_Store" ] && rm "$backuppath/Users/.DS_Store" # just in case someone has been poking around in Users
					for backupuserfolder in $(ls "$backuppath/Users/")
					do
						user=$(basename $backupuserfolder)
						usersize=$(defaults read "$backuppath/Users/$backupuserfolder/UserSettings" UserSize)
						echo -ne "$user - $(( $usersize / 1024 / 1024 )) MBs\n"
					done
					echo -ne "\n\n"
				)
				answer=$(askQuestion "$message" "Restore" "Choose another backup..." )
				if [ "$answer" == "2" ]
				then
					# to choose another... reset backup path and reloop
					backuppath=""
					continue
				fi
			fi
			
			# ask to remove backup, do it before we start the restore so it can be unattended
			answer=$(askQuestion "Would you like to delete the backup once it has been restore successfully?" "Delete Backup" "Keep" 20)
			if [ "$answer" == "1" ]
			then
				removebackup=true
			else
				removebackup=false
			fi

			# do the restore
			cp "$logto/$log" "$backuppath/logs/$log"
			rm "$logto/$log"
			logto="$backuppath/logs"

			# open the log in console for more feedback
			[ $showlog ] && open "$logto/$log"
			
			secho "$uniqueid - Restore size: $(( $totalsize / 1024 / 1024 )) MBs" 2
			secho	
			before=$(date +%s)
			backuptogo=$totalsize
			[ -f "$backuppath/Users/.DS_Store" ] && rm "$backuppath/Users/.DS_Store" # just in case someone has been poking around in Users
			for userroot in "$backuppath/Users/"*
			do
				user=$(basename $userroot)
				usersettings="$backuppath/Users/$user/UserSettings"
				usersize=$(defaults read $usersettings UserSize)
				if [ "$(defaults read $usersettings NetworkUser)" == "1" ]
				then
					usertype="Network"
				else
					usertype="Local"
				fi
				secho
				secho "Restoring: $user  $(( $usersize / 1024 / 1024 ))/$(( $backuptogo / 1024 / 1024 )) MBs - $usertype account" 2
				secho "-------------------------------------------------------------------"
				
				hdiutil attach -owners on "$userroot/$user.sparseimage" 2>> "$logto/$log"
				error="$?"
				if [ "$error" != "0" ]
				then
					errorHander "Error attaching backup image for $user - hdiutil returned error: $error"
				fi
				rsync $rsyncopts -aE --log-file="$logto/$log" "/Volumes/_backup_$user/$user/" "$restoreto/$user/" 
				error="$?"				
				# rsync error handler
				if [ "$error" != "0" ]
				then
					case $error in
						23)
							secho "rsync error 23 - some files were inaccessible (probably in use)"
							;;
						24)
							secho "rsync error 24 - some files disappeared during rsync"
							;;
						12)
							errorHander "Problem backing $user, out of disk space"
							;;
						*)
							errorHander "Problem backing up $user, rsync returned error: $error"
							;;
					esac
				fi
				secho "Ejecting /Volumes/_backup_$user ..."
				diskutil eject "/Volumes/_backup_$user"
				[ "$?" != "0" ] && errorHander "There was a problem ejecting /Volumes/_backup_$user"
				# decrement data
				backuptogo=$(( $backuptogo - $usersize ))
			done
			after=$(date +%s)
			totalsecs=$(( $after - $before ))
			totaltime="$(date -r $totalsecs +%M:%S) secs"
			defaults write $backupsettings HasBeenRestored -bool true
			secho
			secho "=========================================="
			secho " Completed $(( $totalsize / 1024 / 1024 )) MBs in $totaltime" 3
			secho "=========================================="
			secho "finished: $(date)"
			cp "$logto"/*.log "$target/Library/Logs/" 	# copy logs to target when done

			[ $showlog ] && killall Console
				
			# remove them when done
			if $removebackup
			then
				# delete the backup			
				secho "Deleting $backuppath" 2
				while [ -d "$backuppath" ]
				do
					# network shares have some locks / trashes that hold up proceedings, just keep hitting it until it dies
					rm -R "$backuppath"
					sleep 1
				done
			else
				defaults write $backupsettings HasBeenRestored -bool true
			fi
			break
		else
			# no backups found for restore
			if $caspermode
			then
				secho "There are no backups for $uniqueid" 4
				break
			else
				if [ ! "$(ls $backuproot)" ] # check if the backup folder is empty
				then
		 			secho "There are no backups on $backuproot"
					break
				fi
				# interactive mode choose another backup and loop back
				chooseBackup
				# we want to quit?
				[ "$?" == "2" ] && break 
			fi
	fi
	done
}


################################
# Begin!
################################


datestamp=$(date "+%F_%H-%M-%S")

logto="/tmp"
log="$scriptname-$datestamp.log"

if $debug
then
	# dump debug logs to /
	set -xv; exec 1>/BackupRestoreUsers-DEBUG-$datestamp.log 2>&1
fi

dscl="/usr/bin/dscl"	### test - we should run dscl from current booted os. assumed that netboot system will be > system if upgrading.
dslocal="/var/db/dslocal/nodes/Default"	# path to local directory data

target="$1"							# casper passes .. $1 - target, $2 - computername, $3 username --- we only need target path.
[ "$target" == "/" ] && target=""	# if we are targetting / - set target to "" so we don't end up with //Users
userfolder="$target$userfolder"		# eg. /Volumes/MacHD/Users
restoreto="$target$restoreto"		#
dslocal="$target$dslocal"			# etc..

# if there we are in cdpmode, find the cdp server, and set url
[ $cdpmode ] && findServer

# just drop afp or smb url into this variable
networkbackuppath="$afpurl$smburl"

# uniqueid - serial or MAC address of en0
uniqueid=$(ioreg -c "IOPlatformExpertDevice" | awk -F '"' '/IOPlatformSerialNumber/ {print $4}')
[ "$uniqueid" == "" ] && uniqueid=$(ifconfig en0 | awk ' /ether/ {print $2}') # if no serial, fallback to MAC address

# set the IFS to cr
OLDIFS=$IFS
IFS=$'\n' 

#
# Lets Go!
# 
secho
secho "$scriptname $mode $version - $uniqueid" 1
secho "================================================="
secho "started: $(date)"
secho

# if we have a network path, mount it
[ "$networkbackuppath" != "" ] && mountShare

[ ! -d "$backuproot" ] && errorHander "I can't find $backuproot"

backuppath="$backuproot/$uniqueid"
backupsettings="$backuppath/BackupSettings"

#
# Core handler .. parse mode line etc
#

if $caspermode
then
	# mode is hard coded
	case $mode in
		backup )
			backupUsers
			;;
		restore )
			restoreUsers
			;;
	esac
else
	# interactive mode called by wrappers
	case $2 in
		--backup )
			backupUsers
			;;
		--restore )
			restoreUsers
			;;
		* )
			usage
			;;
	esac
fi

# unmount network share
[ "$networkbackuppath" != "" ] && unmountShare

IFS=$OLDIFS
exit