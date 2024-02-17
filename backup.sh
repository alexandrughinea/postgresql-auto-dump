#!/bin/bash

# Prompt for environment
read -p "Enter environment (local, staging, production, .etc): " ENVIRONMENT
ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

# Read environment variables from the .env file
ENV_FILE=".env.$ENVIRONMENT"

if [ -f "$ENV_FILE" ]; then
    echo "Reading environment variables from $ENV_FILE"
    source "$ENV_FILE"
    
    # Check if PGPASSFILE is defined in the .env file
    if [ -n "$PGPASSFILE" ]; then
        echo "PGPASSFILE found in $ENV_FILE"
        cat $PGPASSFILE
        echo "\n----"
        export PGPASSFILE
        PG_DUMP_CMD="pg_dump"
    else
        echo "PGPASSFILE not found. Using other connection parameters."
        PG_DUMP_CMD="pg_dump -U $DB_USER -h $DB_HOST -p $DB_PORT $DB_NAME"
    fi
else
    echo "Error: $ENV_FILE not found"
    echo "Defaulting to manual input ..."
fi

# Check if pg_dump exists
command -v pg_dump >/dev/null 2>&1 || { 
    echo >&2 "pg_dump not found. Aborting."
    if [ -n "$WEBHOOK_ERROR_URL" ]; then
        curl -X POST -d "Backup failed: pg_dump not found" "$WEBHOOK_ERROR_URL"
    fi
    exit 1
}

# Prompt for environment, DB_USER, and DB_NAME if not provided in the .env file
if [ -z "$ENVIRONMENT" ]; then
    read -p "Enter environment (local, staging, production, .etc): " ENVIRONMENT
    ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
fi

if [ -z "$DB_HOST" ]; then
    read -p "Enter database host: " DB_HOST
    DB_HOST=$(echo "$DB_HOST" | tr -d '[:space:]')
fi

if [ -z "$DB_PORT" ]; then
    read -p "Enter database port: " DB_PORT
    DB_PORT=$(echo "$DB_PORT" | tr -d '[:space:]')
fi

if [ -z "$DB_USER" ]; then
    read -p "Enter database user: " DB_USER
    DB_USER=$(echo "$DB_USER" | tr -d '[:space:]')
fi

if [ -z "$DB_NAME" ]; then
    read -p "Enter database name: " DB_NAME
    DB_NAME=$(echo "$DB_NAME" | tr -d '[:space:]')
fi

# Prompt for backup directory if not provided in the .env file
if [ -z "$BACKUP_DIR" ]; then
    read -p "Enter backup directory: " BACKUP_DIR
    BACKUP_DIR=$(echo "$BACKUP_DIR" | tr -d '[:space:]')
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backup directory created: $BACKUP_DIR"
fi

# Date stamp
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Backup filename with environment
BACKUP_FILE="$BACKUP_DIR/backup_$ENVIRONMENT_$DATE.sql"

# Perform database backup using pg_dump
$PG_DUMP_CMD > "$BACKUP_FILE"

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_FILE"
    if [ -n "$WEBHOOK_SUCCESS_URL" ]; then
        curl -X POST -H "Content-Type: application/json" -d "{\"status\": \"SUCCESS\", \"environment\": \"$ENVIRONMENT\"}" "$WEBHOOK_SUCCESS_URL"
    fi
else
    echo "Backup failed"
    if [ -n "$WEBHOOK_ERROR_URL" ]; then
        curl -X POST -H "Content-Type: application/json" -d "{\"status\": \"FAILED\", \"environment\": \"$ENVIRONMENT\"}" "$WEBHOOK_ERROR_URL"
    fi
fi
