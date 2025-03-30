#!/bin/bash

# Get variables from the main script via arguments
USER_EMAIL=$1
DOMAIN_NAME=$2
GENERIC_TIMEZONE=$3

if [ -z "$USER_EMAIL" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "ERROR: Email or domain name not specified"
  echo "Usage: $0 user@example.com example.com [timezone]"
  exit 1
fi

if [ -z "$GENERIC_TIMEZONE" ]; then
  GENERIC_TIMEZONE="UTC"
fi

echo "Generating secret keys and passwords..."

# Function to generate random strings
generate_random_string() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()-_=+' | fold -w ${length} | head -n 1
}

# Function to generate safe passwords (no special bash characters)
generate_safe_password() {
  length=$1
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${length} | head -n 1
}

# Generating keys and passwords
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

# Use safer password generation function (alphanumeric only)
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

# Generate OpenWebUI credentials
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

# Generate Supabase credentials
SUPABASE_DB_PASSWORD=$(generate_safe_password 16)
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Supabase DB"
  exit 1
fi

SUPABASE_JWT_SECRET=$(generate_random_string 40)
if [ -z "$SUPABASE_JWT_SECRET" ]; then
  echo "ERROR: Failed to generate JWT secret for Supabase"
  exit 1
fi

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

# Generate Supabase dashboard credentials
DASHBOARD_USERNAME="admin"
DASHBOARD_PASSWORD=$(generate_safe_password 16)
if [ -z "$DASHBOARD_PASSWORD" ]; then
  echo "ERROR: Failed to generate password for Supabase dashboard"
  exit 1
fi

# Generate SMTP credentials (using a default test configuration)
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

# Writing values to .env file
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

echo "Secret keys generated and saved to .env file"
echo "Password for n8n: $N8N_PASSWORD"
echo "Password for Flowise: $FLOWISE_PASSWORD"
echo "Password for OpenWebUI: $OPENWEBUI_PASSWORD"
echo "Password for Supabase DB: $SUPABASE_DB_PASSWORD"
echo "Supabase Dashboard credentials:"
echo "Username: $DASHBOARD_USERNAME"
echo "Password: $DASHBOARD_PASSWORD"
echo "SMTP Password: $SMTP_PASS"

# Save passwords for future use - using quotes to properly handle special characters
echo "N8N_PASSWORD=\"$N8N_PASSWORD\"" > ./setup-files/passwords.txt
echo "FLOWISE_PASSWORD=\"$FLOWISE_PASSWORD\"" >> ./setup-files/passwords.txt
echo "OPENWEBUI_PASSWORD=\"$OPENWEBUI_PASSWORD\"" >> ./setup-files/passwords.txt
echo "SUPABASE_DB_PASSWORD=\"$SUPABASE_DB_PASSWORD\"" >> ./setup-files/passwords.txt
echo "DASHBOARD_PASSWORD=\"$DASHBOARD_PASSWORD\"" >> ./setup-files/passwords.txt
echo "SMTP_PASS=\"$SMTP_PASS\"" >> ./setup-files/passwords.txt

echo "✅ Secret keys and passwords successfully generated"
exit 0 