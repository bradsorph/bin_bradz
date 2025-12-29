#!/bin/bash

SLIST=tosync.txt
DESTDIR=syncdir

mkdir -p $DESTDIR

COUNT=0

LISTL=$(grep .  $SLIST|wc -l)

for I in $(cat $SLIST)
do
	COUNT=$(expr $COUNT + 1 )
	echo $COUNT" /"$LISTL" - "$I
	rsync -a "$I" "$DESTDIR/"
done

