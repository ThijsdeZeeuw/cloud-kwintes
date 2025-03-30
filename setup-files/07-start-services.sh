#!/bin/bash

# Service Start Script
# Purpose: Orchestrates the startup of all services in the correct order
# This script ensures proper initialization and health checks of all components

echo "Starting services..."

# Health Check Function
# Purpose: Monitor a service's health by checking its endpoint
# Parameters:
#   $1: service name (for logging)
#   $2: health check endpoint URL
# Returns: 0 if healthy, 1 if unhealthy
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

# Container Status Check Function
# Purpose: Verify if a specific container is running
# Parameters:
#   $1: container name
# Returns: 0 if running, 1 if not running
check_container_running() {
  local container=$1
  if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
    return 0
  fi
  return 1
}

# Docker Service Check Function
# Purpose: Verify if Docker daemon is running
# Exits with error if Docker is not available
check_docker_running() {
  if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
  fi
}

# Cleanup Function
# Purpose: Gracefully shut down all services if an error occurs
# This ensures no orphaned containers are left running
cleanup() {
  echo "Cleaning up..."
  docker compose -f supabase-docker-compose.yaml down
  docker compose -f n8n-docker-compose.yaml down
  docker compose -f flowise-docker-compose.yaml down
  docker compose -f ollama-docker-compose.yaml down
  docker compose -f openwebui-docker-compose.yaml down
  exit 1
}

# Set up cleanup trap
# Purpose: Ensure cleanup runs if script exits unexpectedly
trap cleanup EXIT

# Verify Docker is running
check_docker_running

# Required Files Check
# Purpose: Ensure all necessary configuration files exist before starting
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

# Network Setup
# Purpose: Create shared Docker network if it doesn't exist
if ! docker network ls | grep -q "app-network"; then
  echo "Creating Docker network app-network..."
  docker network create app-network
  if [ $? -ne 0 ]; then
    echo "❌ Failed to create Docker network"
    exit 1
  fi
fi

# Service Startup Sequence
# Purpose: Start services in dependency order with health checks

# 1. Start Supabase (Database and API)
echo "Starting Supabase..."
docker compose -f supabase-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start Supabase"
  exit 1
fi
check_service_health "Supabase" "http://localhost:5432/health"

# 2. Start n8n (Workflow Automation)
echo "Starting n8n..."
docker compose -f n8n-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start n8n"
  exit 1
fi
check_service_health "n8n" "http://localhost:5678/healthz"

# 3. Start Flowise (AI Workflow Builder)
echo "Starting Flowise..."
docker compose -f flowise-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start Flowise"
  exit 1
fi
check_service_health "Flowise" "http://localhost:3000/health"

# 4. Start Ollama (LLM Server)
echo "Starting Ollama..."
docker compose -f ollama-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start Ollama"
  exit 1
fi
check_service_health "Ollama" "http://localhost:11434/api/version"

# 5. Start OpenWebUI (Ollama Interface)
echo "Starting OpenWebUI..."
docker compose -f openwebui-docker-compose.yaml up -d
if [ $? -ne 0 ]; then
  echo "❌ Failed to start OpenWebUI"
  exit 1
fi
check_service_health "OpenWebUI" "http://localhost:8080/api/health"

# Final Status Check
# Purpose: Verify all containers are running after startup
containers=("n8n" "flowise" "ollama" "openwebui" "supabase-studio" "supabase-db")
for container in "${containers[@]}"; do
  if ! check_container_running "$container"; then
    echo "❌ Container $container is not running"
    exit 1
  fi
done

echo "✅ All services started successfully"
exit 0 