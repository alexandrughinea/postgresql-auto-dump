#!/bin/bash

# Prompt for the path to the backup script
read -p "Enter the path to the backup script (default: backup.sh): " BACKUP_SCRIPT_PATH
BACKUP_SCRIPT_PATH=${BACKUP_SCRIPT_PATH:-backup.sh}

# Check if the backup script exists
if [ ! -f "$BACKUP_SCRIPT_PATH" ]; then
    echo "Error: Backup script not found at $BACKUP_SCRIPT_PATH"
    exit 1
fi

# Add cron job to run the backup script daily
(crontab -l ; echo "0 0 * * * $BACKUP_SCRIPT_PATH") | crontab -

echo "Cron job set up successfully to run $BACKUP_SCRIPT_PATH daily"
