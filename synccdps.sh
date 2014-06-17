#!/bin/bash

#
# rsyncs CDPs points... run on your master CDP nightly or whenevers...
#
# queries your jss api and pulls down all your CDP info.
# rsyncs local via a file share (slower) but more compatible
#
# why hasn't someone mades this sooner... sheesh?
#
#
# more info lachlan.stewart@interpublic.com -=- USE AT YOUR OWN RISK!!

# read only api user please!
apiuser="apiuser"
apipass="apipass"

# we can't read this from the api
casperadminpassword="cadminpass" 

#
jssurl="https://jss.interpublic.com.au:8443"

# if you are using a self signed cert for you jss, tell curl to allow it.
selfsignedjsscert=true

#
# don't touch below.
#

if $selfsignedjsscert
then
	curlopts="-k"
else
	curlopts=""
fi


# make tmp folder
tmpdir="/tmp/rsyncdp-$$" # i need to find you during debug
cdplist="$tmpdir/cdplist.xml"
cdpdata="$tmpdir/cdpdata"
mkdir "$tmpdir"
mkdir "$cdpdata"

errorHander()
{
	# Error function
	message="$1"
	echo "ERROR: $message"
	unmountShare
	rm -R "$tmpdir"
	exit 1
}

unmountShare()
{
	if [ -d "$mountpath" ]
	then
		echo "unmounting $mountpath..."
		sleep 1
		umount "$mountpath"

		if [ "$?" != "0" ]
		then
			echo "forcing unmount..."
			diskutil unmount force "$mountpath"
			if [ "$?" != "0" ]
			then
				echo "There was a problem unmounting $mountpath"
				exit 1
			fi
		fi
		rm -R "$mountpath"
	fi
}

echo "rsync to cdps started: $(date)"
echo "======================================================================="
echo "getting cdp details from jss..."
curl $curlopts -s -u $apiuser:$apipass ${jssurl}/JSSResource/distributionpoints > $cdplist
# get number of cdps
cdpsize=$(xpath $cdplist //distribution_points/size 2> /dev/null | sed -e 's/<size>//g;s/<\/size>//g')


for (( i=1; i<=$cdpsize; i++ ))
do
	cdpname[$i]=$(xpath $cdplist //distribution_points/distribution_point[$i]/name 2> /dev/null | sed -e 's/<name>//g;s/<\/name>//g')
	echo "getting details for ${cdpname[$i]} ..."
	curl $curlopts -s -u $apiuser:$apipass ${jssurl}/JSSResource/distributionpoints/name/$(echo ${cdpname[$i]} | sed -e 's/ /\+/g') > "$cdpdata/${cdpname[$i]}.xml"
	cdpip[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/ip_address 2> /dev/null | sed -e 's/<ip_address>//g;s/<\/ip_address>//g')
	cdplocalpath[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/local_path 2> /dev/null | sed -e 's/<local_path>//g;s/<\/local_path>//g')
	cdpismaster[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/is_master 2> /dev/null | sed -e 's/<is_master>//g;s/<\/is_master>//g')
	cdpprotocol[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/connection_type 2> /dev/null | sed -e 's/<connection_type>//g;s/<\/connection_type>//g')
	cdpshare[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/share_name 2> /dev/null | sed -e 's/<share_name>//g;s/<\/share_name>//g')
	cdpusername[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/read_write_username 2> /dev/null | sed -e 's/<read_write_username>//g;s/<\/read_write_username>//g')
	cdpsshname[$i]=$(xpath "$cdpdata/${cdpname[$i]}.xml" //distribution_point/ssh_username 2> /dev/null | sed -e 's/<ssh_username>//g;s/<\/ssh_username>//g')

	if [ "${cdpismaster[$i]}" == "true" ]
	then
		masterlocalpath="${cdplocalpath[$i]}"
		echo "local path: $masterlocalpath"
	fi
done

for (( i=1; i<=$cdpsize; i++ ))
do

	[ "${cdpismaster[$i]}" == "true" ] && continue	# if it's the master, skip it

	mountpath="/tmp/${cdpshare[$i]}"
	if [ -d "$mountpath" ]
	then
		errorHander "$mountpath exists.. too hard for me to deal with. sort it fool."
	else	
		mkdir "$mountpath"
	fi

	echo
	echo "-----------------------------------------------------------------------"
	echo "starting sync to ${cdpname[$i]}.."
	echo "mounting ${cdpip[$i]}/${cdpshare[$i]} via ${cdpprotocol[$i]} ..."	
	case ${cdpprotocol[$i]} in
		AFP)
			mount_afp afp://${cdpusername[$i]}:$casperadminpassword@${cdpip[$i]}/${cdpshare[$i]} "$mountpath"
			mounterror="$?"
		;;

		SMB)
			echo mount_smbfs //${cdpusername[$i]}:$casperadminpassword@${cdpip[$i]}/${cdpshare[$i]} "$mountpath"
			mounterror="$?"
		;;

		*)
			errorHander "unhandled protomacol ${cdpprotocol[i$]}... zoink!"
		;;
	esac	
	[ "$mounterror" != "0" ] && errorHander "there was a problem mounting the network share $share from  ${cdpname[$i]} - mount_${cdpprotocol[$i]} returned $mounterror"]
	
	echo "rsyncing to ${cdpname[$i]}: $(date) ..."
	#rsync -av --delete --exclude=".*" --no-perms --omit-dir-times  "$masterlocalpath/" "$mountpath/"
	rsync -rlDv --delete --exclude=".*" "$masterlocalpath/" "$mountpath/"
	error="$?"	
	# rsync error handler - we can ignore a couple of common errors
	
	if [ "$error" != "0" ]
	then
		case $error in
			23)
				echo "rsync error 23 - some files were inaccessible (probably in use)"
			;;
			
			24)
				echo "rsync error 24 - some files disappeared during rsync"
			;;
			
			12)
				errorHander "out of disk space.. blerg"
			;;
			
			*)
				errorHander "rsync returned error: $error"
			;;
		esac
	fi
	# done, unmount this server
	unmountShare
done

echo
echo "finshed !"
echo "======================================================================="
echo "rsync to cdps finshed: $(date)"

rm -R "$tmpdir"
exit
