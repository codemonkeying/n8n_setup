#!/bin/bash

# N8N Service Manager
# Simple systemd service setup and management
# Version: 2.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
N8N_DIR="/home/user/n8n"
SERVICE_NAME="n8n"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

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

# Create systemd service file for secure mode
create_secure_service() {
    info "Creating systemd service for SECURE mode..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=n8n Workflow Automation Platform (Secure Mode)
Documentation=https://docs.n8n.io
After=network.target

[Service]
Type=simple
User=user
Group=user
WorkingDirectory=$N8N_DIR
ExecStart=$N8N_DIR/start_n8n.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=n8n

[Install]
WantedBy=multi-user.target
EOF
    
    success "Secure mode systemd service created"
}

# Create systemd service file for insecure mode
create_insecure_service() {
    info "Creating systemd service for INSECURE mode..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=n8n Workflow Automation Platform (Insecure Mode)
Documentation=https://docs.n8n.io
After=network.target

[Service]
Type=simple
User=user
Group=user
WorkingDirectory=$N8N_DIR
ExecStart=$N8N_DIR/start_n8n_insecure.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=n8n

[Install]
WantedBy=multi-user.target
EOF
    
    success "Insecure mode systemd service created"
}

# Install and enable service
install_service() {
    info "Installing and enabling N8N service..."
    
    # Reload systemd daemon
    systemctl daemon-reload
    
    # Enable service to start on boot
    systemctl enable "$SERVICE_NAME"
    
    # Start the service
    systemctl start "$SERVICE_NAME"
    
    success "N8N service installed, enabled, and started"
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
    
    info "Reloading systemd daemon..."
    systemctl daemon-reload
    
    success "All N8N services have been removed successfully!"
    info "N8N installation files remain in: $N8N_DIR"
    info "You can still run N8N manually using the start scripts"
}

# Setup secure mode service
setup_secure_mode() {
    header "=== Setting up N8N Service (SECURE MODE) ==="
    
    create_secure_service
    install_service
    
    print_status "$GREEN" "=== Secure Mode Service Installation Complete ==="
    echo
    success "N8N systemd service (SECURE MODE) has been installed successfully!"
    echo
    info "Service uses: $N8N_DIR/start_n8n.sh"
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
    
    create_insecure_service
    install_service
    
    print_status "$GREEN" "=== Insecure Mode Service Installation Complete ==="
    echo
    success "N8N systemd service (INSECURE MODE) has been installed successfully!"
    echo
    warning "Security Notice:"
    echo "  - Secure cookies disabled (N8N_SECURE_COOKIE=false)"
    echo "  - This mode is intended for development/testing only"
    echo
    info "Service uses: $N8N_DIR/start_n8n_insecure.sh"
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
    info "Service Details:"
    echo "  - Service name:     n8n"
    echo "  - Service user:     user"
    echo "  - Service file:     $SERVICE_FILE"
    echo "  - Auto-start:       Enabled"
    echo
    success "N8N service is now running!"
}

# Show service status
show_status() {
    info "=== N8N Service Status ==="
    
    if systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
        local status=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo "inactive")
        local enabled=$(systemctl is-enabled "$SERVICE_NAME" 2>/dev/null || echo "disabled")
        
        echo "Service Status: $status"
        echo "Auto-start: $enabled"
        
        if [[ "$status" == "active" ]]; then
            success "N8N service is running"
        else
            warning "N8N service is not running"
        fi
        
        echo
        systemctl status "$SERVICE_NAME" --no-pager -l
    else
        warning "N8N service is not installed. Use setup options to install."
    fi
}

# Display menu
show_menu() {
    header "=== N8N Service Manager ==="
    echo
    print_status "$CYAN" "Please select an option:"
    echo
    echo "1) Setup service for SECURE mode"
    echo "   - Uses start_n8n.sh (secure cookies enabled)"
    echo "   - Recommended for production environments"
    echo
    echo "2) Setup service for INSECURE mode"
    echo "   - Uses start_n8n_insecure.sh (secure cookies disabled)"
    echo "   - For development/testing purposes only"
    echo
    echo "3) Remove all N8N services"
    echo "   - Stops and removes systemd service"
    echo "   - Keeps N8N installation files intact"
    echo
    echo "4) Show service status"
    echo
    echo "5) Exit"
    echo
}

# Show usage information
show_usage() {
    print_status "$CYAN" "N8N Service Manager - Simple Setup and Management Tool"
    echo
    echo "Usage: $0 [command]"
    echo
    echo "COMMANDS:"
    echo "  setup-secure       - Setup service in secure mode"
    echo "  setup-insecure     - Setup service in insecure mode"
    echo "  remove             - Remove all N8N services"
    echo "  status             - Show service status"
    echo "  start              - Start the service"
    echo "  stop               - Stop the service"
    echo "  restart            - Restart the service"
    echo "  logs               - Show service logs"
    echo
    echo "EXAMPLES:"
    echo "  $0                     - Interactive mode"
    echo "  $0 setup-secure        - Setup secure mode service"
    echo "  $0 status              - Check service status"
    echo "  $0 start               - Start the service"
    echo
    echo "MODES:"
    echo "  Secure Mode   - Uses start_n8n.sh (secure cookies enabled)"
    echo "  Insecure Mode - Uses start_n8n_insecure.sh (secure cookies disabled)"
}

# Main function
main() {
    # Check if running with command line arguments
    if [[ $# -gt 0 ]]; then
        # Command line mode
        local command=$1
        
        case "$command" in
            "setup-secure")
                check_sudo
                setup_secure_mode
                ;;
            "setup-insecure")
                check_sudo
                setup_insecure_mode
                ;;
            "remove")
                check_sudo
                remove_services
                ;;
            "status")
                show_status
                ;;
            "start")
                check_sudo
                systemctl start "$SERVICE_NAME"
                success "N8N service started"
                ;;
            "stop")
                check_sudo
                systemctl stop "$SERVICE_NAME"
                success "N8N service stopped"
                ;;
            "restart")
                check_sudo
                systemctl restart "$SERVICE_NAME"
                success "N8N service restarted"
                ;;
            "logs")
                journalctl -u "$SERVICE_NAME" -f
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
        while true; do
            show_menu
            read -p "Enter your choice (1-5): " choice
            echo
            
            case $choice in
                1)
                    check_sudo
                    setup_secure_mode
                    break
                    ;;
                2)
                    check_sudo
                    setup_insecure_mode
                    break
                    ;;
                3)
                    check_sudo
                    echo "Are you sure you want to remove all N8N services? This will:"
                    echo "- Stop the N8N service"
                    echo "- Remove the systemd service configuration"
                    echo
                    read -p "Type 'yes' to confirm: " confirm
                    if [[ "$confirm" == "yes" ]]; then
                        remove_services
                    else
                        info "Operation cancelled"
                    fi
                    break
                    ;;
                4)
                    show_status
                    echo
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    info "Exiting..."
                    exit 0
                    ;;
                *)
                    warning "Invalid choice. Please select 1-5."
                    sleep 1
                    ;;
            esac
        done
    fi
}

# Run main function
main "$@"