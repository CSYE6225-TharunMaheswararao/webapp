#!/bin/bash
set -e  # Exit immediately if a command fails

# Debugging: Print environment variables
echo "🔹 Checking environment variables..."
echo "DB_USER: ${DB_USER:-NOT SET}"
echo "DB_PASSWORD: ${DB_PASSWORD:-NOT SET}"

# Ensure required environment variables are set
if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
    echo "❌ ERROR: DB_USER and DB_PASSWORD must be set!"
    exit 1
fi

echo "✅ Using DB_USER: $DB_USER"
echo "✅ Setting up MySQL with secure credentials..."

# Variables
DB_NAME="healthify"
DB_HOST="127.0.0.1"
DB_PORT="3306"
APP_DIR="/opt/csye6225"
ZIP_FILE="Tharun_Maheswararao_002310838_02.zip"
CONFIG_FILE="${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp/app/app.config"
VENV_DIR="${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp/venv"
RUN_SCRIPT="${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp/run.py"
FLASK_SERVICE="flask_api"

# Ensure we are using Bash
if [ -z "$BASH_VERSION" ]; then
    echo "This script must be run in Bash. Please run: bash setup.sh"
    exit 1
fi

# Step 1: Fix broken package lists and update system
echo "🔹 Fixing package lists..."
sudo rm -rf /var/lib/apt/lists/*
sudo mkdir -p /var/lib/apt/lists/partial
sudo apt update --allow-releaseinfo-change -y
sudo apt upgrade -y

# Step 2: Install required dependencies
echo "🔹 Installing dependencies..."
sudo apt install -y wget gnupg2 lsb-release unzip python3-venv python3-pip software-properties-common

# Fix missing `ufw`
sudo apt install -y ufw || echo "⚠️ WARNING: 'ufw' not found, skipping..."

echo "✅ Dependencies installed successfully!"

# Step 3: Add MySQL Repository & Install MySQL 8.0
echo "🔹 Adding MySQL repository and GPG key..."

# Download the MySQL APT configuration package
wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb

# Install the MySQL APT configuration package (Suppress interactive prompt)
export DEBIAN_FRONTEND=noninteractive
sudo dpkg -i mysql-apt-config_0.8.29-1_all.deb

# Update package lists
sudo apt update -y

# Install MySQL Server
echo "🔹 Installing MySQL Server..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

# Step 4: Start and Enable MySQL Service
echo "🔹 Starting MySQL..."
sudo systemctl enable mysql
sudo systemctl start mysql

# Step 5: Secure MySQL Installation & Reset Root Password
echo "🔹 Configuring MySQL authentication..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Step 6: Restart MySQL to Apply Changes
echo "🔹 Restarting MySQL to apply authentication changes..."
sudo systemctl restart mysql

# Step 7: Create MySQL Database and User
echo "🔹 Creating MySQL database and user..."
sudo mysql -u root -p${DB_PASSWORD} -e "
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
"

# Step 7: Create application directory
echo "🔹 Setting up application directory..."
sudo mkdir -p ${APP_DIR}

# Step 8: Unzip the application
echo "🔹 Extracting application..."
sudo unzip -o ${ZIP_FILE} -d ${APP_DIR}

# Step 9: Update `app.config` with database details
echo "🔹 Writing database credentials to app.config..."
sudo tee $CONFIG_FILE > /dev/null <<EOF
[DATABASE]
DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF

echo "✅ app.config updated successfully!"
cat $CONFIG_FILE

# Step 10: Set permissions
echo "🔹 Setting file permissions..."
sudo chown -R $(whoami) ${APP_DIR}
sudo chmod -R 755 ${APP_DIR}

# Step 11: Create a virtual environment
echo "🔹 Creating a virtual environment..."
python3 -m venv ${VENV_DIR}

# Step 12: Activate `venv` and Install Dependencies
echo "🔹 Activating virtual environment and installing dependencies..."
. ${VENV_DIR}/bin/activate
pip install --upgrade pip
pip install -r ${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp/requirements.txt
deactivate

# Step 13: Open Port 8080 in Firewall
echo "🔹 Configuring firewall..."
sudo ufw allow 8080/tcp
sudo ufw enable
sudo ufw reload

# Step 14: Modify `run.py` to Allow External Access
echo "🔹 Ensuring Flask listens on 0.0.0.0..."
sudo sed -i 's/^.*app.run(host=.*$/    app.run(host="0.0.0.0", port=8080, debug=True)/' ${RUN_SCRIPT}

# Step 15: Creating System User `csye6225` (Non-Login)
echo "🔹 Creating non-login user 'csye6225'..."
sudo useradd --system --no-create-home --shell /usr/sbin/nologin csye6225

# Step 16: Set Up `systemd` Service for Flask API
echo "🔹 Creating systemd service for Flask API..."
sudo tee /etc/systemd/system/${FLASK_SERVICE}.service > /dev/null <<EOF
[Unit]
Description=Flask API Service
After=network.target

[Service]
User=csye6225
Group=csye6225
WorkingDirectory=${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp
ExecStart=${VENV_DIR}/bin/python3 run.py
Restart=always
Environment="FLASK_APP=${RUN_SCRIPT}"
Environment="PYTHONPATH=${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp"
Environment="DB_CONNECTION=mysql"
Environment="DB_HOST=${DB_HOST}"
Environment="DB_PORT=${DB_PORT}"
Environment="DB_NAME=${DB_NAME}"
Environment="DB_USERNAME=${DB_USER}"
Environment="DB_PASSWORD=${DB_PASSWORD}"

[Install]
WantedBy=multi-user.target
EOF

# Step 17: Reload systemd and Start Flask API
echo "🔹 Starting Flask API using systemd..."
sudo systemctl daemon-reload
sudo systemctl start ${FLASK_SERVICE}
sudo systemctl enable ${FLASK_SERVICE}

echo "🚀 Deployment completed successfully!"
echo "✅ API is live at: http://$(curl -4 ifconfig.me):8080/healthz"
