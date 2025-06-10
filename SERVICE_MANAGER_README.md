# N8N Service Manager

A comprehensive script for setting up and managing N8N as a systemd service with support for both secure and insecure modes.

## Features

- **Setup Options**: Configure N8N service in secure or insecure mode
- **Service Management**: Start, stop, restart, and monitor the service
- **Health Monitoring**: Built-in health checks and status reporting
- **Log Management**: View and follow service logs
- **Easy Removal**: Clean removal of all service components

## Usage

### Interactive Mode
```bash
sudo ./service_manager.sh
```

### Command Line Mode

#### Setup Commands (require sudo)
```bash
sudo ./service_manager.sh setup-secure     # Setup secure mode service
sudo ./service_manager.sh setup-insecure   # Setup insecure mode service
sudo ./service_manager.sh remove           # Remove all N8N services
```

#### Management Commands
```bash
sudo ./service_manager.sh start            # Start the service
sudo ./service_manager.sh stop             # Stop the service
sudo ./service_manager.sh restart          # Restart the service
./service_manager.sh status                 # Show service status
./service_manager.sh health                 # Health check
./service_manager.sh logs [lines]           # Show logs (default: 50 lines)
./service_manager.sh follow-logs            # Follow logs in real-time
sudo ./service_manager.sh enable           # Enable auto-start
sudo ./service_manager.sh disable          # Disable auto-start
```

## Service Modes

### Secure Mode (Recommended for Production)
- Sets `N8N_SECURE_COOKIE=true`
- Enhanced security settings
- Recommended for production environments

### Insecure Mode (Development/Testing)
- Sets `N8N_SECURE_COOKIE=false`
- Less secure but may be needed for certain development setups
- **Warning**: Only use for development or testing

## Service Details

- **Service Name**: `n8n`
- **Service User**: `n8n` (system user)
- **Service File**: `/etc/systemd/system/n8n.service`
- **Configuration**: Uses environment file at `./config/.env`
- **Logs**: Available via `journalctl -u n8n`

## Examples

```bash
# Setup secure mode service
sudo ./service_manager.sh setup-secure

# Check service status
./service_manager.sh status

# View last 100 log lines
./service_manager.sh logs 100

# Follow logs in real-time
./service_manager.sh follow-logs

# Remove all services
sudo ./service_manager.sh remove
```

## Prerequisites

- N8N must be installed and configured (run `n8n_setup.sh` first)
- PostgreSQL database should be running
- Script must be run with sudo for setup and service control operations

## Troubleshooting

1. **Service won't start**: Check logs with `./service_manager.sh logs`
2. **Permission issues**: Ensure script is run with sudo for setup/control operations
3. **Database connection**: Verify PostgreSQL is running and accessible
4. **Web interface not accessible**: Check if service is running and port is correct in config