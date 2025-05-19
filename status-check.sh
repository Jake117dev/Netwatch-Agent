#!/bin/bash

# === Konfiguration ===
ntfy_topic="https://ntfy.sh/backup-pi"
dropbox_remote="dropbox:"
hostname=$(hostname)
uptime_info=$(uptime -p)

# CPU-Temperatur auslesen (Pi-spezifisch)
cpu_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
cpu_temp=$(awk "BEGIN {printf \"%.1f°C\", $cpu_temp_raw / 1000}")

ram_used=$(awk '/MemTotal/ {total=$2} /MemAvailable/ {avail=$2} END {printf("%.1f%%", (total-avail)/total*100)}' /proc/meminfo)
disk_usage=$(df -h / | awk 'NR==2 {print $3 " verwendet von " $2 " (" $5 " genutzt)"}')

# === Dropbox Info ===
DROPBOX_USAGE=$(rclone about "$dropbox_remote" 2>/dev/null)

if [[ -z "$DROPBOX_USAGE" ]]; then
    DROPBOX_INFO="⚠️ Keine Dropbox-Daten verfügbar."
else
    DROPBOX_FREE=$(echo "$DROPBOX_USAGE" | grep -i "free" | awk '{$1=""; print $0}')
    DROPBOX_USED=$(echo "$DROPBOX_USAGE" | grep -i "used" | awk '{$1=""; print $0}')
    DROPBOX_TOTAL=$(echo "$DROPBOX_USAGE" | grep -i "total" | awk '{$1=""; print $0}')
    DROPBOX_INFO="☁️ Dropbox:
    Gesamt: $DROPBOX_TOTAL
    Frei:   $DROPBOX_FREE
    Belegt: $DROPBOX_USED"
fi

# === Gesamtnachricht ===
message=$(cat <<EOF
📡 Host: $hostname
⏱️ Laufzeit: $uptime_info
🔥 CPU-Temperatur: $cpu_temp
🧠 RAM: $ram_used
💾 Speicher: $disk_usage

$DROPBOX_INFO
EOF
)

# === ntfy-Push senden ===
curl -s -X POST "$ntfy_topic" -H "Title: Pi Statusbericht" -d "$message"
