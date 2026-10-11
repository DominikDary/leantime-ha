#!/usr/bin/env bash
set -e

CONFIG_PATH="/data/options.json"

# Helper function to read options with a fallback default
get_config() {
    local key="$1"
    local default="$2"
    if [ -f "$CONFIG_PATH" ]; then
        local val
        val=$(jq --raw-output ".$key // empty" "$CONFIG_PATH" 2>/dev/null || true)
        if [ -n "$val" ] && [ "$val" != "null" ]; then
            echo "$val"
            return
        fi
    fi
    echo "$default"
}

echo "===================================================="
echo " Starting Leantime Home Assistant Add-on"
echo "===================================================="

# Read options configured via Home Assistant UI
DB_HOST=$(get_config "db_host" "localhost")
DB_PORT=$(get_config "db_port" "3306")
DB_USER=$(get_config "db_user" "leantime")
DB_NAME=$(get_config "db_name" "leantime")
DB_PASSWORD=$(get_config "db_password" "ChangeThisSecretPassword123!")
SESSION_PASSWORD=$(get_config "session_password" "GenerateA32CharRandomString123!")
APP_URL=$(get_config "app_url" "")
SITE_NAME=$(get_config "site_name" "Leantime")

# Setup persistent directory structure under /data
# (Home Assistant persists /data across container rebuilds and updates)
MYSQL_DATA_DIR="/data/mysql"
LEANTIME_DATA_DIR="/data/leantime"
USERFILES_PERSISTENT_DIR="${LEANTIME_DATA_DIR}/userfiles"

mkdir -p "${USERFILES_PERSISTENT_DIR}"
chown -R www-data:www-data "${LEANTIME_DATA_DIR}"

# Persist uploaded user files across updates
if [ -d "/var/www/html/userfiles" ] && [ ! -L "/var/www/html/userfiles" ]; then
    echo "[INFO] Linking user files to persistent storage..."
    cp -rn /var/www/html/userfiles/* "${USERFILES_PERSISTENT_DIR}/" 2>/dev/null || true
    rm -rf /var/www/html/userfiles
    ln -s "${USERFILES_PERSISTENT_DIR}" /var/www/html/userfiles
    chown -h www-data:www-data /var/www/html/userfiles
fi

# Internal MariaDB setup if DB_HOST is localhost or 127.0.0.1
if [ "$DB_HOST" = "localhost" ] || [ "$DB_HOST" = "127.0.0.1" ]; then
    echo "[INFO] Internal MariaDB database requested."
    mkdir -p /run/mysqld "${MYSQL_DATA_DIR}"
    chown -R mysql:mysql /run/mysqld "${MYSQL_DATA_DIR}"

    # Initialize MariaDB data directory if not already done
    if [ ! -d "${MYSQL_DATA_DIR}/mysql" ]; then
        echo "[INFO] Initializing MariaDB system tables in ${MYSQL_DATA_DIR}..."
        mariadb-install-db --user=mysql --datadir="${MYSQL_DATA_DIR}" --skip-test-db > /dev/null
        echo "[INFO] MariaDB tables initialized."
    fi

    # Start MariaDB temporarily to configure database and user credentials
    echo "[INFO] Starting MariaDB temporarily for initialization..."
    /usr/bin/mariadbd --user=mysql --datadir="${MYSQL_DATA_DIR}" --socket=/run/mysqld/mysqld.sock --port=3306 --bind-address=127.0.0.1 > /data/mariadb-init.log 2>&1 &
    MARIADB_PID=$!

    # Wait for MariaDB socket to be ready
    echo "[INFO] Waiting for MariaDB socket..."
    READY=0
    for i in $(seq 1 30); do
        if mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; then
            READY=1
            break
        fi
        sleep 1
    done

    if [ "$READY" -ne 1 ]; then
        echo "[ERROR] MariaDB failed to start during initialization. Log output:"
        cat /data/mariadb-init.log 2>/dev/null || true
        exit 1
    fi

    # Escape single quotes in password for safe SQL execution
    SAFE_DB_PASSWORD=$(echo "$DB_PASSWORD" | sed "s/'/''/g")

    echo "[INFO] Provisioning database '${DB_NAME}' and user '${DB_USER}'..."
    mariadb -u root --socket=/run/mysqld/mysqld.sock <<EOSQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${SAFE_DB_PASSWORD}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${SAFE_DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${SAFE_DB_PASSWORD}';
ALTER USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${SAFE_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
EOSQL

    # Shut down temporary MariaDB process
    echo "[INFO] Shutting down temporary MariaDB process..."
    mariadb-admin --socket=/run/mysqld/mysqld.sock shutdown
    wait "$MARIADB_PID" 2>/dev/null || true
    echo "[INFO] MariaDB provisioning completed."

    # Configure supervisord to manage MariaDB as a persistent service
    if ! grep -q "\[program:mariadb\]" /etc/supervisor/conf.d/supervisord.conf; then
        echo "[INFO] Adding MariaDB service definition to supervisord configuration..."
        cat >> /etc/supervisor/conf.d/supervisord.conf << 'EOF'

[program:mariadb]
command=/usr/bin/mariadbd --user=mysql --datadir=/data/mysql --socket=/run/mysqld/mysqld.sock --port=3306 --bind-address=127.0.0.1
autostart=true
autorestart=true
priority=1
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF
    fi

    # Export 127.0.0.1 for Leantime PHP connection
    export LEAN_DB_HOST="127.0.0.1"
else
    echo "[INFO] External database configured (${DB_HOST}:${DB_PORT}). Skipping internal MariaDB."
    export LEAN_DB_HOST="${DB_HOST}"
fi

# Export Leantime environment variables
export LEAN_DB_PORT="${DB_PORT}"
export LEAN_DB_USER="${DB_USER}"
export LEAN_DB_PASSWORD="${DB_PASSWORD}"
export LEAN_DB_DATABASE="${DB_NAME}"
export LEAN_SESSION_PASSWORD="${SESSION_PASSWORD}"
export LEAN_SITENAME="${SITE_NAME}"

if [ -n "$APP_URL" ]; then
    export LEAN_APP_URL="${APP_URL}"
fi

# Ensure run directory exists for supervisor pid file
mkdir -p /run

echo "[INFO] Starting Leantime services (PHP-FPM, Nginx, Scheduler, MariaDB)..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
