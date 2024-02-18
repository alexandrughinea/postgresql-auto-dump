#!/bin/bash

# Function to add a cron job
add_cron_job() {
    # Prompt for the environment
    read -p "Enter environment (local, staging, production, .etc): " ENVIRONMENT
    ENV_FILE=".env.$ENVIRONMENT"

    export $ENVIRONMENT

    # Check if the environment file exists
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        CRON_PATTERN=${CRON_PATTERN:-"0 0 * * *"}  # Default pattern if not specified in the environment file
    else
        echo "Environment file not found for $ENVIRONMENT"
        # Prompt for the cron pattern if environment file not found
        read -p "Enter the cron pattern (default: 0 0 * * *): " CRON_PATTERN
        CRON_PATTERN=${CRON_PATTERN:-"0 0 * * *"}
    fi

    # Prompt for the path to the backup script
    read -p "Enter the path to the backup script (default: backup_posgresql.sh): " BACKUP_SCRIPT_PATH
    BACKUP_SCRIPT_PATH=${BACKUP_SCRIPT_PATH:-backup_posgresql.sh}

    # Check if the backup script exists
    if [ ! -f "$BACKUP_SCRIPT_PATH" ]; then
        echo "Error: Backup script not found at $BACKUP_SCRIPT_PATH"
        exit 1
    fi

    # Add cron job to run the backup script daily
    (crontab -l ; echo "$CRON_PATTERN $BACKUP_SCRIPT_PATH") | crontab -

    echo "Cron job set up successfully to run $BACKUP_SCRIPT_PATH with pattern $CRON_PATTERN"
}

# Function to remove a cron job
remove_cron_job() {
    # Prompt for the path to the backup script
    read -p "Enter the path to the backup script (default: backup_posgresql.sh): " BACKUP_SCRIPT_PATH
    BACKUP_SCRIPT_PATH=${BACKUP_SCRIPT_PATH:-backup_posgresql.sh}

    # Remove the cron job associated with the backup script
    crontab -l | grep -v "$BACKUP_SCRIPT_PATH" | crontab -

    echo "Cron job removed for $BACKUP_SCRIPT_PATH"
    echo "Listing all remaining cronjobs:"
    crontab -l
}

# Main menu
echo "1. Add a cron job"
echo "2. Remove a cron job"
read -p "Enter your choice (1/2): " choice

case $choice in
    1) add_cron_job ;;
    2) remove_cron_job ;;
    *) echo "Invalid choice" ;;
esac
