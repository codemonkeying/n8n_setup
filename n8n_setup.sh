#!/bin/bash

# N8N Production Setup Script
# Based on n8n_setup_plan.md and n8n_implementation_plan.md
# Author: Automated Setup System
# Version: 1.0

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
N8N_DIR="/home/user/n8n"
CONFIG_DIR="$N8N_DIR/config"
WORKFLOWS_DIR="$N8N_DIR/workflows"
LOGS_DIR="$N8N_DIR/logs"
BACKUPS_DIR="$N8N_DIR/backups"
VENV_DIR="$N8N_DIR/venv"
LOG_FILE="$LOGS_DIR/setup.log"

# Database configuration
DB_NAME="n8n_db"
DB_USER="n8n_user"
DB_HOST="localhost"
DB_PORT="5432"

# N8N configuration
N8N_PORT="5678"
N8N_HOST="0.0.0.0"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_message="[$timestamp] [$level] $message"
    echo "$log_message"
    
    # Only write to log file if logs directory exists
    if [[ -d "$LOGS_DIR" ]]; then
        echo "$log_message" >> "$LOG_FILE"
    fi
}

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "INFO" "$message"
}

# Error handling
error_exit() {
    print_status "$RED" "ERROR: $1"
    log "ERROR" "$1"
    exit 1
}

# Success message
success() {
    print_status "$GREEN" "✓ $1"
}

# Warning message
warning() {
    print_status "$YELLOW" "⚠ $1"
}

# Info message
info() {
    print_status "$BLUE" "ℹ $1"
}

# Generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Generate encryption key
generate_encryption_key() {
    openssl rand -hex 16
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_system_requirements() {
    info "Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root for security reasons"
    fi
    
    # Check required commands
    local required_commands=("curl" "wget" "openssl" "sudo")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            error_exit "Required command '$cmd' not found. Please install it first."
        fi
    done
    
    success "System requirements check passed"
}

# Create directory structure
create_directories() {
    info "Creating directory structure..."
    
    local directories=("$CONFIG_DIR" "$WORKFLOWS_DIR" "$LOGS_DIR" "$BACKUPS_DIR")
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            success "Created directory: $dir"
        else
            info "Directory already exists: $dir"
        fi
    done
    
    # Set permissions
    chmod 700 "$CONFIG_DIR"
    chmod 755 "$WORKFLOWS_DIR" "$LOGS_DIR" "$BACKUPS_DIR"
    
    success "Directory structure created successfully"
}

# Setup Python virtual environment
setup_python_venv() {
    info "Setting up Python virtual environment..."
    
    if ! command_exists "python3"; then
        error_exit "Python3 is required but not installed"
    fi
    
    if [[ ! -d "$VENV_DIR" ]]; then
        python3 -m venv "$VENV_DIR"
        success "Python virtual environment created"
    else
        info "Python virtual environment already exists"
    fi
    
    # Activate and upgrade pip
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    success "Python virtual environment setup completed"
}

# Check and install Node.js
check_install_nodejs() {
    info "Checking Node.js installation..."
    
    if command_exists "node"; then
        local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ $node_version -ge 18 ]]; then
            success "Node.js version $(node --version) is compatible"
            return 0
        else
            warning "Node.js version $(node --version) is too old. Need v18+"
        fi
    fi
    
    info "Installing Node.js v18..."
    
    # Install Node.js using NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    if command_exists "node" && command_exists "npm"; then
        success "Node.js $(node --version) and npm $(npm --version) installed successfully"
    else
        error_exit "Failed to install Node.js"
    fi
}

# Check and install PostgreSQL
check_install_postgresql() {
    info "Checking PostgreSQL installation..."
    
    if command_exists "psql" && sudo systemctl is-active --quiet postgresql; then
        success "PostgreSQL is already installed and running"
        return 0
    fi
    
    info "Installing PostgreSQL..."
    
    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    success "PostgreSQL installed and started"
}

# Setup PostgreSQL database and user
setup_database() {
    info "Setting up PostgreSQL database and user..."
    
    # Generate secure password
    local db_password=$(generate_password)
    
    # Create database and user
    sudo -u postgres psql << EOF
CREATE DATABASE $DB_NAME;
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$db_password';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
ALTER USER $DB_USER CREATEDB;
\q
EOF

    # Grant CREATE privileges on public schema (required for N8N chat memory and other features)
    sudo -u postgres psql -d "$DB_NAME" << EOF
GRANT CREATE ON SCHEMA public TO $DB_USER;
\q
EOF
    
    # Store password for later use
    echo "$db_password" > "$CONFIG_DIR/.db_password"
    chmod 600 "$CONFIG_DIR/.db_password"
    
    success "Database '$DB_NAME' and user '$DB_USER' created successfully"
    success "Granted CREATE privileges on public schema for N8N features"
    info "Database password stored in $CONFIG_DIR/.db_password"
}

