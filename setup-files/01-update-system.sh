#!/bin/bash

echo "Updating system..."

# Setting environment variables to prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Configuring debconf for automatic service restart
echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo bash -c "cat > /etc/apt/apt.conf.d/70debconf << EOF
Dpkg::Options {
   \"--force-confdef\";
   \"--force-confold\";
}
EOF"

# apt options for automatic confirmation and preventing prompts
APT_OPTIONS="-o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef -y"

# Update package list
sudo apt-get update
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to update package list"
  exit 1
fi

# Install required packages
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

# Upgrade system
sudo DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade $APT_OPTIONS
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to upgrade packages"
  exit 1
fi

# Clean up
sudo apt-get autoremove $APT_OPTIONS
sudo apt-get clean

echo "✅ System successfully updated"
exit 0