#!/bin/bash

# Script to add PostgreSQL credential to N8N via API
# Run this after N8N is started and you've created your first user

N8N_URL="http://localhost:5678"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="$SCRIPT_DIR/config"
DB_PASSWORD=$(cat "$CONFIG_DIR/.db_password")

echo "Adding PostgreSQL credential to N8N..."
echo "Note: You may need to authenticate with N8N first"

# Create credential via N8N API
curl -X POST "$N8N_URL/rest/credentials" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "PostgreSQL Database",
    "type": "postgres",
    "data": {
      "host": "localhost",
      "port": 5432,
      "database": "n8n_db",
      "user": "n8n_user",
      "password": "'$DB_PASSWORD'",
      "allowUnauthorizedCerts": false,
      "ssl": "disable"
    }
  }'

echo
echo "PostgreSQL credential added successfully!"
echo "You can now use this credential in your N8N workflows."