# Install N8N
install_n8n() {
    info "Installing N8N..."
    
    # Install n8n globally
    sudo npm install -g n8n
    
    if command_exists "n8n"; then
        success "N8N installed successfully"
        info "N8N version: $(n8n --version)"
    else
        error_exit "Failed to install N8N"
    fi
}

# Generate configuration files
generate_config() {
    info "Generating configuration files..."
    
    local db_password=$(cat "$CONFIG_DIR/.db_password")
    local encryption_key=$(generate_encryption_key)
    
    # Create .env file
    cat > "$CONFIG_DIR/.env" << EOF
# Database Configuration
DB_TYPE=postgresdb
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_DATABASE=$DB_NAME
DB_USERNAME=$DB_USER
DB_PASSWORD=$db_password

# N8N Configuration
N8N_PORT=$N8N_PORT
N8N_HOST=$N8N_HOST
WEBHOOK_URL=http://localhost:$N8N_PORT
N8N_USER_FOLDER=$N8N_DIR
WORKFLOWS_FOLDER=$WORKFLOWS_DIR

# Security
N8N_ENCRYPTION_KEY=$encryption_key
N8N_USER_MANAGEMENT_DISABLED=false

# Logging
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_LOCATION=$LOGS_DIR/
EOF
    
    # Set secure permissions
    chmod 600 "$CONFIG_DIR/.env"
    
    success "Configuration files generated"
    info "Environment file created: $CONFIG_DIR/.env"
}

# Test N8N installation
test_n8n() {
    info "Testing N8N installation..."
    
    # Source environment variables
    set -a
    source "$CONFIG_DIR/.env"
    set +a
    
    # Test database connection
    info "Testing database connection..."
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        success "Database connection test passed"
    else
        error_exit "Database connection test failed"
    fi
    
    # Test N8N startup (quick test)
    info "Testing N8N startup..."
    timeout 10s n8n start --tunnel >/dev/null 2>&1 || true
    
    success "N8N installation test completed"
}

# Set file permissions
set_permissions() {
    info "Setting file permissions..."
    
    # Set ownership
    chown -R $(whoami):$(whoami) "$N8N_DIR"
    
    # Set directory permissions
    chmod 700 "$CONFIG_DIR"
    chmod 755 "$WORKFLOWS_DIR" "$LOGS_DIR" "$BACKUPS_DIR"
    chmod 755 "$VENV_DIR"
    
    # Set file permissions
    chmod 600 "$CONFIG_DIR/.env"
    chmod 600 "$CONFIG_DIR/.db_password"
    
    success "File permissions set correctly"
}

# Create startup script
create_startup_script() {
    info "Creating startup script..."
    
    cat > "$N8N_DIR/start_n8n.sh" << 'EOF'
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
EOF
    
    chmod +x "$N8N_DIR/start_n8n.sh"
    success "Startup script created: $N8N_DIR/start_n8n.sh"
}

# Main installation function
main() {
    print_status "$BLUE" "=== N8N Production Setup ==="
    print_status "$BLUE" "Starting installation process..."
    
    # Create log file
    mkdir -p "$LOGS_DIR"
    touch "$LOG_FILE"
    
    log "INFO" "N8N setup started"
    
    # Run installation steps
    check_system_requirements
    create_directories
    setup_python_venv
    check_install_nodejs
    check_install_postgresql
    setup_database
    install_n8n
    generate_config
    set_permissions
    create_startup_script
    test_n8n
    
    print_status "$GREEN" "=== Installation Complete ==="
    echo
    success "N8N has been successfully installed and configured!"
    echo
    info "Next steps:"
    echo "  1. To start N8N manually: $N8N_DIR/start_n8n.sh"
    echo "  2. To install as a system service: ./install_service.sh"
    echo "  3. Access N8N at: http://localhost:$N8N_PORT"
    echo
    info "Configuration files:"
    echo "  - Environment: $CONFIG_DIR/.env"
    echo "  - Logs: $LOGS_DIR/"
    echo "  - Workflows: $WORKFLOWS_DIR/"
    echo "  - Backups: $BACKUPS_DIR/"
    echo
    warning "Important: Keep your database password secure!"
    warning "Database password is stored in: $CONFIG_DIR/.db_password"
    
    log "INFO" "N8N setup completed successfully"
}

# Run main function
main "$@"