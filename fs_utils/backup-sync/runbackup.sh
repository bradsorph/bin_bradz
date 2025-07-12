#!/bin/bash

DIRTOBKP="/home/youruser"
TEMPDIRS="$DIRTOBKP/Downloads/ $DIRTOBKP/tmp/"
SCRIPTBKP="./backupDataNinfo.sh"

echo "- Check Temporary dirs"

for I in $TEMPDIRS
do
	FILESN=$(ls -a "$I" |  grep -vw "\."| wc -l)
	echo "-- There are $FILESN files on $I"
	if [ $FILESN -gt 0 ]
	then
		echo -n "--- Delete them (Y/N)?"
		read ANS
		if [ "$ANS" = "Y" -o "$ANS" = "y" ]
		then 
			rm -rf $I*
			echo "---- Delete result "$?
		else
			echo "---- Skipping $I* from deletion"
		fi
	fi
done

echo "- Start backup, see output on nohup.out"
/usr/bin/nohup  $SCRIPTBKP &
