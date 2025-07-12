#!/bin/bash

HPATH="/home/"
MSIZE=1024
OUTF="/tmp/bigfiles.txt"

> $OUTF

TSUM="0"

date

find $HPATH -type f | while read LINE; 
do 
	if [ $(expr $(date +%s) % 20 ) -eq 0 ]
	then
		echo -n "."
	fi
	SIZE=$(du -m "$LINE" | awk '{ print $1 }');
	#echo -n -e \\b
	if [ $SIZE -gt $MSIZE ]
	then
		echo
		echo $LINE $SIZE | tee -a $OUTF
		TSUM=$TSUM"+"$SIZE
	fi
	#echo $TSUM
done


echo -n Total" "
echo $TSUM | bc -l
date