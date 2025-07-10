#!/bin/bash
URL=google.it #URL to test
DOCS="https://everything.curl.dev/cmdline/exitcode.html"
LOGFILE="$0.log"
ALERT="echo -ne \\a"


ATT=0
> $LOGFILE

while true
do
	ATT=$( expr $ATT + 1 )
	
	D=$(date)
	
	echo "$D - Calling $URL attempt $ATT - logfile $LOGFILE"
	 
	time curl -v $URL  >> $LOGFILE 2>&1
	
	EC=$?
	
	if [ $EC -eq 0 ]
	then	
		echo "Successfully contacted $URL !!!!"
		break
	else 
		echo "Exit code $EC - Lookup $DOCS"
	fi
	
done

$ALERT

echo "Alert running. Press CTRL+c to stop!"
while true
do
	$ALERT
	sleep 1
done
