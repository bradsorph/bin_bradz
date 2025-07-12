#!/bin/bash
if [ -e "./nohup.out" ]
then
        TS=$(date +%Y%m%d%H%M)
        mv nohup.out nohup_"$TS".out
fi

