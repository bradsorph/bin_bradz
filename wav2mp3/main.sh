#!/bin/bash

source ./config.sh

# CHECK
if [ -n "$1" ]
then
	DIRNAME=$1
else
	OS=$(uname)
	if [ "$OS" = "Linux" ]; then
		DIRNAME=$(date -d yesterday +%Y%m%d)
	else
		DIRNAME=$(date -v -1d +%Y%m%d)
	fi
fi

#RUN

echo "- Creating "$DIRNAME
mkdir -p $DIRNAME

echo "- Searching for wave files"
find $SRCDIR -iname "*.wav" 2>/dev/null | grep -v Trash | tee $TMPF 


while read -r line; 
do 
	echo " -- Moving" $line in $DIRNAME
	mv -v  $line $DIRNAME

done < $TMPF

echo "- Encoding..."
$ENCSCRIPT $DIRNAME

echo "- Zipping..."
zip -v "$DIRNAME".zip "$DIRNAME"/*.mp3

if [ -n "$BZBACKUP" ]
then
	echo "- Backup waves"
	ls "$DIRNAME/"*.WAV >/dev/null 2>&1
	ISWAV=$?
	
	if [ $ISWAV -eq 0 ]
	then 
		tar -cvjf "$BZBACKUP/$PROJ_"$DIRNAME"_WAV.tar.bz2" "$DIRNAME/"*.WAV ;
		echo $? > $ZIPOK
	fi

        ls "$DIRNAME/"*.wav >/dev/null 2>&1
        ISWAV=$?

        if [ $ISWAV -eq 0 ]
        then
                tar -cvjf "$BZBACKUP/$PROJ_"$DIRNAME"_wav.tar.bz2" "$DIRNAME/"*.wav ;
                echo $? > $ZIPOK
        fi
	
else
	echo "- Skipped Backup waves"
fi

$CLEANUPS $ZIPOK

echo "END"


$RIFF > /dev/null 2>&1
