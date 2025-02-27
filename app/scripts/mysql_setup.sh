#!/bin/bash
set -e  # Exit on error

DB_NAME="healthify"
DB_USER=${DB_USER:-"default_user"}
DB_PASSWORD=${DB_PASSWORD:-"default_password"}

echo "🔹 Configuring MySQL authentication..."

# Secure MySQL root user
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Restart MySQL to apply changes
sudo systemctl restart mysql

echo "🔹 Creating database and user..."
sudo mysql -u root -p${DB_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
"

echo "✅ MySQL setup completed successfully!"
