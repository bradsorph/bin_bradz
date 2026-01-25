#!/bin/bash



if [ $# -lt 1 ]
then
	echo "$0: input dir expected"
	exit 1
fi

SRCDIR=$1

FLIST=`ls $SRCDIR/*.wav $SRCDIR/*.WAV 2>/dev/null`

for I in $FLIST
do
	EXT=`echo $I| awk -F'.' '{ print $NF }' ` 
	FN=`basename $I $EXT`
	MP3F=$SRCDIR/$FN"mp3"
	echo "--- Converting $I in $MP3F"
	ffmpeg -i $I -acodec mp3 $MP3F	
done
