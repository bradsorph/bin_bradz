#!/bin/bash

DESTDIR=syncdir

if [ $# -lt 1 ]
then 
	echo "use $0 'YYYY-MM-DD' "
	exit 1
fi

find $DESTDIR -type f -newermt $1 | sed "s|^$DESTDIR/||" 
