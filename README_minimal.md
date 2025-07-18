# N8N Minimal Setup

A streamlined, minimal implementation for deploying a standalone n8n instance on Linux with PostgreSQL. This setup prioritizes quick deployment while maintaining security basics.

## Features

- **Directory Flexible**: Works in any directory, no hardcoded paths
- **Minimal Dependencies**: Only installs what's essential (Node.js 18+, PostgreSQL, n8n)
- **Secure by Default**: Auto-generated passwords, proper file permissions
- **Development Mode**: Optional insecure mode for testing without HTTPS
- **Quick Setup**: 20-30 minute installation

## Quick Start

1. **Clone and navigate to the repository:**
   ```bash
   git clone https://github.com/codemonkeying/n8n_setup.git
   cd n8n_setup
   ```

2. **Run the minimal setup:**
   ```bash
   ./n8n_minimal_setup.sh
   ```

3. **For development/testing (without HTTPS):**
   ```bash
   ./n8n_minimal_setup.sh --insecure
   ```

4. **Start n8n:**
   ```bash
   ./start_n8n.sh
   # or for insecure mode:
   ./start_n8n_insecure.sh
   ```

5. **Access n8n:**
   Open http://localhost:5678 in your browser

## What Gets Installed

### System Dependencies
- Node.js v18+ (via NodeSource if not present)
- PostgreSQL (if not already installed)

### Directory Structure
```
./
├── config/           # Configuration files (.env, passwords)
├── workflows/        # Custom workflows
├── logs/            # Log files
├── plan.md          # Implementation plan
├── n8n_minimal_setup.sh    # Main setup script
├── start_n8n.sh            # Secure start script
└── start_n8n_insecure.sh   # Insecure start script (dev only)
```

### Database Setup
- Database: `n8n_db`
- User: `n8n_user`
- Password: Auto-generated (stored securely in `./config/.db_password`)

## Configuration

The setup creates `./config/.env` with:
- PostgreSQL connection settings
- n8n port (5678) and host configuration
- Webhook URL (http://localhost:5678)
- Auto-generated encryption key
- Logging configuration

## Security Features

- **Secure Passwords**: Auto-generated using OpenSSL
- **File Permissions**: Config directory (700), .env file (600)
- **Minimal Privileges**: Database user has only necessary permissions
- **Secure Cookies**: Enabled by default (disable with --insecure for dev)

## Development Mode (--insecure)

⚠️ **Warning**: Only use for development/testing!

The `--insecure` flag:
- Sets `N8N_SECURE_COOKIE=false`
- Allows cookies over HTTP (useful when testing without HTTPS)
- Should NOT be used in production

## Usage Examples

### Standard Setup
```bash
./n8n_minimal_setup.sh
./start_n8n.sh
```

### Development Setup
```bash
./n8n_minimal_setup.sh --insecure
./start_n8n_insecure.sh
```

### Check Setup Status
```bash
# View logs
tail -f logs/setup.log

# Check n8n logs
tail -f logs/n8n.log
```

## Troubleshooting

### Common Issues

1. **Node.js version too old**
   - The script automatically installs Node.js v18+ if needed

2. **PostgreSQL connection failed**
   - Check if PostgreSQL service is running: `sudo systemctl status postgresql`
   - Restart if needed: `sudo systemctl restart postgresql`

3. **Permission denied on scripts**
   - Make scripts executable: `chmod +x *.sh`

4. **Port 5678 already in use**
   - Edit `./config/.env` and change `N8N_PORT=5678` to another port
   - Restart n8n

### Log Files
- Setup logs: `./logs/setup.log`
- n8n logs: `./logs/n8n.log` (when running)

## Next Steps

This minimal setup provides a functional base. For production use, consider:

1. **Service Management**: Set up systemd service for auto-start
2. **HTTPS Setup**: Configure reverse proxy (Nginx) with SSL/TLS
3. **Backups**: Implement database and workflow backups
4. **Monitoring**: Add log rotation and monitoring
5. **Firewall**: Configure proper firewall rules
6. **Updates**: Regular n8n and system updates

## Advanced Configuration

### Custom Database Settings
Edit `./config/.env` to modify:
- `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`
- Restart n8n after changes

### Custom n8n Settings
Add any n8n environment variables to `./config/.env`:
```bash
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_password
```

## Support

- **Documentation**: See `plan.md` for detailed implementation plan
- **Issues**: Report issues on GitHub
- **n8n Documentation**: https://docs.n8n.io/

## License

This setup script is provided as-is for educational and development purposes.