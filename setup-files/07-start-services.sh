#!/bin/bash

echo "Starting services..."

# Function to check service health
check_service_health() {
  local service=$1
  local endpoint=$2
  local max_attempts=30
  local attempt=1
  local wait=5

  echo "Waiting for $service to be healthy..."
  while [ $attempt -le $max_attempts ]; do
    if curl -s -f "$endpoint" > /dev/null; then
      echo "✅ $service is healthy"
      return 0
    fi
    echo "Attempt $attempt/$max_attempts: $service is not ready yet..."
    sleep $wait
    attempt=$((attempt + 1))
  done
  echo "❌ $service failed to become healthy"
  return 1
}

# Function to check if a container is running
check_container_running() {
  local container=$1
  if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
    return 0
  fi
  return 1
}

# Function to check if Docker is running
check_docker_running() {
  if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
  fi
}

# Function to clean up on failure
cleanup() {
  echo "Cleaning up..."
  docker compose -f supabase-docker-compose.yaml down
  docker compose -f n8n-docker-compose.yaml down
  docker compose -f flowise-docker-compose.yaml down
  docker compose -f ollama-docker-compose.yaml down
  docker compose -f openwebui-docker-compose.yaml down
  exit 1
}

# Set up trap for cleanup
trap cleanup EXIT

# Check if Docker is running
check_docker_running

# Check for required files
required_files=(
  "n8n-docker-compose.yaml"
  "flowise-docker-compose.yaml"
  "ollama-docker-compose.yaml"
  "openwebui-docker-compose.yaml"
  "supabase-docker-compose.yaml"
  ".env"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "❌ Required file $file not found"
    exit 1
  fi
done

# Create Docker network if it doesn't exist
if ! docker network ls | grep -q "app-network"; then
  echo "Creating Docker network app-network..."
  docker network create app-network
  if [ $? -ne 0 ]; then
    echo "❌ Failed to create Docker network"
    exit 1
  fi
fi

# Start services in order
echo "Starting Supabase..."
docker compose -f supabase-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start Supabase"
  exit 1
fi

# Wait for Supabase to be healthy
check_service_health "Supabase" "http://localhost:5432/health"

echo "Starting n8n..."
docker compose -f n8n-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start n8n"
  exit 1
fi

# Wait for n8n to be healthy
check_service_health "n8n" "http://localhost:5678/healthz"

echo "Starting Flowise..."
docker compose -f flowise-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start Flowise"
  exit 1
fi

# Wait for Flowise to be healthy
check_service_health "Flowise" "http://localhost:3000/health"

echo "Starting Ollama..."
docker compose -f ollama-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start Ollama"
  exit 1
fi

# Wait for Ollama to be healthy
check_service_health "Ollama" "http://localhost:11434/api/version"

echo "Starting OpenWebUI..."
docker compose -f openwebui-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start OpenWebUI"
  exit 1
fi

# Wait for OpenWebUI to be healthy
check_service_health "OpenWebUI" "http://localhost:8080/api/health"

# Final check to ensure all containers are running
containers=("n8n" "flowise" "ollama" "openwebui" "supabase-studio" "supabase-db")
for container in "${containers[@]}"; do
  if ! check_container_running "$container"; then
    echo "❌ Container $container is not running"
    exit 1
  fi
done

echo "✅ All services started successfully"
exit 0 