# PostgreSQL + pgvector + pg_cron

[![Docker Hub](https://img.shields.io/docker/pulls/sportsight/postgres.svg)](https://hub.docker.com/r/sportsight/postgres)
[![Docker Image Version](https://img.shields.io/docker/v/sportsight/postgres.svg?sort=semver)](https://hub.docker.com/r/sportsight/postgres/tags)

A production-ready PostgreSQL Docker image with pgvector and pg_cron extensions, designed for reusability across multiple projects.

## Docker Hub

This image is publicly available on Docker Hub: [`sportsight/postgres`](https://hub.docker.com/r/sportsight/postgres)

```bash
docker pull sportsight/postgres:latest
```

## Features

- **PostgreSQL 17** (configurable via build args)
- **pgvector** extension for vector operations
- **pg_cron** extension for scheduled tasks
- **Custom initialization scripts** support
- **Optimized configuration** for production workloads

## Usage

### Basic Usage

```bash
docker run -d \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  sportsight/postgres:latest
```

### With Custom Initialization Scripts

The image supports custom initialization scripts through volume mounting:

```bash
docker run -d \
  -e POSTGRES_DB=myapp \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -v ./custom-scripts:/docker-entrypoint-initdb.d/custom-init.d \
  -p 5432:5432 \
  sportsight/postgres:latest
```

### Custom Scripts Directory Structure

Place your custom initialization scripts in a local directory and mount it to `/docker-entrypoint-initdb.d/custom-init.d`:

```
custom-scripts/
├── 01-create-users.sh
├── 02-create-databases.sql
├── 03-seed-data.sql.gz
└── 99-final-setup.sh
```

Supported file types:
- `.sh` - Shell scripts (executed or sourced)
- `.sql` - SQL files
- `.sql.gz` - Compressed SQL files

### Example Custom Database Setup Script

```bash
#!/bin/bash
# custom-scripts/01-create-app-db.sh
set -e

DB_NAME="${APP_DB_NAME:-myapp}"
DB_USER="${APP_DB_USER:-myapp}"
DB_PASSWORD="${APP_DB_PASSWORD:-password}"

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
```

### Docker Compose Example

```yaml
version: '3.8'
services:
  postgres:
    image: sportsight/postgres:latest
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      # Custom environment variables for your scripts
      APP_DB_NAME: myapp
      APP_DB_USER: myapp
      APP_DB_PASSWORD: myapp_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./custom-scripts:/docker-entrypoint-initdb.d/custom-init.d
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

## Build Arguments

- `PG_MAJOR`: PostgreSQL major version (default: 17)
- `PGVECTOR_VERSION`: pgvector version (default: v0.8.0)
- `PG_CRON_VERSION`: pg_cron version (default: v1.6.4)

```bash
docker build \
  --build-arg PG_MAJOR=16 \
  --build-arg PGVECTOR_VERSION=v0.7.0 \
  -t my-postgres .
```

## Initialization Order

1. **01-enable-extensions.sh** - Installs pg_cron extension
2. **Your custom scripts** (executed in lexicographical order)
3. **99-run-custom-scripts.sh** - Processes custom-init.d directory

## Environment Variables

Standard PostgreSQL environment variables:
- `POSTGRES_DB` - Initial database name
- `POSTGRES_USER` - Superuser name
- `POSTGRES_PASSWORD` - Superuser password

Plus any custom variables your initialization scripts require.

## Extensions Included

- **pgvector**: Vector similarity search
- **pg_cron**: PostgreSQL job scheduler

## Configuration

The image includes optimized PostgreSQL configuration in `config/postgresql.conf` with:
- Shared preload libraries for extensions
- Optimized memory settings
- Performance tuning parameters

## CI/CD with GitHub Actions

This repository includes automated Docker image building and publishing using GitHub Actions with Docker Build Cloud for faster multi-platform builds.

### Automated Builds

The GitHub Actions workflow automatically:
- Builds multi-platform images (linux/amd64, linux/arm64) on pushes to main
- Creates tagged releases when you push version tags (e.g., `v1.0.0`)
- Validates builds on pull requests without publishing

### Required Repository Configuration

To enable automated builds, configure these repository secrets and variables:

**Repository Variables** (Settings → Secrets and variables → Actions → Variables):
- `DOCKER_USER`: Your Docker Hub username or organization name
- `DOCKER_ORG`: Your Docker organization name for Build Cloud

**Repository Secrets** (Settings → Secrets and variables → Actions → Secrets):
- `DOCKER_PAT`: Docker Hub Personal Access Token with read/write permissions

### Setup Instructions

1. **Create Docker Hub Personal Access Token:**
   - Go to Docker Hub → Account Settings → Security → New Access Token
   - Name it "GitHub Actions Build Cloud"
   - Set permissions to Read & Write
   - Copy the generated token

2. **Configure GitHub Repository:**
   - Navigate to your repository → Settings → Secrets and variables → Actions
   - Add the variables and secrets listed above

3. **Ensure Docker Build Cloud Access:**
   - Verify your Docker Hub account has Build Cloud enabled
   - The workflow will use your organization's default Build Cloud endpoint

### Publishing Images

Images are published to Docker Hub with the following tags:
- `latest`: Latest build from main branch
- `<branch-name>`: Builds from specific branches
- `<version>`: Semantic version tags (e.g., `1.0.0`, `1.0`)

Published image: [`docker.io/sportsight/postgres`](https://hub.docker.com/r/sportsight/postgres)

## License

This image includes:
- PostgreSQL (PostgreSQL License)
- pgvector (PostgreSQL License)  
- pg_cron (PostgreSQL License)