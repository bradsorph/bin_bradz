#!/bin/bash

DIRTOBKP="/home/youruser"
AUDIOALERT="$DIRTOBKP/yoursonud.mp3"

echo "# Backup up $DIRTOBKP"
/usr/bin/rsync -av --exclude '.cache' $DIRTOBKP .
echo "# Backup up etc"
sudo /usr/bin/rsync -av /etc .

TS=$(date +%Y%m%d%H%M)

if [ -e "./nohup" ]
then
	mv nohup.out nohup_"$TS".out
fi

echo "# List package installed"
apt list --installed | tee ./installed_$TS.txt

mplayer $AUDIOALERT  > /dev/null 2>&1
echo "#END"
