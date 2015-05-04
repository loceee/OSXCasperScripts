#!/bin/bash
#
# unBinderAD.sh
# unbind a mac from AD.

aduser="${4}"
adpass="${5}"

tries=3

if [ -z "$(dsconfigad -show)" ]
then
	echo "this mac doesn't seem to be bound to ad"
	exit 0
fi



for (( i = 0; i < ${tries}; i++ ))
do
	echo "unbinding from AD - try ${i}/${tries}"
	dsconfigad -remove -force -u "${aduser}" -p "${adpass}"
	sleep 10
	if [ -z "$(dsconfigad -show)" ]
	then
		echo "unbind successful!"
		exit 0
	fi
done

echo "unbind failed :("
exit 1
