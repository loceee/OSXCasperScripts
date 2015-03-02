#!/bin/bash
#
# repartion main hard disk
#
# casper imaging doesn't allow you to partion back to 1 single parition?
# 
# undo a previous fstab / system / data partition setup.
#
# WARNING. THIS DESTROYS ALL DATA ON YOUR INTERNAL DISK
# RUN IN A DESTRUCTIVE CASPER IMAGING WORKFLOW ONLY
#
# YOU HAVE BEEN WARNED!
#
# (it won't handle fusion disks)
# http://github.com/loceee

numberofinternals=0

checkDiskInfo()
{
	devicepath="${1}"
	info="${2}"
	result=$(diskutil info ${devicepath} | grep "${info}:" | awk '{ print $2 }')
	echo "${result}"
}

for device in $(diskutil list | grep /dev/)
do
	internal=$(checkDiskInfo ${device} "Internal")
	ejectable=$(checkDiskInfo ${device} "Ejectable")
	# if it's internal and not ejectable, we'll assume it's the internal drive
	if [ "${internal}" == "Yes" ] && [ "${ejectable}" == "No" ]
	then
		(( numberofinternals ++ ))
		internaldevice="${device}"
	fi
done

if [ "${numberofinternals}" == "1" ]
then
	# there is only 1 internal disk that complies... let's blow it away!
	diskutil umountDisk force ${internaldevice}
	diskutil partitionDisk ${internaldevice} 1 GPTFormat JHFS+ "Macintosh HD" 100%
else
	# there is 0 or 2+ disks.. too tricky for this script (for now)
	echo "there are ${numberofinternals} valid internal devices... I don't know what to do."
fi

exit

