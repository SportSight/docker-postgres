#!/bin/bash
set -e

# Example script to create application database and user
# This demonstrates how to use environment variables for configuration

DB_NAME="${APP_DB_NAME:-myapp}"
DB_USER="${APP_DB_USER:-myapp}"
DB_PASSWORD="${APP_DB_PASSWORD:-password}"

echo "Setting up application database: $DB_NAME with user: $DB_USER"

# Function to check if a role exists
role_exists() {
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_roles WHERE rolname='$1'" | grep -q 1
}

# Function to check if a database exists
database_exists() {
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname='$1'" | grep -q 1
}

# Create user if not exists
if ! role_exists "$DB_USER"; then
  echo "Creating role '$DB_USER'..."
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASSWORD';
    ALTER ROLE $DB_USER WITH CREATEDB;
EOSQL
  echo "Role '$DB_USER' created."
else
  echo "Role '$DB_USER' already exists."
fi

# Create database if not exists
if ! database_exists "$DB_NAME"; then
  echo "Creating database '$DB_NAME'..."
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE $DB_NAME OWNER $DB_USER;
    GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;
    GRANT CREATE ON SCHEMA public TO $DB_USER;
EOSQL
  echo "Database '$DB_NAME' created and privileges granted."
else
  echo "Database '$DB_NAME' already exists."
fi

echo "Application database setup complete."