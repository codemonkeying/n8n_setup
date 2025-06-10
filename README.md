# N8N Production Setup

A comprehensive, production-ready setup for n8n workflow automation platform with PostgreSQL database integration, systemd service management, and security hardening.

## 📋 Overview

This setup provides:
- **PostgreSQL Integration**: Robust database backend for workflow storage
- **Systemd Service**: Automatic startup, restart on failure, and proper process management
- **Security Hardening**: Secure file permissions, dedicated user, and encrypted credentials
- **Monitoring & Logging**: Comprehensive logging with rotation and service monitoring
- **Backup System**: Automated backup scripts for database and workflows
- **Virtual Environment**: Isolated Python environment for dependencies

## 🏗️ Project Structure

```
/home/user/n8n/
├── n8n_setup_plan.md           # Original setup plan documentation
├── n8n_implementation_plan.md  # Detailed implementation guide
├── n8n_setup.sh               # Main setup script
├── install_service.sh          # Systemd service installer
├── README.md                   # This file
├── config/
│   ├── .env                    # Environment variables (created during setup)
│   └── .db_password           # Database password (created during setup)
├── workflows/                  # Custom workflows directory
├── logs/                      # Log files directory
├── backups/                   # Database and workflow backups
├── venv/                      # Python virtual environment
├── start_n8n.sh              # Manual startup script (created during setup)
├── manage_service.sh          # Service management script (created during setup)
└── backup_n8n.sh             # Backup script (created during setup)
```

## 🚀 Quick Start

### 1. Run Main Setup
```bash
cd /home/user/n8n
./n8n_setup.sh
```

### 2. Install Systemd Service (Optional)
```bash
sudo ./install_service.sh
```

### 3. Access N8N
Open your browser and navigate to: `http://localhost:5678`

## 📖 Detailed Setup Instructions

### Prerequisites
- Ubuntu/Debian-based Linux system
- Internet connection for downloading dependencies
- Sudo privileges for system-level installations

### Step 1: Main Setup Script

The [`n8n_setup.sh`](n8n_setup.sh) script performs the following:

1. **System Requirements Check**: Verifies required commands and permissions
2. **Directory Structure**: Creates organized directory layout
3. **Python Virtual Environment**: Sets up isolated Python environment
4. **Node.js Installation**: Installs Node.js v18+ if not present
5. **PostgreSQL Setup**: Installs and configures PostgreSQL database
6. **Database Creation**: Creates dedicated n8n database and user
7. **N8N Installation**: Installs n8n globally via npm
8. **Configuration Generation**: Creates secure environment variables
9. **Permission Setting**: Applies proper file and directory permissions
10. **Testing**: Validates installation and database connectivity

```bash
./n8n_setup.sh
```

### Step 2: Service Installation (Optional)

The [`install_service.sh`](install_service.sh) script provides:

1. **System User Creation**: Creates dedicated service user
2. **Systemd Service**: Configures auto-start and restart policies
3. **Log Rotation**: Sets up automatic log rotation
4. **Security Hardening**: Applies systemd security features
5. **Management Scripts**: Creates service control utilities
6. **Backup Scripts**: Provides automated backup functionality

```bash
sudo ./install_service.sh
```

## 🔧 Configuration

### Environment Variables

The setup automatically generates a `.env` file in the `config/` directory:

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

### Customization

To modify configuration:
1. Edit `config/.env` file
2. Restart n8n service: `sudo systemctl restart n8n`

## 🎮 Usage

### Manual Start/Stop
```bash
# Start manually
./start_n8n.sh

# Stop (Ctrl+C in terminal)
```

### Service Management
```bash
# Using systemctl
sudo systemctl start n8n
sudo systemctl stop n8n
sudo systemctl restart n8n
sudo systemctl status n8n

# Using management script
./manage_service.sh start
./manage_service.sh stop
./manage_service.sh restart
./manage_service.sh status
./manage_service.sh logs
./manage_service.sh follow-logs
```

