#!/bin/bash

# --- Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Functions ---
# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Main Script ---

# 1. Check if MySQL is already installed
if command_exists mysql; then
  echo "MySQL is already installed. Skipping installation."
else
  # Prompt for the new MySQL root password
  read -s -p "Enter the new MySQL root password: " root_password
  echo

  # Set the DEBIAN_FRONTEND to noninteractive to avoid prompts
  export DEBIAN_FRONTEND=noninteractive

  # Pre-configure the MySQL installation with the root password
  # This is the most reliable way to set the password non-interactively
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $root_password"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $root_password"

  # Install MySQL Server
  echo "Installing MySQL Server..."
  sudo apt-get update
  sudo apt-get install -y mysql-server
fi

# 2. Secure the MySQL installation
# Run SQL commands to perform the same actions as mysql_secure_installation
echo "Securing MySQL installation..."
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

echo "MySQL server has been installed and configured securely."
