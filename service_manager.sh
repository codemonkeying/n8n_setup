#!/bin/bash

# N8N Service Manager
# Complete service setup and management script with secure/insecure mode options
# Version: 2.0

# Don't exit on error for management commands
# set -e will be enabled only for setup operations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Header message
header() {
    print_status "$CYAN" "$1"
}

# Check if running with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        info "This operation requires sudo privileges. Re-running with sudo..."
        exec sudo "$0" "$@"
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

# Create systemd service file for secure mode
create_secure_service_file() {
    info "Creating systemd service file for SECURE mode..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=n8n Workflow Automation Platform (Secure Mode)
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
Environment=N8N_SECURE_COOKIE=true
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
    
    success "Secure mode systemd service file created: $SERVICE_FILE"
}

# Create systemd service file for insecure mode
create_insecure_service_file() {
    info "Creating systemd service file for INSECURE mode..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=n8n Workflow Automation Platform (Insecure Mode)
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
Environment=N8N_SECURE_COOKIE=false
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
    
    success "Insecure mode systemd service file created: $SERVICE_FILE"
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

# Remove all N8N services
remove_services() {
    header "=== Removing N8N Services ==="
    
    info "Stopping N8N service if running..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    
    info "Disabling N8N service..."
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    
    info "Removing service file..."
    if [[ -f "$SERVICE_FILE" ]]; then
        rm -f "$SERVICE_FILE"
        success "Service file removed: $SERVICE_FILE"
    else
        info "Service file not found"
    fi
    
    info "Removing logrotate configuration..."
    if [[ -f "/etc/logrotate.d/n8n" ]]; then
        rm -f "/etc/logrotate.d/n8n"
        success "Logrotate configuration removed"
    else
        info "Logrotate configuration not found"
    fi
    
    info "Reloading systemd daemon..."
    systemctl daemon-reload
    
    info "Removing service user..."
    if id "$SERVICE_USER" &>/dev/null; then
        # Change ownership back to original user before removing service user
        chown -R user:user "$N8N_DIR" 2>/dev/null || true
        userdel "$SERVICE_USER" 2>/dev/null || true
        success "Service user removed: $SERVICE_USER"
    else
        info "Service user not found"
    fi
    
    success "All N8N services have been removed successfully!"
    info "N8N installation files remain in: $N8N_DIR"
    info "You can still run N8N manually using the start scripts"
}

# Setup secure mode service
setup_secure_mode() {
    header "=== Setting up N8N Service (SECURE MODE) ==="
    
    check_n8n_setup
    create_service_user
    create_secure_service_file
    create_logrotate_config
    install_service
    test_service
    
    print_status "$GREEN" "=== Secure Mode Service Installation Complete ==="
    echo
    success "N8N systemd service (SECURE MODE) has been installed successfully!"
    echo
    info "Security Features:"
    echo "  - Secure cookies enabled (N8N_SECURE_COOKIE=true)"
    echo "  - Enhanced systemd security settings"
    echo "  - Restricted file system access"
    echo "  - Process isolation"
    echo
    display_service_info
}

# Setup insecure mode service
setup_insecure_mode() {
    header "=== Setting up N8N Service (INSECURE MODE) ==="
    
    warning "INSECURE MODE WARNING:"
    warning "This mode disables secure cookies and may be less secure."
    warning "Only use this mode for development or testing purposes."
    echo
    
    check_n8n_setup
    create_service_user
    create_insecure_service_file
    create_logrotate_config
    install_service
    test_service
    
    print_status "$GREEN" "=== Insecure Mode Service Installation Complete ==="
    echo
    success "N8N systemd service (INSECURE MODE) has been installed successfully!"
    echo
    warning "Security Notice:"
    echo "  - Secure cookies disabled (N8N_SECURE_COOKIE=false)"
    echo "  - This mode is intended for development/testing only"
    echo "  - Consider using secure mode for production environments"
    echo
    display_service_info
}

# Display service information
display_service_info() {
    info "Service Management:"
    echo "  - Start service:    sudo systemctl start n8n"
    echo "  - Stop service:     sudo systemctl stop n8n"
    echo "  - Restart service:  sudo systemctl restart n8n"
    echo "  - Service status:   sudo systemctl status n8n"
    echo "  - View logs:        sudo journalctl -u n8n -f"
    echo
    info "Management Scripts:"
    echo "  - Service control:  $N8N_DIR/service_manager.sh"
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

# Display menu
show_menu() {
    header "=== N8N Service Manager ==="
    echo
    print_status "$CYAN" "Please select an option:"
    echo
    echo "1) Setup service for SECURE mode"
    echo "   - Enables secure cookies (N8N_SECURE_COOKIE=true)"
    echo "   - Recommended for production environments"
    echo "   - Enhanced security settings"
    echo
    echo "2) Setup service for INSECURE mode"
    echo "   - Disables secure cookies (N8N_SECURE_COOKIE=false)"
    echo "   - For development/testing purposes only"
    echo "   - Less secure but may be needed for certain setups"
    echo
    echo "3) Remove all N8N services"
    echo "   - Stops and removes systemd service"
    echo "   - Removes service user and configurations"
    echo "   - Keeps N8N installation files intact"
    echo
    echo "4) Exit"
    echo
}

# Check service mode
check_service_mode() {
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
        local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
        if [[ -f "$service_file" ]]; then
            if grep -q "N8N_SECURE_COOKIE=true" "$service_file"; then
                echo "SECURE"
            elif grep -q "N8N_SECURE_COOKIE=false" "$service_file"; then
                echo "INSECURE"
            else
                echo "UNKNOWN"
            fi
        else
            echo "NO_SERVICE"
        fi
    else
        echo "INACTIVE"
    fi
}

# Display service status with mode information
show_detailed_status() {
    info "=== N8N Service Status ==="
    
    if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
        local mode=$(check_service_mode)
        local status=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo "inactive")
        local enabled=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || echo "disabled")
        
        echo "Service Status: $status"
        echo "Auto-start: $enabled"
        echo "Service Mode: $mode"
        
        if [[ "$status" == "active" ]]; then
            success "N8N service is running"
            
            # Check web interface
            local n8n_port=$(grep "N8N_PORT=" "$CONFIG_DIR/.env" 2>/dev/null | cut -d'=' -f2 || echo "5678")
            if curl -s "http://localhost:${n8n_port}" >/dev/null 2>&1; then
                success "Web interface accessible at: http://localhost:${n8n_port}"
            else
                warning "Web interface may not be ready yet"
            fi
            
            # Show resource usage
            echo
            info "Resource Usage:"
            systemctl show "$SERVICE_NAME" --property=MainPID --value | xargs -I {} ps -p {} -o pid,ppid,%cpu,%mem,cmd --no-headers 2>/dev/null || echo "Process info not available"
        else
            warning "N8N service is not running"
        fi
        
        echo
        systemctl status "$SERVICE_NAME" --no-pager -l
    else
        warning "N8N service is not installed. Use setup options to install."
    fi
}

