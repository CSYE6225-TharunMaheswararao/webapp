#!/bin/bash
set -e  # Exit on error

echo "🔹 Updating system packages..."
sudo apt update -y && sudo apt upgrade -y

echo "🔹 Installing dependencies..."
sudo apt install -y python3 python3-pip python3-venv unzip zip mysql-client software-properties-common

echo "✅ System setup complete."
