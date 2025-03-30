#!/bin/bash

# Docker Installation Script
# Purpose: Installs Docker Engine and Docker Compose
# This script sets up Docker with the official repository and configures it for use

echo "Installing Docker and Docker Compose..."

# Prevent Interactive Prompts
# Purpose: Configure system to run non-interactively during installation
export DEBIAN_FRONTEND=noninteractive

# Configure debconf for automatic service restart
# Purpose: Prevent prompts during package installation
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

# Check if Docker is already installed
# Purpose: Skip installation if Docker is already present
if ! [ -x "$(command -v docker)" ]; then
  echo "Docker is not installed. Installing Docker..."
  
  # Update System
  # Purpose: Ensure package list is up-to-date before installation
  sudo DEBIAN_FRONTEND=noninteractive apt-get -qq update
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to update package list"
    exit 1
  fi
  
  # Install Required Packages
  # Purpose: Install dependencies needed for Docker installation
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
  
  # Set up Docker Repository
  # Purpose: Add official Docker repository for installation
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create directory for keys"
    exit 1
  fi
  
  # Download Docker GPG Key
  # Purpose: Add Docker's official GPG key for package verification
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download Docker GPG key"
    exit 1
  fi
  
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  
  # Add Docker Repository
  # Purpose: Configure system to use Docker's official repository
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to add Docker repository"
    exit 1
  fi
  
  # Update Package List
  # Purpose: Refresh package list to include Docker repository
  sudo DEBIAN_FRONTEND=noninteractive apt-get -qq update
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to update package list after adding Docker repository"
    exit 1
  fi
  
  # Install Docker
  # Purpose: Install Docker Engine and related tools
  sudo DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    $APT_OPTIONS

  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Docker"
    exit 1
  fi
  
  # Configure User Permissions
  # Purpose: Add current user to docker group for non-root access
  sudo usermod -aG docker $USER
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to add user to the docker group. You may need root privileges to run docker."
  fi
  
  # Start Docker Service
  # Purpose: Ensure Docker daemon is running
  sudo systemctl start docker
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start Docker service"
    exit 1
  fi
  
  # Enable Docker Service
  # Purpose: Configure Docker to start on system boot
  sudo systemctl enable docker
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to enable Docker service"
  fi
  
  echo "Docker successfully installed"
else
  echo "Docker is already installed"
fi

# Verify Docker Installation
# Purpose: Check if Docker is working correctly
docker --version
if [ $? -ne 0 ]; then
  echo "ERROR: Docker is installed but not working correctly"
  exit 1
fi

# Verify Docker Compose Installation
# Purpose: Check if Docker Compose is working correctly
docker compose version
if [ $? -ne 0 ]; then
  echo "ERROR: Docker Compose is not working correctly"
  exit 1
fi

echo "✅ Docker and Docker Compose successfully installed and running"
exit 0