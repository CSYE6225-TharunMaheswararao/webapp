#!/bin/bash
set -e  # Exit on error

echo "🔹 Creating non-login system user 'csye6225'..."
if ! id "csye6225" &>/dev/null; then
    sudo groupadd csye6225
    sudo useradd --system --no-create-home --shell /usr/sbin/nologin -g csye6225 csye6225
    echo "✅ User 'csye6225' created successfully."
else
    echo "⚠️ User 'csye6225' already exists, skipping creation."
fi
