# postgresql database backup script
Liteweight backup script with scheduling over `pg_dump`.

## Description
This shell script can perform backups or scheduled backups of PostgreSQL databases.

## Features
- Supports reads of environment variables from `.env.*` files.
- Alternatively prompts the user to enter `environment`, `database user`, `database name`, and backup directory if not provided in the `.env` file.
- Sanitizes the user input.
- Optional webhooks with `POST` for `success` and `error` cases (sending the` environment` in the request body) to notify other systems (have to set `WEBHOOK_SUCCESS_URL` and/or `WEBHOOK_ERROR_URL`).
- Saves the backup file with a timestamp and environment name in the specified backup directory.
- Prints a success or failure message based on the backup operation.

## Usage

1. Clone the repository:

     ```bash
     git clone <repository-url>
     ```
2. Create .env files for each environment (e.g., `.env.local`, `.env.staging`, `.env.production`, etc.) with the following format:
     ```text
    ENVIRONMENT="local"
    BACKUP_DIR="backups"
    WEBHOOK_SUCCESS_URL="http://localhost:3005/webhook"
    WEBHOOK_ERROR_URL="http://localhost:3005/webhook"
    CRON_PATTERN="0 0 * * *" # daily run
    
    #PGPASSFILE=~/.pgpass
    #If `.pgpass` file exists on disk, it takes priority over:
    DB_HOST=localhost
    DB_PORT=5243
    DB_USER=dboperator
    DB_NAME=postgres
     ```
3. Schedule the backup for your particular env:
    ```bash
    sh ./schedule_backup_posgresql.sh`
    ```
    
    a. You can also configure your individual CRON_PATTERN for each `env` file.
    b. Then a main menu will then allow you to schedule or un-schedule a cron:
   
    ```text
    # Main menu
     1. Add a cron job
     2. Remove a cron job
     Enter your choice (1/2): 
    ```
    c. The script will then ask you what `env` file you want to load the configuration from. 

4. Webhook support for external notifications
   The `WEBHOOK_SUCCESS_URL` and `WEBHOOK_ERROR_URL` will have a payload with the following format:
   ```json
    { "status": "FAILED | SUCCESS", "environment": "$ENVIRONMENT", "message": "Extra information"}
    ```