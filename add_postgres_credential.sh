#!/bin/bash

# Script to add PostgreSQL credential to N8N via API with authentication
# Run this after N8N is started and you've created your first user

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="$SCRIPT_DIR/config"
DB_PASSWORD=$(cat "$CONFIG_DIR/.db_password")
N8N_URL="http://localhost:5678"

echo "Adding PostgreSQL credential to N8N..."

# Wait for n8n to be ready
max_attempts=10
attempt=1

while [[ $attempt -le $max_attempts ]]; do
    if curl -s "$N8N_URL/healthz" >/dev/null 2>&1; then
        echo "N8N is ready"
        break
    fi
    echo "Waiting for N8N to be ready... (attempt $attempt/$max_attempts)"
    sleep 3
    ((attempt++))
done

if [[ $attempt -gt $max_attempts ]]; then
    echo "Error: N8N is not responding. Make sure N8N is running."
    exit 1
fi

# Function to login and get session cookie
login_to_n8n() {
    echo "Please provide your N8N login credentials:"
    read -p "Email: " email
    read -s -p "Password: " password
    echo

    # Login and save cookies
    login_response=$(curl -s -c /tmp/n8n_cookies.txt -X POST "$N8N_URL/rest/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"$password\"}")
    
    if echo "$login_response" | grep -q '"id"'; then
        echo "Login successful!"
        return 0
    else
        echo "Login failed. Please check your credentials."
        return 1
    fi
}

# Try to access credentials endpoint to check if we're authenticated
auth_check=$(curl -s -b /tmp/n8n_cookies.txt "$N8N_URL/rest/credentials" 2>/dev/null)

if echo "$auth_check" | grep -q "Unauthorized" || [[ -z "$auth_check" ]]; then
    echo "Authentication required..."
    if ! login_to_n8n; then
        exit 1
    fi
fi

# Check if PostgreSQL credential already exists
existing_creds=$(curl -s -b /tmp/n8n_cookies.txt "$N8N_URL/rest/credentials" | grep -c "PostgreSQL Database" || echo "0")

if [[ "$existing_creds" -gt 0 ]]; then
    echo "PostgreSQL credential already exists in N8N"
    rm -f /tmp/n8n_cookies.txt
    exit 0
fi

# Create the PostgreSQL credential
echo "Creating PostgreSQL credential..."
credential_response=$(curl -s -b /tmp/n8n_cookies.txt -X POST "$N8N_URL/rest/credentials" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"PostgreSQL Database\",
        \"type\": \"postgres\",
        \"data\": {
            \"host\": \"localhost\",
            \"port\": 5432,
            \"database\": \"n8n_db\",
            \"user\": \"n8n_user\",
            \"password\": \"$DB_PASSWORD\",
            \"allowUnauthorizedCerts\": false,
            \"ssl\": \"disable\"
        }
    }")

# Clean up cookies
rm -f /tmp/n8n_cookies.txt

if echo "$credential_response" | grep -q '"id"'; then
    echo "✓ PostgreSQL credential added successfully!"
    echo "You can now use 'PostgreSQL Database' credential in your N8N workflows."
else
    echo "Error creating credential:"
    echo "$credential_response"
    exit 1
fi