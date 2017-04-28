#!/usr/bin/env bash

set -e

# Wait for the SQL Server to come up.
until nc -z -w2 127.0.0.1 1433
do
    echo "[moodle-db-setup] Waiting 5s for mssql to come up setup"
    sleep 5
done

echo "[moodle-db-setup] Setting up Moodle data"
/opt/mssql/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d master -i setup.sql
echo "[moodle-db-setup] Setup complete."
