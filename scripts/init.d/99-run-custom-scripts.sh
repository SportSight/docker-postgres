#!/bin/bash
set -e

echo "Looking for custom initialization scripts in /docker-entrypoint-initdb.d/custom-init.d/..."

# Check if custom-init.d directory exists and has files
if [ -d "/docker-entrypoint-initdb.d/custom-init.d" ] && [ "$(ls -A /docker-entrypoint-initdb.d/custom-init.d)" ]; then
    echo "Found custom initialization scripts, executing them..."
    
    # Execute all executable scripts in custom-init.d directory
    for script in /docker-entrypoint-initdb.d/custom-init.d/*; do
        if [ -f "$script" ]; then
            case "$script" in
                *.sh)
                    if [ -x "$script" ]; then
                        echo "Running custom script: $script"
                        "$script"
                    else
                        echo "Sourcing custom script: $script"
                        . "$script"
                    fi
                    ;;
                *.sql)
                    echo "Executing SQL file: $script"
                    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$script"
                    ;;
                *.sql.gz)
                    echo "Executing compressed SQL file: $script"
                    gunzip -c "$script" | psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
                    ;;
                *)
                    echo "Ignoring unsupported file: $script"
                    ;;
            esac
        fi
    done
    
    echo "Custom initialization scripts completed."
else
    echo "No custom initialization scripts found."
fi