### Backup and Restore
```bash
# Create backup
./backup_n8n.sh

# Backups are stored in backups/ directory:
# - n8n_db_backup_YYYYMMDD_HHMMSS.sql (database)
# - workflows_backup_YYYYMMDD_HHMMSS.tar.gz (workflows)
# - config_backup_YYYYMMDD_HHMMSS.tar.gz (configuration)
```

## 📊 Monitoring

### Service Status
```bash
# Check service status
sudo systemctl status n8n

# View recent logs
sudo journalctl -u n8n -n 50

# Follow logs in real-time
sudo journalctl -u n8n -f
```

### Log Files
- **Setup logs**: `logs/setup.log`
- **N8N logs**: `logs/` (as configured in .env)
- **System logs**: `sudo journalctl -u n8n`

### Health Checks
```bash
# Check if n8n is responding
curl http://localhost:5678

# Check database connectivity
PGPASSWORD="$(cat config/.db_password)" psql -h localhost -U n8n_user -d n8n_db -c "SELECT 1;"
```

## 🔒 Security Features

### File Permissions
- **Config directory**: 700 (owner only)
- **Environment file**: 600 (owner read/write only)
- **Database password**: 600 (owner read/write only)
- **Log directory**: 755 (standard logging permissions)

### Service Security
- **Dedicated user**: Runs as `n8n` system user
- **No new privileges**: Prevents privilege escalation
- **Private temp**: Isolated temporary directory
- **Protected system**: Read-only system directories
- **Resource limits**: CPU and file descriptor limits

### Database Security
- **Dedicated user**: Separate PostgreSQL user with minimal privileges
- **Encrypted password**: Secure password generation and storage
- **Local connections**: Database accessible only from localhost

## 🛠️ Troubleshooting

### Common Issues

#### N8N Won't Start
```bash
# Check service status
sudo systemctl status n8n

# Check logs
sudo journalctl -u n8n -n 50

# Verify configuration
cat config/.env
```

#### Database Connection Issues
```bash
# Test database connection
PGPASSWORD="$(cat config/.db_password)" psql -h localhost -U n8n_user -d n8n_db -c "SELECT 1;"

# Check PostgreSQL status
sudo systemctl status postgresql
```

#### Permission Issues
```bash
# Reset permissions
sudo chown -R n8n:n8n /home/user/n8n
chmod 700 config/
chmod 600 config/.env config/.db_password
```

#### Port Already in Use
```bash
# Check what's using port 5678
sudo netstat -tlnp | grep 5678

# Change port in config/.env and restart
```

### Log Analysis
```bash
# Setup logs
tail -f logs/setup.log

# Service logs
sudo journalctl -u n8n -f

# N8N application logs
tail -f logs/*.log
```

## 🔄 Maintenance

### Regular Tasks
1. **Monitor logs**: Check for errors or warnings
2. **Update n8n**: `sudo npm update -g n8n`
3. **Backup data**: Run `./backup_n8n.sh` regularly
4. **Check disk space**: Monitor logs and backups directories
5. **Security updates**: Keep system packages updated

### Backup Strategy
- **Automated**: Old backups are automatically cleaned (7+ days)
- **Manual**: Run `./backup_n8n.sh` before major changes
- **Restore**: Use PostgreSQL tools to restore database backups

### Updates
```bash
# Update n8n
sudo npm update -g n8n
sudo systemctl restart n8n

# Update system packages
sudo apt update && sudo apt upgrade
```

## 📚 Additional Resources

- **N8N Documentation**: https://docs.n8n.io
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Systemd Documentation**: https://systemd.io/

## 🆘 Support

### Files to Check
1. `logs/setup.log` - Setup process logs
2. `config/.env` - Environment configuration
3. `sudo journalctl -u n8n` - Service logs
4. `/etc/systemd/system/n8n.service` - Service configuration

### Information to Gather
- Operating system version: `lsb_release -a`
- Node.js version: `node --version`
- N8N version: `n8n --version`
- PostgreSQL version: `psql --version`
- Service status: `sudo systemctl status n8n`

---

**Created by**: N8N Production Setup System  
**Version**: 1.0  
**Last Updated**: $(date '+%Y-%m-%d')

> ⚠️ **Security Note**: Keep your database password secure and regularly update your system packages for security patches.