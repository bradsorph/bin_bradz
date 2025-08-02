#!/bin/bash

SLIST=tosync.txt

COUNT=0

LISTL=$(grep .  $SLIST|wc -l)

for I in $(cat $SLIST)
do
	COUNT=$(expr $COUNT + 1 )
	echo $COUNT" /"$LISTL" - "$I
	rsync -a "$I" .
done

