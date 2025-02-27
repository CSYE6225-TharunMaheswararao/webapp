#!/bin/bash
set -e  # Exit on error

echo "🔹 Creating application directory..."
sudo mkdir -p /opt/webapp

echo "🔹 Copying application artifact..."
sudo cp /tmp/webapp.zip /opt/webapp/webapp.zip

echo "🔹 Extracting application..."
sudo unzip -o /opt/webapp/webapp.zip -d /opt/webapp/
sudo rm -f /opt/webapp/webapp.zip  # Cleanup zip

echo "🔹 Setting ownership to user 'csye6225'..."
sudo chown -R csye6225:csye6225 /opt/webapp
sudo chmod -R 755 /opt/webapp

echo "🔹 Creating virtual environment..."
sudo -u csye6225 python3 -m venv /opt/webapp/venv

echo "🔹 Installing application dependencies..."
sudo -u csye6225 /opt/webapp/venv/bin/pip install --upgrade pip
sudo -u csye6225 /opt/webapp/venv/bin/pip install -r /opt/webapp/requirements.txt

echo "🔹 Writing database config to app.config..."
cat <<EOF | sudo tee /opt/webapp/app/app.config > /dev/null
[DATABASE]
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
EOF

echo "🔹 Setting permissions for app.config..."
sudo chown csye6225:csye6225 /opt/webapp/app/app.config
sudo chmod 600 /opt/webapp/app/app.config  # Restrict access for security

echo "✅ Application setup completed successfully!"
