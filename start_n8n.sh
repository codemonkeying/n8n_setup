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

# Kill any existing processes on N8N port
echo "Checking for existing processes on port $N8N_PORT..."
EXISTING_PID=$(lsof -ti:$N8N_PORT)
if [[ -n "$EXISTING_PID" ]]; then
    echo "Killing existing process on port $N8N_PORT (PID: $EXISTING_PID)"
    kill -9 $EXISTING_PID
    sleep 2
fi

# Kill any existing n8n processes
pkill -f "n8n start" 2>/dev/null || true
sleep 1

# Start N8N (no need for Python venv since n8n is installed globally)
echo "Starting N8N on port $N8N_PORT..."
n8n start
