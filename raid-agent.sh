#!/bin/bash

# Öffentlich erreichbarer ntfy.sh-Kanal
NTFY_TOPIC="https://ntfy.sh/raid-status"

# RAID & Systeminfos
RAID_DEV="/dev/md0"
SMART_DEVICES=("/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd")

HOSTNAME=$(hostname)
RAID_STATUS=$(cat /proc/mdstat)

SMART_INFO=""
for disk in "${SMART_DEVICES[@]}"; do
    RESULT=$(sudo smartctl -H "$disk" 2>/dev/null | grep overall-health)
    SMART_INFO+="\n$disk: $RESULT"
done

USAGE=$(df -h /mnt/raid | awk 'NR==2 {print $3 " von " $2 " verwendet (" $5 " genutzt)"}')

STATUS_MSG=$(cat <<EOF
RAID-Agentenbericht vom $HOSTNAME:

[RAID Status]
$RAID_STATUS

[SMART Werte]
$SMART_INFO

[Speichernutzung RAID]
$USAGE
EOF
)

curl -s -H "Title: RAID Statusbericht" -d "$STATUS_MSG" "$NTFY_TOPIC"
