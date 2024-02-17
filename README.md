# postgresql database backup script

This shell script performs automated backups of PostgreSQL databases.

## Behavior
- Supports reads of environment variables from `.env` files based on the specified environment.
- Alternatively prompts the user to enter `environment`, `database user`, `database name`, and backup directory if not provided in the `.env` file.
- Sanitizes and trims the user input.
- Optionally calls webhooks with `POST` for `success` and `error` cases (sending the` environment` in the request body) to notify other systems.
- Performs a database backup using `pg_dump`.
- Saves the backup file with a timestamp and environment name in the specified backup directory.
- Prints a success or failure message based on the backup operation.

## Usage

1. Clone the repository:

     ```bash
     git clone <repository-url>
     ```
2. Create .env files for each environment (e.g., .env.local, .env.staging, .env.production) with the following format:
     ```text
     ENVIRONMENT=local
     DB_HOST=127.0.0.1
     DB_PORT=5432
     DB_NAME=your-db-name
     DB_USER=username
     DB_NAME=database_name
     BACKUP_DIR=/path/to/backup
     WEBHOOK_SUCCESS_URL=/webhook-success/
     WEBHOOK_ERROR_URL=/webhook-error/
     ```
3. Schedule the backup:
    ```bash
    sh ./schedule_daily.sh`
    ```
