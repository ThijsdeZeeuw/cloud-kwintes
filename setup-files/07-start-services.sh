#!/bin/bash

echo "Starting services..."

# Check for required files
if [ ! -f "n8n-docker-compose.yaml" ]; then
  echo "ERROR: File n8n-docker-compose.yaml not found"
  exit 1
fi

if [ ! -f "flowise-docker-compose.yaml" ]; then
  echo "ERROR: File flowise-docker-compose.yaml not found"
  exit 1
fi

if [ ! -f "ollama-docker-compose.yaml" ]; then
  echo "ERROR: File ollama-docker-compose.yaml not found"
  exit 1
fi

if [ ! -f "openwebui-docker-compose.yaml" ]; then
  echo "ERROR: File openwebui-docker-compose.yaml not found"
  exit 1
fi

if [ ! -f "supabase-docker-compose.yaml" ]; then
  echo "ERROR: File supabase-docker-compose.yaml not found"
  exit 1
fi

if [ ! -f ".env" ]; then
  echo "ERROR: File .env not found"
  exit 1
fi

# Start n8n and Caddy
echo "Starting n8n and Caddy..."
sudo docker compose -f n8n-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start n8n and Caddy"
  exit 1
fi

# Wait a bit for the network to be created
echo "Waiting for docker network creation..."
sleep 5

# Check if app-network was created
if ! sudo docker network inspect app-network &> /dev/null; then
  echo "ERROR: Failed to create app-network"
  exit 1
fi

# Start Flowise
echo "Starting Flowise..."
sudo docker compose -f flowise-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start Flowise"
  exit 1
fi

# Start Ollama
echo "Starting Ollama..."
sudo docker compose -f ollama-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start Ollama"
  exit 1
fi

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
sleep 10

# Start OpenWebUI
echo "Starting OpenWebUI..."
sudo docker compose -f openwebui-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start OpenWebUI"
  exit 1
fi

# Start Supabase
echo "Starting Supabase..."
sudo docker compose -f supabase-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start Supabase"
  exit 1
fi

# Check that all containers are running
echo "Checking running containers..."
sleep 5

if ! sudo docker ps | grep -q "n8n"; then
  echo "ERROR: Container n8n is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "caddy"; then
  echo "ERROR: Container caddy is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "flowise"; then
  echo "ERROR: Container flowise is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "ollama"; then
  echo "ERROR: Container ollama is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "openwebui"; then
  echo "ERROR: Container openwebui is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "supabase-db"; then
  echo "ERROR: Container supabase-db is not running"
  exit 1
fi

if ! sudo docker ps | grep -q "supabase-studio"; then
  echo "ERROR: Container supabase-studio is not running"
  exit 1
fi

echo "✅ All services successfully started"
exit 0 