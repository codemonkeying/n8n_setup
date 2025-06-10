# N8N Production Setup - Implementation Plan

## Overview
This document outlines the detailed implementation steps for deploying n8n in a production environment based on the [`n8n_setup_plan.md`](/home/user/n8n/n8n_setup_plan.md) specifications.

## Implementation Phases

### Phase 1: Directory and Environment Preparation
- Create the following directory structure:
  - `/home/user/n8n/`
    - `config/`
    - `workflows/`
    - `logs/`
    - `backups/`
    - `venv/` (Python virtual environment)
- Set secure permissions on sensitive directories (e.g., `config/` with 700 permissions)

### Phase 2: Python Virtual Environment
- Create a Python virtual environment in `/home/user/n8n/venv`
- Activate the venv and install any required Python dependencies
- Ensure isolation from system Python packages

### Phase 3: System Dependencies
#### Node.js & npm
- Check for Node.js v18+ and npm installation
- Install or upgrade Node.js/npm if needed
- Verify installation with version checks

#### PostgreSQL
- Install PostgreSQL server if not present
- Create dedicated database (`n8n_db`) and user (`n8n_user`)
- Generate secure password for database user
- Configure authentication and minimal privileges

### Phase 4: N8N Installation & Configuration
- Install n8n globally via npm: `npm install -g n8n`
- Generate `.env` file in `config/` directory with:
  - Database credentials (PostgreSQL)
  - Port and host settings (default: 5678, 0.0.0.0)
  - Secure encryption key (auto-generated)
  - Logging and workflow directory paths
  - User management settings
- Create `n8n.config.js` if custom JavaScript configuration is needed
- Validate configuration before proceeding

### Phase 5: Production Hardening
- Set restrictive file permissions:
  - `.env` file: 600 (owner read/write only)
  - Config directory: 700 (owner access only)
  - Log directory: 755 (owner full, group/other read)
- Configure log rotation for `/home/user/n8n/logs/`
- Set up health check endpoints
- Prepare HTTPS configuration structure
- Optional: Configure firewall rules

### Phase 6: Service Management
- Create systemd unit file (`/etc/systemd/system/n8n.service`)
- Configure service to:
  - Auto-start on boot
  - Restart on failure
  - Load environment variables from config
  - Depend on PostgreSQL service
  - Run as dedicated user with proper permissions
- Write `install_service.sh` script for automated service installation
- Enable and test service functionality

### Phase 7: Testing & Validation
- Test n8n installation with manual start
- Verify database connectivity
- Check log file creation and permissions
- Test service start/stop/restart functionality
- Validate web interface accessibility
- Confirm workflow directory functionality

## Implementation Scripts

### Main Setup Script (`n8n_setup.sh`)
Features:
- Interactive prompts for configuration options
- Automatic dependency detection and installation
- Database setup with secure password generation
- Configuration file generation and validation
- Comprehensive error handling and rollback capability
- Detailed logging of all operations
- Pre-flight checks and system validation

### Service Installer (`install_service.sh`)
Features:
- Optional systemd service installation
- Service status checking and validation
- Enable/disable service management
- Log file monitoring setup
- Service dependency verification

## Security Considerations
- Generate cryptographically secure passwords and encryption keys
- Implement proper file permissions (600 for sensitive config files)
- Create database user with minimal required privileges
- Prepare for HTTPS deployment with certificate management
- Optional firewall configuration prompts
- Secure log file handling and rotation

## Configuration Details

### Environment Variables (`.env`)
```bash
# Database Configuration
DB_TYPE=postgresdb
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=n8n_db
DB_USERNAME=n8n_user
DB_PASSWORD=<auto_generated_secure_password>

# N8N Configuration
N8N_PORT=5678
N8N_HOST=0.0.0.0
WEBHOOK_URL=http://localhost:5678
N8N_USER_FOLDER=/home/user/n8n
WORKFLOWS_FOLDER=/home/user/n8n/workflows

# Security
N8N_ENCRYPTION_KEY=<auto_generated_32_char_key>
N8N_USER_MANAGEMENT_DISABLED=false

# Logging
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_LOCATION=/home/user/n8n/logs/
```

### Systemd Service Configuration
```ini
[Unit]
Description=n8n Workflow Automation
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=n8n
WorkingDirectory=/home/user/n8n
EnvironmentFile=/home/user/n8n/config/.env
ExecStart=/usr/local/bin/n8n start
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Usage Instructions

### Initial Setup
1. Run the main setup script:
   ```bash
   cd /home/user/n8n
   chmod +x n8n_setup.sh
   ./n8n_setup.sh
   ```

2. Optionally install systemd service:
   ```bash
   chmod +x install_service.sh
   ./install_service.sh
   ```

### Starting N8N
```bash
# If service installed:
sudo systemctl start n8n
sudo systemctl enable n8n

# Manual start:
cd /home/user/n8n
source venv/bin/activate
n8n start
```

### Monitoring and Maintenance
- Access n8n web interface: `http://localhost:5678`
- Monitor logs: `tail -f /home/user/n8n/logs/n8n.log`
- Check service status: `sudo systemctl status n8n`
- Database backups: Regular dumps to `/home/user/n8n/backups/`

## Post-Installation Checklist
- [ ] N8N web interface accessible at configured port
- [ ] Database connectivity verified
- [ ] Workflows directory writable
- [ ] Log files being created properly
- [ ] Service auto-starts on boot (if installed)
- [ ] Initial admin user configured
- [ ] Backup strategy implemented
- [ ] Security hardening completed

## Troubleshooting
- Check logs in `/home/user/n8n/logs/` for errors
- Verify database connection with `psql` commands
- Ensure all file permissions are correct
- Check service status with `systemctl status n8n`
- Validate environment variables in `.env` file

## Implementation Timeline
- **Phase 1-2**: 10 minutes (Directory setup, Python venv)
- **Phase 3**: 15-30 minutes (System dependencies)
- **Phase 4**: 10 minutes (N8N installation)
- **Phase 5**: 15 minutes (Security hardening)
- **Phase 6**: 10 minutes (Service setup)
- **Phase 7**: 10 minutes (Testing)

**Total Estimated Time**: 70-90 minutes

---

*This implementation plan follows the specifications outlined in [`n8n_setup_plan.md`](/home/user/n8n/n8n_setup_plan.md) and provides a comprehensive approach to deploying n8n in a production environment.*