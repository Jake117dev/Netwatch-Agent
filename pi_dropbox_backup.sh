#!/bin/bash

# === Debug-Ausgabe für Prüfung ===
BACKUP_DIR="/opt/agent_backups"
echo "BACKUP_DIR ist gesetzt auf: $BACKUP_DIR"

# === Konfiguration ===
DROPBOX_REMOTE="dropbox:pi-backup"
NTFY_TOPIC="https://ntfy.sh/backup-pi"
DATE=$(date +%u)
BACKUP_NAME="backup-A"

if (( DATE % 2 == 0 )); then
    BACKUP_NAME="backup-B"
fi

ARCHIVE_NAME="${BACKUP_NAME}.tar.xz"
CHECKSUM_NAME="${ARCHIVE_NAME}.sha256"

INCLUDE_PATHS=(
    "/home/maddin"
    "/etc"
    "/usr/local"
)

# === Sicherheits-Check: kein Backup im Backup! ===
for path in "${INCLUDE_PATHS[@]}"; do
    if [[ "$BACKUP_DIR" == "$path"* ]]; then
        echo "⚠️  Sicherheits-ABBRUCH: Der Backup-Ordner ($BACKUP_DIR) liegt innerhalb von '$path'."
        echo "→ Das würde zu einem sich selbst fressenden Backup führen."
        echo "→ Bitte wähle einen Backup-Ordner außerhalb der zu sichernden Verzeichnisse."
        exit 1
    fi
done

# === Backup-Ordner sicherstellen & wechseln ===
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

echo "→ [1/6] Dropbox-Speicher abfragen..."
DROPBOX_USAGE=$(rclone about "$DROPBOX_REMOTE" 2>/dev/null)

if [[ -z "$DROPBOX_USAGE" ]]; then
    DROPBOX_FREE="Nicht verfügbar"
    DROPBOX_USED="Nicht verfügbar"
else
    DROPBOX_FREE=$(echo "$DROPBOX_USAGE" | grep -i "Free" | awk '{$1=""; print $0}')
    DROPBOX_USED=$(echo "$DROPBOX_USAGE" | grep -i "Used" | awk '{$1=""; print $0}')
fi

echo "→ [2/6] Backup wird erstellt (tar + xz Kompression)..."
tar -I 'xz -9' --exclude="$BACKUP_DIR" -cvf "$ARCHIVE_NAME" "${INCLUDE_PATHS[@]}" > /dev/null 2>&1

echo "→ [3/6] Prüfsumme wird erstellt..."
sha256sum "$ARCHIVE_NAME" > "$CHECKSUM_NAME"

echo "→ [4/6] Upload zur Dropbox läuft..."
rclone copy "$ARCHIVE_NAME" "$DROPBOX_REMOTE"
rclone copy "$CHECKSUM_NAME" "$DROPBOX_REMOTE"

echo "→ [5/6] Hash-Check wird durchgeführt..."
rclone copy "$DROPBOX_REMOTE/$CHECKSUM_NAME" .
REMOTE_HASH=$(cut -d ' ' -f1 "$CHECKSUM_NAME")
LOCAL_HASH=$(sha256sum "$ARCHIVE_NAME" | cut -d ' ' -f1)

if [[ "$REMOTE_HASH" == "$LOCAL_HASH" ]]; then
    echo "→ [6/6] Hash stimmt – ntfy senden & lokale Löschung vorbereiten..."
    rm -f "$CHECKSUM_NAME"
    rclone delete "$DROPBOX_REMOTE/$CHECKSUM_NAME"

    touch /tmp/backup-ok.flag
    sudo /home/maddin/backup-loeschung-lokal.sh

    ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)

    SUCCESS_MSG=$(cat <<EOF
🗃️ Archiv: $ARCHIVE_NAME
📅 Datum: $(date)
💾 Größe: $ARCHIVE_SIZE
☁️ Dropbox frei: $DROPBOX_FREE
📦 Dropbox belegt: $DROPBOX_USED
🔐 Hash-Check: ✅ OK
EOF
)
    curl -s -H "Title: ✅ Backup abgeschlossen" -d "$SUCCESS_MSG" "$NTFY_TOPIC"

else
    echo "→ [6/6] Hash-Fehler! Archiv wird gelöscht..."
    rclone delete "$DROPBOX_REMOTE/$ARCHIVE_NAME"
    rclone delete "$DROPBOX_REMOTE/$CHECKSUM_NAME"

    FAILURE_MSG=$(cat <<EOF
Hashprüfung fehlgeschlagen – Backup gelöscht!
🗃️ Archiv: $ARCHIVE_NAME
📅 Datum: $(date)
EOF
)
    curl -s -H "Title: ❌ Backup fehlgeschlagen" -d "$FAILURE_MSG" "$NTFY_TOPIC"
fi
