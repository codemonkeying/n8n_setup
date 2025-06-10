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
EXISTING_PID=$(lsof -ti:$N8N_PORT 2>/dev/null)
if [[ -n "$EXISTING_PID" ]]; then
    echo "Killing existing process on port $N8N_PORT (PID: $EXISTING_PID)"
    kill -9 $EXISTING_PID
    sleep 2
fi

# Kill any existing n8n processes
pkill -f "n8n start" 2>/dev/null || true
sleep 1

# Activate Python virtual environment (for future extensibility and best practices)
if [[ -d "$N8N_DIR/venv" ]]; then
    echo "Activating Python virtual environment..."
    source "$N8N_DIR/venv/bin/activate"
fi

# Ensure critical environment variables are set
export N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE:-false}
export N8N_PORT=${N8N_PORT:-5678}

# Start N8N
echo "Starting N8N on port $N8N_PORT..."
echo "Secure cookie setting: $N8N_SECURE_COOKIE"
n8n start
