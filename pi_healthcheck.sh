#!/bin/bash

echo "===== Raspberry Pi Health Check ====="

# Kernel-Version
echo -e "\n--- Kernel Version:"
uname -a

# CPU-Temp
echo -e "\n--- CPU Temperature:"
vcgencmd measure_temp

# System-Auslastung
echo -e "\n--- System Load:"
uptime

# Speicher
echo -e "\n--- Memory Usage:"
free -h

# Festplattenspeicher
echo -e "\n--- Disk Usage:"
df -h /

# Netzwerkstatus
echo -e "\n--- IP Address:"
hostname -I

# Dienste (z. B. SSH, VNC, WireGuard falls vorhanden)
echo -e "\n--- Aktive Dienste:"
systemctl list-units --type=service --state=running | grep -E "ssh|vnc|wg"

# Bootzeit
echo -e "\n--- Letzter Boot:"
who -b

echo -e "\n===== Check abgeschlossen. ====="
