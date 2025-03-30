#!/bin/bash

# Secrets Generation Script
# Purpose: Generates secure passwords and keys for all services
# This script creates random credentials and saves them to .env file

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

echo "Generating secret keys and passwords..."

# Random String Generation Functions
# Purpose: Create cryptographically secure random strings for various uses
generate_random_string() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()-_=+' | fold -w ${length} | head -n 1
}

generate_safe_password() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${length} | head -n 1
}

# Generate n8n Credentials
# Purpose: Create encryption key and JWT secret for n8n
N8N_ENCRYPTION_KEY=$(generate_random_string 40)
if [ -z "$N8N_ENCRYPTION_KEY" ]; then
  echo "ERROR: Failed to generate encryption key for n8n"
  exit 1
fi

N8N_USER_MANAGEMENT_JWT_SECRET=$(generate_random_string 40)
if [ -z "$N8N_USER_MANAGEMENT_JWT_SECRET" ]; then
  echo "ERROR: Failed to generate JWT secret for n8n"
  exit 1
fi

# Generate Service Passwords
# Purpose: Create secure passwords for all services
N8N_PASSWORD=$(generate_safe_password 16)
if [ -z "$N8N_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for n8n"
  exit 1
fi

FLOWISE_PASSWORD=$(generate_safe_password 16)
if [ -z "$FLOWISE_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Flowise"
  exit 1
fi

# Generate OpenWebUI Credentials
# Purpose: Create secret key and admin credentials for OpenWebUI
OPENWEBUI_SECRET_KEY=$(generate_random_string 32)
if [ -z "$OPENWEBUI_SECRET_KEY" ]; then
  echo "ERROR: Failed to generate secret key for OpenWebUI"
  exit 1
fi

OPENWEBUI_USERNAME="admin"
OPENWEBUI_PASSWORD=$(generate_safe_password 16)
if [ -z "$OPENWEBUI_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for OpenWebUI"
  exit 1
fi

# Generate Supabase Credentials
# Purpose: Create database password and API keys for Supabase
SUPABASE_DB_PASSWORD=$(generate_safe_password 32)
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Supabase DB"
  exit 1
fi

SUPABASE_JWT_SECRET=$(generate_random_string 40)
if [ -z "$SUPABASE_JWT_SECRET" ]; then
  echo "ERROR: Failed to generate JWT secret for Supabase"
  exit 1
fi

# Generate Supabase API Keys
# Purpose: Create anon and service role keys for Supabase
SUPABASE_ANON_KEY=$(generate_random_string 32)
if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERROR: Failed to generate anon key for Supabase"
  exit 1
fi

SUPABASE_SERVICE_ROLE_KEY=$(generate_random_string 32)
if [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "ERROR: Failed to generate service role key for Supabase"
  exit 1
fi

# Generate Supabase Dashboard Credentials
# Purpose: Create admin credentials for Supabase Studio
DASHBOARD_USERNAME="admin"
DASHBOARD_PASSWORD=$(generate_safe_password 16)
if [ -z "$DASHBOARD_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Supabase dashboard"
  exit 1
fi

# Generate Supabase Pooler Tenant ID
# Purpose: Create a unique tenant ID for the connection pooler
POOLER_TENANT_ID=$(shuf -i 1000-9999 -n 1)
if [ -z "$POOLER_TENANT_ID" ]; then
  echo "ERROR: Failed to generate pooler tenant ID"
  exit 1
fi

# Generate SMTP Credentials
# Purpose: Set up email configuration for Supabase
SMTP_ADMIN_EMAIL="admin@${DOMAIN_NAME}"
SMTP_HOST="smtp.${DOMAIN_NAME}"
SMTP_PORT="587"
SMTP_USER="smtp_user"
SMTP_PASS=$(generate_safe_password 16)
if [ -z "$SMTP_PASS" ]; then
  echo "ERROR: Failed to generate SMTP password"
  exit 1
fi
SMTP_SENDER_NAME="Supabase Admin"

# Create .env File
# Purpose: Save all credentials to environment file
cat > .env << EOL
# Settings for n8n
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET
N8N_DEFAULT_USER_EMAIL=$USER_EMAIL
N8N_DEFAULT_USER_PASSWORD=$N8N_PASSWORD

# n8n host configuration
SUBDOMAIN=n8n
GENERIC_TIMEZONE=$GENERIC_TIMEZONE

# Settings for Flowise
FLOWISE_USERNAME=admin
FLOWISE_PASSWORD=$FLOWISE_PASSWORD

# Settings for OpenWebUI
OPENWEBUI_SECRET_KEY=$OPENWEBUI_SECRET_KEY
OPENWEBUI_USERNAME=$OPENWEBUI_USERNAME
OPENWEBUI_PASSWORD=$OPENWEBUI_PASSWORD

# Settings for Supabase
SUPABASE_DB_PASSWORD=$SUPABASE_DB_PASSWORD
SUPABASE_JWT_SECRET=$SUPABASE_JWT_SECRET
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY
DASHBOARD_USERNAME=$DASHBOARD_USERNAME
DASHBOARD_PASSWORD=$DASHBOARD_PASSWORD
POOLER_TENANT_ID=$POOLER_TENANT_ID

# Supabase SMTP settings
SMTP_ADMIN_EMAIL=$SMTP_ADMIN_EMAIL
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASS=$SMTP_PASS
SMTP_SENDER_NAME=$SMTP_SENDER_NAME

# Site URL for Supabase
SITE_URL=https://supabase.${DOMAIN_NAME}

# Domain settings
DOMAIN_NAME=$DOMAIN_NAME
EOL

if [ $? -ne 0 ]; then
  echo "ERROR: Failed to create .env file"
  exit 1
fi

# Display Generated Credentials
# Purpose: Show important credentials to the user
echo "Secret keys generated and saved to .env file"
echo "Password for n8n: $N8N_PASSWORD"
echo "Password for Flowise: $FLOWISE_PASSWORD"
echo "Password for OpenWebUI: $OPENWEBUI_PASSWORD"
echo "Password for Supabase DB: $SUPABASE_DB_PASSWORD"
echo "Supabase Dashboard credentials:"
echo "Username: $DASHBOARD_USERNAME"
echo "Password: $DASHBOARD_PASSWORD"
echo "SMTP Password: $SMTP_PASS"
echo "Pooler Tenant ID: $POOLER_TENANT_ID"

# Save Passwords to File
# Purpose: Store passwords for future reference
echo "N8N_PASSWORD=\"$N8N_PASSWORD\"" > ./setup-files/passwords.txt
echo "FLOWISE_PASSWORD=\"$FLOWISE_PASSWORD\"" >> ./setup-files/passwords.txt
echo "OPENWEBUI_PASSWORD=\"$OPENWEBUI_PASSWORD\"" >> ./setup-files/passwords.txt
echo "SUPABASE_DB_PASSWORD=\"$SUPABASE_DB_PASSWORD\"" >> ./setup-files/passwords.txt
echo "DASHBOARD_PASSWORD=\"$DASHBOARD_PASSWORD\"" >> ./setup-files/passwords.txt
echo "SMTP_PASS=\"$SMTP_PASS\"" >> ./setup-files/passwords.txt
echo "POOLER_TENANT_ID=\"$POOLER_TENANT_ID\"" >> ./setup-files/passwords.txt

echo "✅ Secret keys and passwords successfully generated"
exit 0 