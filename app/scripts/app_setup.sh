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

echo "✅ Application setup completed successfully!"
