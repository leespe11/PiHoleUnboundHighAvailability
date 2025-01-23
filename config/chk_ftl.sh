#!/bin/bash
CHECK_CONTAINER=$(/usr/bin/docker ps -q -f name=pihole)
if [ "$CHECK_CONTAINER" = "" ]
then
    exit 1
fi

STATUS=$(/usr/bin/docker exec -it pihole ps ax | grep -v grep | grep pihole-FTL)

if [ "$STATUS" != "" ]
then
    exit 0
else
    exit 1
fi