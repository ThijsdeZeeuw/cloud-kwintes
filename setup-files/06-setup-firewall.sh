#!/bin/bash

# Firewall Setup Script
# Purpose: Configures UFW (Uncomplicated Firewall) to allow necessary traffic
# This script opens required ports for all services and enables the firewall

echo "Setting up firewall..."

# Check UFW Installation
# Purpose: Verify if UFW is installed and install if needed
if command -v ufw &> /dev/null; then
  echo "UFW is already installed, opening required ports..."
  
  # Open Required Ports
  # Purpose: Allow traffic for web services, Ollama, and Supabase
  sudo ufw allow 80  # HTTP
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 80"
    exit 1
  fi
  
  sudo ufw allow 443  # HTTPS
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 443"
    exit 1
  fi

  sudo ufw allow 11434  # Ollama API
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 11434"
    exit 1
  fi

  sudo ufw allow 5432  # Supabase Database
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 5432"
    exit 1
  fi
  
  # Check Firewall Status
  # Purpose: Ensure UFW is active
  sudo ufw status | grep -q "Status: active"
  if [ $? -ne 0 ]; then
    echo "UFW is not active, activating..."
    sudo ufw --force enable
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to activate UFW"
      exit 1
    fi
  fi
  
  echo "Ports 80, 443, 11434, and 5432 are open in the firewall"
else
  # Install UFW
  # Purpose: Install UFW if not present
  echo "UFW is not installed. Installing..."
  sudo apt-get install -y ufw
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install UFW"
    exit 1
  fi
  
  # Open Required Ports
  # Purpose: Allow traffic for all services
  sudo ufw allow 80  # HTTP
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 80"
    exit 1
  fi
  
  sudo ufw allow 443  # HTTPS
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 443"
    exit 1
  fi

  sudo ufw allow 11434  # Ollama API
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 11434"
    exit 1
  fi

  sudo ufw allow 5432  # Supabase Database
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to open port 5432"
    exit 1
  fi
  
  # Activate Firewall
  # Purpose: Enable UFW and apply rules
  sudo ufw --force enable
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to activate UFW"
    exit 1
  fi
  
  echo "Firewall installed and ports 80, 443, 11434, and 5432 are open"
fi

echo "✅ Firewall successfully configured"
exit 0 