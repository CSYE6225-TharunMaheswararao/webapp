#!/bin/bash

# Variables
DB_NAME="healthify"
DB_USER=$1
DB_PASSWORD=$2
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

# Step 1: Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Step 2: Install required dependencies
echo "Installing dependencies..."
sudo apt install -y mysql-server python3-venv python3-pip unzip ufw

# Step 3: Start and enable MySQL
echo "Starting MySQL..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Step 4: Configure MySQL root user to use password authentication
echo "Fixing MySQL authentication issues..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Step 5: Create MySQL Database and User
echo "Configuring MySQL database..."
sudo mysql -u root -p${DB_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
sudo mysql -u root -p${DB_PASSWORD} -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -u root -p${DB_PASSWORD} -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -u root -p${DB_PASSWORD} -e "FLUSH PRIVILEGES;"

# Step 6: Create application directory
echo "Setting up application directory..."
sudo mkdir -p ${APP_DIR}

# Step 7: Unzip the application
echo "Extracting application..."
sudo unzip -o ${ZIP_FILE} -d ${APP_DIR}

# Step 8: Update `app.config` with database details
if [ ! -s "$CONFIG_FILE" ]; then
    echo "app.config is empty. Writing default configuration..."
    sudo bash -c "cat > $CONFIG_FILE <<EOF
[DATABASE]
DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF"
fi

echo "app.config updated successfully!"
cat $CONFIG_FILE

# Step 9: Set permissions
echo "Setting file permissions..."
sudo chown -R $(whoami) ${APP_DIR}
sudo chmod -R 755 ${APP_DIR}

# Step 10: Create a virtual environment
echo "Creating a virtual environment..."
python3 -m venv ${VENV_DIR}

# Step 11: Activate `venv` and Install Dependencies
echo "Activating virtual environment and installing dependencies..."
. ${VENV_DIR}/bin/activate
pip install --upgrade pip
pip install -r ${APP_DIR}/Tharun_Maheswararao_002310838_02/webapp/requirements.txt

# Step 12: Deactivate `venv` (Safely)
deactivate || echo "Virtual environment deactivated."

# Step 13: Open Port 8080 in Firewall
echo "Configuring firewall..."
sudo ufw allow 8080/tcp
sudo ufw enable
sudo ufw reload

# Step 14: Modify `run.py` to Allow External Access
echo "Ensuring Flask listens on 0.0.0.0..."
sudo sed -i 's/^.*app.run(host=.*$/    app.run(host="0.0.0.0", port=8080, debug=True)/' ${RUN_SCRIPT}

# Step 15: Set Up `systemd` Service for Flask
echo "Creating systemd service for Flask API..."
sudo bash -c "cat > /etc/systemd/system/${FLASK_SERVICE}.service <<EOF
[Unit]
Description=Flask API Service
After=network.target

[Service]
User=$(whoami)
Group=$(whoami)
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
EOF"

# Step 16: Reload systemd and Start Flask API
echo "Starting Flask API using systemd..."
sudo systemctl daemon-reload
sudo systemctl start ${FLASK_SERVICE}
sudo systemctl enable ${FLASK_SERVICE}

echo "Deployment completed!"
echo "API is live at: http://$(curl -4 ifconfig.me):8080/healthz"
