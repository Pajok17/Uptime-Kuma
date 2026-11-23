#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/pam5296/sysAdmin02/uptime-kuma"
BACKUP_DIR="/home/pam5296/sysAdmin02/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$BACKUP_DIR/uptime-kuma-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"
cd "$APP_DIR"
docker compose config --quiet

if [[ ! -d data || -e "$ARCHIVE" ]]; then
    echo "ERROR: Data directory missing or archive already exists."
    exit 1
fi

# Restart the app even if the archive operation fails.
trap 'docker compose start' EXIT

echo "[1/4] Stopping Uptime Kuma..."
docker compose stop

echo "[2/4] Creating backup..."
tar -czf "$ARCHIVE" data
tar -tzf "$ARCHIVE" >/dev/null

echo "[3/4] Restarting Uptime Kuma..."
docker compose start
trap - EXIT

echo "[4/4] Cleaning old backups..."
mapfile -t backups < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'uptime-kuma-*.tar.gz' -printf '%f\n' | sort -r
)
for ((i=7; i<${#backups[@]}; i++)); do
    rm -- "$BACKUP_DIR/${backups[i]}"
done

echo "Backup completed successfully!"
ls -lh "$ARCHIVE"
