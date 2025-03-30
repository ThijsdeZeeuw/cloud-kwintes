#!/bin/bash

# Refresh Script
# Purpose: Safely refresh all files from the repository while preserving local changes
# This script ensures a clean update without losing important local configurations

echo "Starting refresh process..."

# Function to check if a file has local changes
has_local_changes() {
  local file=$1
  if [ -f "$file" ]; then
    if git diff --quiet "$file" 2>/dev/null; then
      return 1  # No local changes
    else
      return 0  # Has local changes
    fi
  fi
  return 1  # File doesn't exist
}

# Function to backup a file
backup_file() {
  local file=$1
  if [ -f "$file" ]; then
    cp "$file" "${file}.backup"
    echo "✅ Backed up $file"
  fi
}

# Function to restore a file
restore_file() {
  local file=$1
  if [ -f "${file}.backup" ]; then
    mv "${file}.backup" "$file"
    echo "✅ Restored $file"
  fi
}

# Check if we're in the correct directory
if [ ! -d ".git" ]; then
  echo "❌ Not in a git repository. Please run this script from the cloud-kwintes directory."
  exit 1
fi

# Create a backup directory
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Backup important files
echo "Backing up important files..."
backup_file "../.env"
backup_file "../setup-files/passwords.txt"
backup_file "../n8n-docker-compose.yaml"
backup_file "../flowise-docker-compose.yaml"
backup_file "../ollama-docker-compose.yaml"
backup_file "../openwebui-docker-compose.yaml"
backup_file "../supabase-docker-compose.yaml"
backup_file "../Caddyfile"

cd ..

# Check for local changes
echo "Checking for local changes..."
FILES_WITH_CHANGES=()
for file in .env setup-files/passwords.txt n8n-docker-compose.yaml flowise-docker-compose.yaml ollama-docker-compose.yaml openwebui-docker-compose.yaml supabase-docker-compose.yaml Caddyfile; do
  if has_local_changes "$file"; then
    FILES_WITH_CHANGES+=("$file")
    echo "⚠️ Found local changes in $file"
  fi
done

# If there are local changes, ask for confirmation
if [ ${#FILES_WITH_CHANGES[@]} -ne 0 ]; then
  echo "The following files have local changes:"
  printf '%s\n' "${FILES_WITH_CHANGES[@]}"
  read -p "Do you want to keep these changes? (y/n): " keep_changes
  if [ "$keep_changes" != "y" ]; then
    echo "❌ Refresh cancelled to preserve local changes"
    exit 1
  fi
fi

# Fetch latest changes
echo "Fetching latest changes from repository..."
git fetch origin
if [ $? -ne 0 ]; then
  echo "❌ Failed to fetch changes from repository"
  exit 1
fi

# Reset to origin/main
echo "Resetting to origin/main..."
git reset --hard origin/main
if [ $? -ne 0 ]; then
  echo "❌ Failed to reset to origin/main"
  exit 1
fi

# Clean untracked files
echo "Cleaning untracked files..."
git clean -fd
if [ $? -ne 0 ]; then
  echo "❌ Failed to clean untracked files"
  exit 1
fi

# Restore backed up files
echo "Restoring backed up files..."
cd "$BACKUP_DIR"
restore_file "../.env"
restore_file "../setup-files/passwords.txt"
restore_file "../n8n-docker-compose.yaml"
restore_file "../flowise-docker-compose.yaml"
restore_file "../ollama-docker-compose.yaml"
restore_file "../openwebui-docker-compose.yaml"
restore_file "../supabase-docker-compose.yaml"
restore_file "../Caddyfile"
cd ..

# Set execution permissions
echo "Setting execution permissions..."
chmod +x setup.sh
chmod +x setup-files/*.sh

echo "✅ Refresh completed successfully"
echo "Backup directory: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Review the changes in the repository"
echo "2. Test the setup with: ./setup.sh"
echo "3. If needed, restore from backup directory: $BACKUP_DIR" 