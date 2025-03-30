#!/bin/bash

# System Update Script
# Purpose: Updates the system packages and installs necessary dependencies
# This script ensures the system is up-to-date and has all required packages

echo "Updating system..."

# Prevent Interactive Prompts
# Purpose: Configure system to run non-interactively during updates
export DEBIAN_FRONTEND=noninteractive

# Configure debconf for automatic service restart
# Purpose: Prevent prompts during package installation and updates
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo bash -c "cat > /etc/apt/apt.conf.d/70debconf << EOF
Dpkg::Options {
   \"--force-confdef\";
   \"--force-confold\";
}
EOF"

# Configure apt options for automatic confirmation
# Purpose: Prevent prompts during package operations
APT_OPTIONS="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y"

# Update Package List
# Purpose: Refresh the list of available packages
sudo apt-get update
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to update package list"
  exit 1
fi

# Install Required Packages
# Purpose: Install system dependencies needed for Docker and other services
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  $APT_OPTIONS

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to install required packages"
  exit 1
fi

# Upgrade System Packages
# Purpose: Update all installed packages to their latest versions
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade $APT_OPTIONS
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to upgrade packages"
  exit 1
fi

# Clean Up
# Purpose: Remove unnecessary packages and clean package cache
sudo apt-get autoremove $APT_OPTIONS
sudo apt-get clean

echo "✅ System successfully updated"
exit 0