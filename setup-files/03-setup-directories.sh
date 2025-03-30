#!/bin/bash

# Directory Setup Script
# Purpose: Creates necessary directories and users for running services
# This script sets up the file structure and permissions for all services

# Get variables from the main script via arguments
USER_EMAIL=$1
DOMAIN_NAME=$2
GENERIC_TIMEZONE=$3

# Validate required arguments
# Purpose: Ensure all necessary information is provided
if [ -z "$USER_EMAIL" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "ERROR: Email or domain name not specified"
  echo "Usage: $0 user@example.com example.com [timezone]"
  exit 1
fi

if [ -z "$GENERIC_TIMEZONE" ]; then
  GENERIC_TIMEZONE="UTC"
fi

echo "Setting up directories and users..."

# Create n8n User
# Purpose: Set up a dedicated user for running services
if ! id "n8n" &>/dev/null; then
  echo "Creating n8n user..."
  sudo adduser --disabled-password --gecos "" n8n
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create n8n user"
    exit 1
  fi
  
  # Generate random password for n8n user
  # Purpose: Set a secure password for the service user
  N8N_PASSWORD=$(openssl rand -base64 12)
  echo "n8n:$N8N_PASSWORD" | sudo chpasswd
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to set password for n8n user"
    exit 1
  fi
  
  echo "✅ Created n8n user with password: $N8N_PASSWORD"
  echo "⚠️ IMPORTANT: Write down this password, you will need it for working with Docker!"
  
  # Add n8n user to docker group
  # Purpose: Allow n8n user to run Docker commands
  sudo usermod -aG docker n8n
  if [ $? -ne 0 ]; then
    echo "WARNING: Failed to add n8n user to docker group"
    # Not exiting as this is not a critical error
  fi
else
  echo "User n8n already exists"
  
  # Optional password reset for existing user
  # Purpose: Allow updating the password if needed
  read -p "Do you want to reset the password for n8n user? (y/n): " reset_password
  if [ "$reset_password" = "y" ]; then
    N8N_PASSWORD=$(openssl rand -base64 12)
    echo "n8n:$N8N_PASSWORD" | sudo chpasswd
    if [ $? -ne 0 ]; then
      echo "ERROR: Failed to reset password for n8n user"
    else
      echo "✅ Password for n8n user has been reset: $N8N_PASSWORD"
      echo "⚠️ IMPORTANT: Write down this password, you will need it for working with Docker!"
    fi
  fi
fi

# Create Service Directories
# Purpose: Set up directories for each service's data and configuration
echo "Creating directories..."
sudo mkdir -p /opt/n8n
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create directory /opt/n8n"
  exit 1
fi

sudo mkdir -p /opt/n8n/files
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create directory /opt/n8n/files"
  exit 1
fi

sudo mkdir -p /opt/flowise
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create directory /opt/flowise"
  exit 1
fi

sudo mkdir -p /opt/ollama
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create directory /opt/ollama"
  exit 1
fi

sudo mkdir -p /opt/openwebui
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create directory /opt/openwebui"
  exit 1
fi

sudo mkdir -p /opt/supabase
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create directory /opt/supabase"
  exit 1
fi

# Set Directory Permissions
# Purpose: Ensure n8n user has access to all service directories
sudo chown -R n8n:n8n /opt/n8n
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to change owner of directory /opt/n8n"
  exit 1
fi

sudo chown -R n8n:n8n /opt/flowise
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to change owner of directory /opt/flowise"
  exit 1
fi

sudo chown -R n8n:n8n /opt/ollama
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to change owner of directory /opt/ollama"
  exit 1
fi

sudo chown -R n8n:n8n /opt/openwebui
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to change owner of directory /opt/openwebui"
  exit 1
fi

sudo chown -R n8n:n8n /opt/supabase
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to change owner of directory /opt/supabase"
  exit 1
fi

# Create Docker Volumes
# Purpose: Set up persistent storage for all services
echo "Creating Docker volumes..."
sudo docker volume create n8n_data
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create Docker volume n8n_data"
  exit 1
fi

sudo docker volume create caddy_data
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create Docker volume caddy_data"
  exit 1
fi

sudo docker volume create ollama_data
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create Docker volume ollama_data"
  exit 1
fi

sudo docker volume create supabase_data
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create Docker volume supabase_data"
  exit 1
fi

sudo docker volume create openwebui_data
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create Docker volume openwebui_data"
  exit 1
fi

echo "✅ Directories and users successfully configured"
exit 0 