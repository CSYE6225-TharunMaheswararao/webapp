#!/bin/bash
set -e  # Exit on error

echo "🔹 Setting up systemd service for the Flask application..."

sudo cp /tmp/webapp.service /etc/systemd/system/webapp.service
sudo chmod 644 /etc/systemd/system/webapp.service

echo "🔹 Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "🔹 Enabling webapp service to start on boot..."
sudo systemctl enable webapp.service

echo "✅ Systemd service setup completed!"
