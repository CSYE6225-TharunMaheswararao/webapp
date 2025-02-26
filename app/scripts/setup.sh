#!/bin/bash
set -e

echo "🔹 Checking environment variables..."
echo "DB_USER: ${DB_USER:-NOT SET}"
echo "DB_PASSWORD: ${DB_PASSWORD:-NOT SET}"

if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
    echo "❌ ERROR: DB_USER and DB_PASSWORD must be set!"
    exit 1
fi

echo "✅ Setting up MySQL with secure credentials..."
DB_NAME="healthify"
DB_HOST="127.0.0.1"
DB_PORT="3306"
APP_DIR="/opt/webapp"

sudo apt update && sudo apt upgrade -y
sudo apt install -y mysql-server python3-venv python3-pip unzip

sudo systemctl enable mysql
sudo systemctl start mysql

echo "🔹 Configuring MySQL authentication..."
sudo mysql -e "
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
FLUSH PRIVILEGES;
"

echo "🔹 Creating MySQL database and user..."
sudo mysql -u root -p${DB_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
"

echo "🔹 Extracting application..."
sudo mkdir -p ${APP_DIR}
sudo unzip -o /tmp/webapp.zip -d ${APP_DIR}
sudo chown -R csye6225:csye6225 ${APP_DIR}

echo "🔹 Reloading systemd..."
sudo systemctl daemon-reload
sudo systemctl enable webapp
sudo systemctl restart webapp

echo "🚀 Deployment completed successfully!"
