#!/bin/bash

# Date stamp
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Read the timeout value from the environment variable or use a default value
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-12}

# Function to read user input with timeout and sanitize it
read_with_timeout() {
    local timeout_duration=$1
    local input
    read -t $timeout_duration input
    input=$(echo "$input" | tr -s ' ' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "$input"
}

# Function to handle errors for empty variables
handle_empty_variable() {
    local variable_name=$1

    if [ -z "$variable_name" ]; then
        if [ -n "$WEBHOOK_ERROR_URL" ]; then
            curl -X POST -H "Content-Type: application/json" -d "{\"status\": \"FAILED\", \"environment\": \"$ENVIRONMENT\", \"message\": \"Required variable $1 not found.\"}" "$WEBHOOK_ERROR_URL"
        fi
        echo "Required variable $1 was not found."
        exit 1
    fi
}


# Check if ENVIRONMENT variable is already set
if [ -z "$ENVIRONMENT" ]; then
    # If not set, prompt the user for the environment
    echo -n "Enter environment (local, staging, production, etc): "
    ENVIRONMENT=$(read_with_timeout $TIMEOUT_SECONDS)
    ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
fi

# Read environment variables from the .env file
ENV_FILE=".env.$ENVIRONMENT"

if [ -f "$ENV_FILE" ]; then
    echo "Reading environment variables from $ENV_FILE"
    source "$ENV_FILE"

    if [ -n "$PGPASSFILE" ]; then
        echo "PGPASSFILE found in $ENV_FILE"
        cat $PGPASSFILE
        echo "\n----"
        export PGPASSFILE
        PG_DUMP_CMD="pg_dump"
    fi
else
    echo "Error: $ENV_FILE not found"
    echo "Defaulting to manual input ..."
fi

# Check if pg_dump exists
command -v pg_dump >/dev/null 2>&1 || {
    echo >&2 "pg_dump not found. Aborting."
    handle_empty_variable "pg_dump"
    exit 1
}

# Prompt for environment, DB_USER, and DB_NAME if not provided in the .env file
if [ -z "$ENVIRONMENT" ]; then
    echo -n "Enter environment (local, staging, production, etc): "
    ENVIRONMENT=$(read_with_timeout $TIMEOUT_SECONDS)
fi

if [ -z "$DB_HOST" ]; then
    echo -n "Enter database host: "
    DB_HOST=$(read_with_timeout $TIMEOUT_SECONDS)
    handle_empty_variable $DB_HOST
fi

if [ -z "$DB_PORT" ]; then
    echo -n "Enter database port: "
    DB_PORT=$(read_with_timeout $TIMEOUT_SECONDS)
    handle_empty_variable $DB_PORT
fi

if [ -z "$DB_USER" ]; then
    echo -n "Enter database user: "
    DB_USER=$(read_with_timeout $TIMEOUT_SECONDS)
    handle_empty_variable $DB_USER
fi

if [ -z "$DB_NAME" ]; then
    echo -n "Enter database name: "
    DB_NAME=$(read_with_timeout $TIMEOUT_SECONDS)
    handle_empty_variable $DB_NAME
fi

# Prompt for backup directory if not provided in the .env file
if [ -z "$BACKUP_DIR" ]; then
    echo -n "Enter backup directory: "
    BACKUP_DIR=$(read_with_timeout $TIMEOUT_SECONDS)
    handle_empty_variable $BACKUP_DIR
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    echo "Backup directory created: $BACKUP_DIR"
fi

# Backup filename with environment
BACKUP_FILE="$BACKUP_DIR/backup_${ENVIRONMENT}_${DATE}.sql"

# Construct final pg_dump command
PG_DUMP_CMD="pg_dump -U $DB_USER -h $DB_HOST -p $DB_PORT $DB_NAME"

# Perform database backup using pg_dump
$PG_DUMP_CMD > "$BACKUP_FILE"
echo "Executing command: $PG_DUMP_CMD"


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
