# Syncthing Backup Script

This script creates periodic ZIP backups of a Syncthing Docker container’s configuration directory. It is designed for Synology NAS but works on any Linux system.

# What It Does

- Finds the newest existing backup
- Checks if it’s older than the configured number of days
- Stops the Syncthing container
- Creates a ZIP archive of the config directory
- Restarts the container (always, even on failure)
- Logs all actions to a logfile

# Configuration

Edit these variables at the top of the script:

```bash
BACKUP_DIR="/volume1/docker/appdata-backup/syncthing"
CONFIG_DIR="/volume1/docker/syncthing"
CONTAINER_NAME="syncthing"
DAYS=7
LOGFILE="/volume1/docker/appdata-backup/backup.log"
```

# Backup Output

Backups are stored as:

```bash
syncthing_config_YYYY-MM-DD_HH-MM-SS.zip
```

ZIP files can be opened directly in Synology File Station.

# Restore
1. Stop the container
2. Delete the old container volume contents
3. Extract the ZIP into the config directory
4. Start the container again
