#!/bin/bash

# --- Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

echo "v1"

# --- Main Script ---

# 1. Check if the MySQL SERVER package is already installed.
# This is a more robust check than looking for the 'mysql' command.
if dpkg-query -W -f='${Status}' mysql-server 2>/dev/null | grep -q "ok installed"; then
  echo "MySQL Server is already installed. Skipping installation."
else
  # Prompt for the new MySQL root password ONLY if installing.
  read -s -p "Enter the new MySQL root password: " root_password
  echo # Adds a newline for cleaner output

  # Set the DEBIAN_FRONTEND to noninteractive to avoid prompts
  export DEBIAN_FRONTEND=noninteractive

  # Pre-configure the MySQL installation with the root password
  echo "Pre-configuring MySQL with the provided password..."
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $root_password"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $root_password"

  # Install MySQL Server
  echo "Installing MySQL Server..."
  sudo apt-get update
  sudo apt-get install -y mysql-server

  # 2. Secure the MySQL installation
  # This section now runs only after a fresh install.
  echo "Securing MySQL installation..."
  # Note: Use the password variable defined during the install prompt.
  sudo mysql --user=root --password="$root_password" <<_EOF_
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload privilege tables
FLUSH PRIVILEGES;
_EOF_

fi

echo "MySQL configuration check complete."
