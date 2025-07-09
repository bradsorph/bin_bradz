#!/bin/bash

if [ $# -lt 1 ]
then 
	echo "use $0 'YYYY-MM-DD' "
	exit 1
fi

find . -type f -newermt $1