# Show service logs with filtering options
show_logs() {
    local lines=${1:-50}
    local follow=${2:-false}
    
    if [[ "$follow" == "true" ]]; then
        info "Following N8N service logs (Ctrl+C to exit):"
        sudo journalctl -u "$SERVICE_NAME" -f
    else
        info "N8N service logs (last $lines lines):"
        sudo journalctl -u "$SERVICE_NAME" -n "$lines" --no-pager
    fi
}

# Quick health check
health_check() {
    info "=== N8N Health Check ==="
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
        warning "Service not installed. Use setup options to install."
        return 1
    fi
    
    # Check if service is running
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        warning "Service not running"
        return 1
    fi
    
    success "Service is running"
    
    # Check web interface
    local n8n_port=$(grep "N8N_PORT=" "$CONFIG_DIR/.env" 2>/dev/null | cut -d'=' -f2 || echo "5678")
    if curl -s "http://localhost:${n8n_port}" >/dev/null 2>&1; then
        success "Web interface responding"
    else
        warning "Web interface not responding"
        return 1
    fi
    
    # Check database connection (if configured)
    if grep -q "DB_TYPE=postgresdb" "$CONFIG_DIR/.env" 2>/dev/null; then
        local db_host=$(grep "DB_HOST=" "$CONFIG_DIR/.env" | cut -d'=' -f2)
        local db_port=$(grep "DB_PORT=" "$CONFIG_DIR/.env" | cut -d'=' -f2)
        
        if nc -z "$db_host" "$db_port" 2>/dev/null; then
            success "Database connection available"
        else
            warning "Database connection issues"
        fi
    fi
    
    success "Health check completed"
}

