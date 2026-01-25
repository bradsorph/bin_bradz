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

ZO=$(cat $ZIPOK)

if [ $ZO -eq 0 ]
then 
	rm -f $DIRNAME/*.wav  $DIRNAME/*.WAV
fi	

rm $TMPF $ZIPOK



