#!/bin/bash

# === Konfiguration ===
WARN_TEMP=80
SHUTDOWN_TEMP=82
NTFY_TOPIC="https://ntfy.sh/emergency"
LOGFILE="/var/log/emergency_shutdown.log"

# === Temperatur ermitteln ===
cpu_temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)

if [[ -z "$cpu_temp_raw" ]]; then
    echo "$(date): [WARN] Temperatur konnte nicht gelesen werden – kein thermal_zone0." >> "$LOGFILE"
    exit 0
fi

cpu_temp=$(awk "BEGIN {printf \"%.1f\", $cpu_temp_raw / 1000}")

if ! [[ "$cpu_temp" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    echo "$(date): [ERROR] Ungültiger Temperaturwert '$cpu_temp'" >> "$LOGFILE"
    exit 0
fi

echo "$(date): Aktuelle CPU-Temperatur: ${cpu_temp}°C" >> "$LOGFILE"

# === Warnmeldung ab WARN_TEMP ===
if (( $(echo "$cpu_temp >= $WARN_TEMP" | bc -l) )) && (( $(echo "$cpu_temp < $SHUTDOWN_TEMP" | bc -l) )); then
    curl -s -H "Title: ⚠️ Pi überhitzt – Vorwarnung" \
         -d "Temperatur liegt bei $cpu_temp°C.
Shutdown bei $SHUTDOWN_TEMP°C wird vorbereitet." \
         "$NTFY_TOPIC" \
    && echo "$(date): Warnung gesendet bei $cpu_temp°C" >> "$LOGFILE"
fi

# === Harte Abschaltung ab SHUTDOWN_TEMP ===
if (( $(echo "$cpu_temp >= $SHUTDOWN_TEMP" | bc -l) )); then
    curl -s -H "Title: ⛔️ System-Abschaltung" \
         -d "CPU-Temperatur bei $cpu_temp°C überschritten!
Der Pi wird jetzt zur Sicherheit heruntergefahren." \
         "$NTFY_TOPIC" \
    && echo "$(date): Abschaltung ausgeführt bei $cpu_temp°C" >> "$LOGFILE"

    shutdown -h now
fi