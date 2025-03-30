# Cloud-Local n8n & Flowise Setup

Automated installation script for n8n, Flowise, Ollama, OpenWebUI, and Supabase with reverse proxy server Caddy for secure access via HTTPS.

## Description

This repository contains scripts for automatic configuration of:

- **n8n** - a powerful open-source workflow automation platform
- **Flowise** - a tool for creating customizable AI flows
- **Ollama** - a local LLM server for running various AI models
- **OpenWebUI** - a web interface for Ollama
- **Supabase** - an open source Firebase alternative
- **Caddy** - a modern web server with automatic HTTPS

The system is configured to work with your domain name and automatically obtains Let's Encrypt SSL certificates.

## Requirements

- Ubuntu 22.04 
- Domain name pointing to your server's IP address
- Server access with administrator rights (sudo)
- Open ports 80, 443, 11434 (Ollama), 5432 (Supabase DB)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ThijsdeZeeuw/cloud-kwintes.git && cd cloud-kwintes
   chmod +x setup.sh
   ./setup.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the installation script:
   ```bash
   ./setup.sh
   ```

4. Follow the instructions in the terminal:
   - Enter your domain name (e.g., example.com)
   - Enter your email (will be used for n8n login and Let's Encrypt)

## Refreshing Files

To update your local files with the latest version from the repository while preserving your local configurations:

1. Make the refresh script executable:
   ```bash
   chmod +x refresh.sh
   ```

2. Run the refresh script:
   ```bash
   ./refresh.sh
   ```

The script will:
- Create a backup of your important configuration files
- Check for any local changes
- Fetch and apply the latest changes from the repository
- Restore your backed-up configuration files
- Set proper execution permissions

If you have local changes, the script will ask for confirmation before proceeding. You can always restore from the backup directory if needed.

## What the installation script does

1. **System update** - updates the package list and installs necessary dependencies
2. **Docker installation** - installs Docker Engine and Docker Compose
3. **Directory setup** - creates n8n user and necessary directories
4. **Secret generation** - creates random passwords and encryption keys
5. **Configuration file creation** - generates docker-compose files and Caddyfile
6. **Firewall setup** - opens necessary ports
7. **Service launch** - starts Docker containers

## Accessing services

After installation completes, you will be able to access services at the following URLs:

- **n8n**: https://n8n.your-domain.xxx
- **Flowise**: https://flowise.your-domain.xxx
- **Ollama**: https://ollama.your-domain.xxx
- **OpenWebUI**: https://openwebui.your-domain.xxx
- **Supabase**: https://supabase.your-domain.xxx

Login credentials will be displayed at the end of the installation process.

## Project structure

- `setup.sh` - main installation script
- `setup-files/` - directory with helper scripts:
  - `01-update-system.sh` - system update
  - `02-install-docker.sh` - Docker installation
  - `03-setup-directories.sh` - directory and user setup
  - `04-generate-secrets.sh` - secret key generation
  - `05-create-templates.sh` - configuration file creation
  - `06-setup-firewall.sh` - firewall setup
  - `07-start-services.sh` - service launch
- `n8n-docker-compose.yaml.template` - docker-compose template for n8n and Caddy
- `flowise-docker-compose.yaml.template` - docker-compose template for Flowise
- `ollama-docker-compose.yaml.template` - docker-compose template for Ollama
- `openwebui-docker-compose.yaml.template` - docker-compose template for OpenWebUI
- `supabase-docker-compose.yaml.template` - docker-compose template for Supabase

## Managing services

### Restarting services

```bash
docker compose -f n8n-docker-compose.yaml restart
docker compose -f flowise-docker-compose.yaml restart
docker compose -f ollama-docker-compose.yaml restart
docker compose -f openwebui-docker-compose.yaml restart
docker compose -f supabase-docker-compose.yaml restart
```

### Stopping services

```bash
docker compose -f n8n-docker-compose.yaml down
docker compose -f flowise-docker-compose.yaml down
docker compose -f ollama-docker-compose.yaml down
docker compose -f openwebui-docker-compose.yaml down
docker compose -f supabase-docker-compose.yaml down
```

### Viewing logs

```bash
docker compose -f n8n-docker-compose.yaml logs
docker compose -f flowise-docker-compose.yaml logs
docker compose -f ollama-docker-compose.yaml logs
docker compose -f openwebui-docker-compose.yaml logs
docker compose -f supabase-docker-compose.yaml logs
```

## Uninstallation

To completely remove all services and start fresh, follow these steps:

1. Stop and remove all containers:
```bash
docker compose -f n8n-docker-compose.yaml down
docker compose -f flowise-docker-compose.yaml down
docker compose -f ollama-docker-compose.yaml down
docker compose -f openwebui-docker-compose.yaml down
docker compose -f supabase-docker-compose.yaml down
```

2. Remove all Docker volumes:
```bash
docker volume rm n8n_data caddy_data caddy_config ollama_data openwebui_data openwebui_config supabase_data
```

3. Remove all configuration files:
```bash
rm -f n8n-docker-compose.yaml flowise-docker-compose.yaml ollama-docker-compose.yaml openwebui-docker-compose.yaml supabase-docker-compose.yaml .env Caddyfile
rm -f setup-files/passwords.txt
```

4. Remove service directories:
```