#!/bin/bash
set -e

echo "Starting QGIS Server container setup..."

# Create required directories
mkdir -p /var/log/qgis
chmod 777 /var/log/qgis

# Create and set permissions for QGIS authentication DB directory
mkdir -p /var/lib/qgis/.local/share/QGIS/QGIS3/profiles/default/qgis-auth.db/
chmod -R 777 /var/lib/qgis/
echo "QGIS Auth DB directory created at: $QGIS_AUTH_DB_DIR_PATH"

# Create symbolic link for data files
echo "Setting up data directory symlinks..."
mkdir -p /etc/data
for file in /var/lib/qgisserver/data/*; do
  if [ -f "$file" ]; then
    ln -sf "$file" "/etc/data/$(basename "$file")"
  fi
done
ls -la /etc/data/
echo "Data files linked to /etc/data/"

if [ -f "$QGIS_PROJECT_FILE" ]; then
    echo "Using QGIS project file: $QGIS_PROJECT_FILE"
    echo "Project file contains these layers:"
    grep "<shortname>" "$QGIS_PROJECT_FILE" || echo "No shortname tags found"
else
    echo "Warning: QGIS project file not found at $QGIS_PROJECT_FILE"
    echo "Available project files:"
    find /etc/qgisserver -name "*.qgs" -o -name "*.qgz" | sort
fi

# Make required directories accessible to www-data
echo "Setting proper permissions..."
chmod -R 755 /etc/data
chown -R www-data:www-data /etc/data
chown -R www-data:www-data /var/lib/qgis

# Start fcgiwrap
echo "Starting fcgiwrap..."
spawn-fcgi -u www-data -g www-data -s /var/run/fcgiwrap.socket /usr/sbin/fcgiwrap
chmod 777 /var/run/fcgiwrap.socket

# Start Xvfb (needed for QGIS Server rendering)
echo "Starting Xvfb..."
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset > /dev/null 2>&1 &
export DISPLAY=:99

echo "QGIS Server configuration:"
echo "- Project file: $QGIS_PROJECT_FILE"
echo "- Log level: $QGIS_SERVER_LOG_LEVEL"
echo "- Auth DB path: $QGIS_AUTH_DB_DIR_PATH"

# Fix permissions for project directories
echo "Setting additional permissions..."
chmod -R 755 /etc/qgisserver || true
chmod -R 755 /var/lib/qgisserver/data || true

# Validate NGINX configuration
echo "Validating NGINX configuration..."
nginx -t || { echo "NGINX configuration is invalid"; exit 1; }

# Start nginx in foreground
echo "Starting nginx..."
nginx -g "daemon off;"