# Service management functions
manage_service() {
    local action=$1
    local param=$2
    
    case "$action" in
        start)
            info "Starting N8N service..."
            if sudo systemctl start "$SERVICE_NAME"; then
                success "N8N service started"
                sleep 2
                show_detailed_status
            else
                error_exit "Failed to start N8N service"
            fi
            ;;
        stop)
            info "Stopping N8N service..."
            if sudo systemctl stop "$SERVICE_NAME"; then
                success "N8N service stopped"
            else
                error_exit "Failed to stop N8N service"
            fi
            ;;
        restart)
            info "Restarting N8N service..."
            if sudo systemctl restart "$SERVICE_NAME"; then
                success "N8N service restarted"
                sleep 2
                show_detailed_status
            else
                error_exit "Failed to restart N8N service"
            fi
            ;;
        status)
            show_detailed_status
            ;;
        health)
            health_check
            ;;
        logs)
            show_logs "$param" "false"
            ;;
        follow-logs)
            show_logs "50" "true"
            ;;
        enable)
            info "Enabling N8N service for automatic startup..."
            if sudo systemctl enable "$SERVICE_NAME"; then
                success "N8N service enabled for automatic startup"
            else
                error_exit "Failed to enable N8N service"
            fi
            ;;
        disable)
            info "Disabling N8N service automatic startup..."
            if sudo systemctl disable "$SERVICE_NAME"; then
                success "N8N service automatic startup disabled"
            else
                error_exit "Failed to disable N8N service"
            fi
            ;;
        reload)
            info "Reloading systemd configuration..."
            sudo systemctl daemon-reload
            success "Configuration reloaded"
            ;;
        *)
            error_exit "Invalid management command: $action"
            ;;
    esac
}

# Setup mode selection
setup_mode() {
    set -e  # Enable exit on error for setup operations
    
    case $1 in
        1)
            setup_secure_mode
            ;;
        2)
            setup_insecure_mode
            ;;
        3)
            echo "Are you sure you want to remove all N8N services? This will:"
            echo "- Stop the N8N service"
            echo "- Remove the systemd service configuration"
            echo "- Remove the service user"
            echo "- Remove logrotate configuration"
            echo
            read -p "Type 'yes' to confirm: " confirm
            if [[ "$confirm" == "yes" ]]; then
                remove_services
            else
                info "Operation cancelled"
            fi
            ;;
        *)
            error_exit "Invalid setup option"
            ;;
    esac
}

# Show usage information
show_usage() {
    print_status "$CYAN" "N8N Service Manager - Complete Setup and Management Tool"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "SETUP COMMANDS (require sudo):"
    echo "  setup-secure       - Setup service in secure mode"
    echo "  setup-insecure     - Setup service in insecure mode"
    echo "  remove             - Remove all N8N services"
    echo
    echo "MANAGEMENT COMMANDS:"
    echo "  start              - Start the N8N service (requires sudo)"
    echo "  stop               - Stop the N8N service (requires sudo)"
    echo "  restart            - Restart the N8N service (requires sudo)"
    echo "  status             - Show detailed service status"
    echo "  health             - Perform health check"
    echo "  logs [lines]       - Show recent service logs (default: 50)"
    echo "  follow-logs        - Follow service logs in real-time"
    echo "  enable             - Enable automatic startup (requires sudo)"
    echo "  disable            - Disable automatic startup (requires sudo)"
    echo "  reload             - Reload service configuration (requires sudo)"
    echo
    echo "EXAMPLES:"
    echo "  sudo $0                    - Interactive mode"
    echo "  sudo $0 setup-secure       - Setup secure mode service"
    echo "  sudo $0 start              - Start the service"
    echo "  $0 status                  - Check service status"
    echo "  $0 logs 100               - Show last 100 log lines"
    echo "  $0 health                 - Check service health"
    echo
    echo "MODES:"
    echo "  Secure Mode   - N8N_SECURE_COOKIE=true (recommended for production)"
    echo "  Insecure Mode - N8N_SECURE_COOKIE=false (development/testing only)"
}

# Main function
main() {
    # Check if running with command line arguments
    if [[ $# -gt 0 ]]; then
        # Command line mode
        local command=$1
        local param=$2
        
        case "$command" in
            "setup-secure")
                check_sudo
                set -e
                setup_secure_mode
                ;;
            "setup-insecure")
                check_sudo
                set -e
                setup_insecure_mode
                ;;
            "remove")
                check_sudo
                set -e
                remove_services
                ;;
            "start"|"stop"|"restart"|"enable"|"disable"|"reload")
                check_sudo
                manage_service "$command" "$param"
                ;;
            "status"|"health"|"logs"|"follow-logs")
                manage_service "$command" "$param"
                ;;
            "help"|"--help"|"-h")
                show_usage
                ;;
            *)
                show_usage
                error_exit "Unknown command: $command"
                ;;
        esac
    else
        # Interactive mode
        check_sudo
        
        while true; do
            show_menu
            read -p "Enter your choice (1-4): " choice
            echo
            
            case $choice in
                1)
                    setup_mode "$choice"
                    break
                    ;;
                2)
                    setup_mode "$choice"
                    break
                    ;;
                3)
                    setup_mode "$choice"
                    break
                    ;;
                4)
                    info "Exiting..."
                    exit 0
                    ;;
                *)
                    warning "Invalid choice. Please select 1-4."
                    sleep 1
                    ;;
            esac
        done
    fi
}

# Run main function
main "$@"