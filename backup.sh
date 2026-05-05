#!/bin/bash
set -euo pipefail

########################################
# User‑configurable variables
########################################
BACKUP_DIR="/volume1/docker/appdata-backup/syncthing"
CONFIG_DIR="/volume1/docker/syncthing"
CONTAINER_NAME="syncthing"
DAYS=7
LOGFILE="/volume1/docker/appdata-backup/backup.log"
########################################

# Everything below is logged
{
echo "=== Syncthing Backup Check ==="
echo "Timestamp: $(date)"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Guarantee Syncthing is restarted even if script fails
trap 'echo "Ensuring Syncthing is running..."; docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true' EXIT

# Find newest backup file (if any)
latest_backup=$(ls -1 "$BACKUP_DIR"/syncthing_config_*.zip 2>/dev/null | sort | tail -n 1 || true)

# If no backups exist, force a backup
if [ -z "$latest_backup" ]; then
    echo "No existing backups found — running first backup."
    run_backup=true
else
    echo "Latest backup found: $latest_backup"

    # Extract timestamp from filename
    ts=$(basename "$latest_backup" | sed -E 's/.*_([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}).*/\1/')

    # Convert "YYYY-MM-DD_HH-MM-SS" → "YYYY-MM-DD HH:MM:SS"
    ts_fixed=$(echo "$ts" | sed 's/_/ /; s/-/:/3; s/-/:/4')
    file_epoch=$(date -d "$ts_fixed" +%s)
    now=$(date +%s)
    threshold=$(( now - DAYS*24*3600 ))

    echo "Backup timestamp: $ts"
    echo "Threshold epoch:  $threshold"
    echo "File epoch:       $file_epoch"

    # Compare age
    if [ "$file_epoch" -lt "$threshold" ]; then
        echo "Backup is older than $DAYS days — running new backup."
        run_backup=true
    else
        echo "Backup is newer than $DAYS days — skipping backup."
        run_backup=false
    fi
fi

########################################
# Run backup if needed
########################################
if [ "$run_backup" = true ]; then
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    archive="$BACKUP_DIR/syncthing_config_${timestamp}.zip"

    echo "Stopping container: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME"

    echo "Creating backup: $archive"
    (
        cd "$CONFIG_DIR"
        zip -r "$archive" . -x "*/@eaDir/*"
    )

    echo "Backup complete."
else
    echo "No backup performed."
fi

echo "=== Done ==="

} 2>&1 | tee -a "$LOGFILE"
