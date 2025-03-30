#!/bin/bash

echo "Starting services..."

# Function to cleanup on failure
cleanup() {
  echo "Cleaning up on failure..."
  sudo docker compose -f supabase-docker-compose.yaml down
  sudo docker compose -f n8n-docker-compose.yaml down
  sudo docker compose -f flowise-docker-compose.yaml down
  sudo docker compose -f ollama-docker-compose.yaml down
  sudo docker compose -f openwebui-docker-compose.yaml down
  exit 1
}

# Set up trap for cleanup
trap cleanup EXIT

# Check for required files
for file in "n8n-docker-compose.yaml" "flowise-docker-compose.yaml" "ollama-docker-compose.yaml" "openwebui-docker-compose.yaml" "supabase-docker-compose.yaml" ".env"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: File $file not found"
    exit 1
  fi
done

# Function to wait for service health
wait_for_service() {
  local service=$1
  local port=$2
  local endpoint=$3
  local max_attempts=30
  local attempt=1

  echo "Waiting for $service to be ready..."
  while [ $attempt -le $max_attempts ]; do
    if curl -s "http://localhost:$port$endpoint" > /dev/null; then
      echo "$service is ready"
      return 0
    fi
    echo "Attempt $attempt/$max_attempts: $service is not ready yet..."
    sleep 2
    attempt=$((attempt + 1))
  done
  echo "ERROR: $service failed to become ready after $max_attempts attempts"
  return 1
}

# Create app-network if it doesn't exist
if ! sudo docker network inspect app-network &> /dev/null; then
  echo "Creating app-network..."
  sudo docker network create app-network
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create app-network"
    exit 1
  fi
fi

# Start Supabase first
echo "Starting Supabase..."
sudo docker compose -f supabase-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start Supabase"
  exit 1
fi

# Wait for Supabase to be ready
wait_for_service "Supabase" 3000 "/api/health"
if [ $? -ne 0 ]; then
  echo "ERROR: Supabase failed to start properly"
  exit 1
fi

# Start n8n and Caddy
echo "Starting n8n and Caddy..."
sudo docker compose -f n8n-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start n8n and Caddy"
  exit 1
fi

# Start Flowise
echo "Starting Flowise..."
sudo docker compose -f flowise-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start Flowise"
  exit 1
fi

# Wait for Flowise to be ready
wait_for_service "Flowise" 3001 "/api/health"
if [ $? -ne 0 ]; then
  echo "ERROR: Flowise failed to start properly"
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
wait_for_service "Ollama" 11434 "/api/version"
if [ $? -ne 0 ]; then
  echo "ERROR: Ollama failed to start properly"
  exit 1
fi

# Start OpenWebUI
echo "Starting OpenWebUI..."
sudo docker compose -f openwebui-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to start OpenWebUI"
  exit 1
fi

# Wait for OpenWebUI to be ready
wait_for_service "OpenWebUI" 8080 "/"
if [ $? -ne 0 ]; then
  echo "ERROR: OpenWebUI failed to start properly"
  exit 1
fi

# Check that all containers are running
echo "Checking running containers..."
sleep 5

# List of containers to check
containers=("n8n" "caddy" "flowise" "ollama" "openwebui" "supabase-db" "supabase-studio")

for container in "${containers[@]}"; do
  if ! sudo docker ps | grep -q "$container"; then
    echo "ERROR: Container $container is not running"
    exit 1
  fi
done

# Remove cleanup trap as everything is successful
trap - EXIT

echo "✅ All services successfully started"
exit 0 