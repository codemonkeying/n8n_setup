#!/bin/bash

# N8N Startup Script
N8N_DIR="/home/user/n8n"
CONFIG_DIR="$N8N_DIR/config"

# Load environment variables
if [[ -f "$CONFIG_DIR/.env" ]]; then
    set -a
    source "$CONFIG_DIR/.env"
    set +a
else
    echo "Error: Configuration file not found at $CONFIG_DIR/.env"
    exit 1
fi

# Activate Python virtual environment
source "$N8N_DIR/venv/bin/activate"

# Start N8N
echo "Starting N8N on port $N8N_PORT..."
n8n start
