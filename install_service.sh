#!/bin/bash

# N8N Systemd Service Installer
# Companion script to n8n_setup.sh
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
LOGS_DIR="$N8N_DIR/logs"
SERVICE_NAME="n8n"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SERVICE_USER="n8n"

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Error handling
error_exit() {
    print_status "$RED" "ERROR: $1"
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

# Check if running with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run with sudo privileges"
    fi
}

# Check if N8N setup was completed
check_n8n_setup() {
    info "Checking N8N installation..."
    
    if [[ ! -f "$CONFIG_DIR/.env" ]]; then
        error_exit "N8N configuration not found. Please run n8n_setup.sh first."
    fi
    
    if ! command -v n8n >/dev/null 2>&1; then
        error_exit "N8N is not installed. Please run n8n_setup.sh first."
    fi
    
    success "N8N installation verified"
}

# Create system user for N8N service
create_service_user() {
    info "Creating system user for N8N service..."
    
    if id "$SERVICE_USER" &>/dev/null; then
        info "User '$SERVICE_USER' already exists"
    else
        # Create system user without home directory
        useradd --system --no-create-home --shell /bin/false "$SERVICE_USER"
        success "Created system user: $SERVICE_USER"
    fi
    
    # Add service user to necessary groups
    usermod -a -G postgres "$SERVICE_USER" 2>/dev/null || true
    
    # Set ownership of N8N directory
    chown -R "$SERVICE_USER:$SERVICE_USER" "$N8N_DIR"
    success "Set ownership of N8N directory to $SERVICE_USER"
}

# Create systemd service file
create_service_file() {
    info "Creating systemd service file..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=n8n Workflow Automation Platform
Documentation=https://docs.n8n.io
After=network.target postgresql.service
Wants=postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$N8N_DIR
EnvironmentFile=$CONFIG_DIR/.env
ExecStartPre=/bin/bash -c 'source $N8N_DIR/venv/bin/activate'
ExecStart=/usr/local/bin/n8n start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=n8n

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$N8N_DIR
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    success "Systemd service file created: $SERVICE_FILE"
}

# Create log rotation configuration
create_logrotate_config() {
    info "Creating log rotation configuration..."
    
    cat > "/etc/logrotate.d/n8n" << EOF
$LOGS_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_USER
    postrotate
        systemctl reload-or-restart n8n >/dev/null 2>&1 || true
    endscript
}
EOF
    
    success "Log rotation configuration created"
}

# Install and enable service
install_service() {
    info "Installing and enabling N8N service..."
    
    # Reload systemd daemon
    systemctl daemon-reload
    
    # Enable service to start on boot
    systemctl enable "$SERVICE_NAME"
    
    success "N8N service enabled for automatic startup"
}

# Test service functionality
test_service() {
    info "Testing N8N service..."
    
    # Start the service
    info "Starting N8N service..."
    systemctl start "$SERVICE_NAME"
    
    # Wait a moment for service to start
    sleep 5
    
    # Check service status
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        success "N8N service is running"
    else
        warning "N8N service may not be running properly"
        info "Service status:"
        systemctl status "$SERVICE_NAME" --no-pager -l
    fi
    
    # Check if N8N is responding
    local n8n_port=$(grep "N8N_PORT=" "$CONFIG_DIR/.env" | cut -d'=' -f2)
    if curl -s "http://localhost:${n8n_port}" >/dev/null 2>&1; then
        success "N8N web interface is accessible"
    else
        warning "N8N web interface may not be accessible yet (this is normal during first startup)"
    fi
}

# Create service management script
create_management_script() {
    info "Creating service management script..."
    
    cat > "$N8N_DIR/manage_service.sh" << 'EOF'
#!/bin/bash

# N8N Service Management Script
SERVICE_NAME="n8n"

case "$1" in
    start)
        echo "Starting N8N service..."
        sudo systemctl start "$SERVICE_NAME"
        ;;
    stop)
        echo "Stopping N8N service..."
        sudo systemctl stop "$SERVICE_NAME"
        ;;
    restart)
        echo "Restarting N8N service..."
        sudo systemctl restart "$SERVICE_NAME"
        ;;
    status)
        echo "N8N service status:"
        sudo systemctl status "$SERVICE_NAME" --no-pager -l
        ;;
    logs)
        echo "N8N service logs (last 50 lines):"
        sudo journalctl -u "$SERVICE_NAME" -n 50 --no-pager
        ;;
    follow-logs)
        echo "Following N8N service logs (Ctrl+C to exit):"
        sudo journalctl -u "$SERVICE_NAME" -f
        ;;
    enable)
        echo "Enabling N8N service for automatic startup..."
        sudo systemctl enable "$SERVICE_NAME"
        ;;
    disable)
        echo "Disabling N8N service automatic startup..."
        sudo systemctl disable "$SERVICE_NAME"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|follow-logs|enable|disable}"
        echo
        echo "Commands:"
        echo "  start        - Start the N8N service"
        echo "  stop         - Stop the N8N service"
        echo "  restart      - Restart the N8N service"
        echo "  status       - Show service status"
        echo "  logs         - Show recent service logs"
        echo "  follow-logs  - Follow service logs in real-time"
        echo "  enable       - Enable automatic startup"
        echo "  disable      - Disable automatic startup"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$N8N_DIR/manage_service.sh"
    success "Service management script created: $N8N_DIR/manage_service.sh"
}

# Create backup script
create_backup_script() {
    info "Creating backup script..."
    
    cat > "$N8N_DIR/backup_n8n.sh" << 'EOF'
#!/bin/bash

# N8N Backup Script
N8N_DIR="/home/user/n8n"
CONFIG_DIR="$N8N_DIR/config"
BACKUPS_DIR="$N8N_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Load database configuration
source "$CONFIG_DIR/.env"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUPS_DIR"

# Backup database
echo "Creating database backup..."
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" -d "$DB_DATABASE" > "$BACKUPS_DIR/n8n_db_backup_$TIMESTAMP.sql"

# Backup workflows directory
echo "Creating workflows backup..."
tar -czf "$BACKUPS_DIR/workflows_backup_$TIMESTAMP.tar.gz" -C "$N8N_DIR" workflows/

# Backup configuration (excluding sensitive files)
echo "Creating configuration backup..."
tar -czf "$BACKUPS_DIR/config_backup_$TIMESTAMP.tar.gz" -C "$N8N_DIR" --exclude="config/.db_password" --exclude="config/.env" config/

# Clean up old backups (keep last 7 days)
find "$BACKUPS_DIR" -name "*backup_*.sql" -mtime +7 -delete
find "$BACKUPS_DIR" -name "*backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed successfully!"
echo "Database backup: $BACKUPS_DIR/n8n_db_backup_$TIMESTAMP.sql"
echo "Workflows backup: $BACKUPS_DIR/workflows_backup_$TIMESTAMP.tar.gz"
echo "Config backup: $BACKUPS_DIR/config_backup_$TIMESTAMP.tar.gz"
EOF
    
    chmod +x "$N8N_DIR/backup_n8n.sh"
    success "Backup script created: $N8N_DIR/backup_n8n.sh"
}

# Main installation function
main() {
    print_status "$BLUE" "=== N8N Systemd Service Installer ==="
    
    check_sudo
    check_n8n_setup
    create_service_user
    create_service_file
    create_logrotate_config
    install_service
    create_management_script
    create_backup_script
    test_service
    
    print_status "$GREEN" "=== Service Installation Complete ==="
    echo
    success "N8N systemd service has been installed successfully!"
    echo
    info "Service Management:"
    echo "  - Start service:    sudo systemctl start n8n"
    echo "  - Stop service:     sudo systemctl stop n8n"
    echo "  - Restart service:  sudo systemctl restart n8n"
    echo "  - Service status:   sudo systemctl status n8n"
    echo "  - View logs:        sudo journalctl -u n8n -f"
    echo
    info "Management Scripts:"
    echo "  - Service control:  $N8N_DIR/manage_service.sh"
    echo "  - Create backup:    $N8N_DIR/backup_n8n.sh"
    echo
    info "Service Details:"
    echo "  - Service name:     n8n"
    echo "  - Service user:     $SERVICE_USER"
    echo "  - Service file:     $SERVICE_FILE"
    echo "  - Auto-start:       Enabled"
    echo
    local n8n_port=$(grep "N8N_PORT=" "$CONFIG_DIR/.env" | cut -d'=' -f2)
    success "N8N is now accessible at: http://localhost:${n8n_port}"
    
    warning "Note: It may take a few moments for N8N to fully start up on first run."
}

# Run main function
main "$@"