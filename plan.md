# N8N Minimal Implementation Plan

## Overview
This document provides a streamlined, minimal implementation plan for deploying a standalone n8n instance on Linux with PostgreSQL. The focus is on core setup in the current working directory (where the script is run), avoiding hardcoded paths like /home/user/n8n. This ensures flexibility for any directory. Advanced features (e.g., backups, HTTPS) are deferred to next steps. The plan includes support for an "insecure mode" for development/testing.

Based on the existing n8n_setup_plan.md, this minimal version prioritizes quick setup while maintaining security basics.

## Key Principles
- **Directory Flexibility**: All paths are relative to the current directory (e.g., ./config/, ./logs/). Use N8N_DIR=$(pwd) in scripts to resolve absolute paths dynamically.
- **Minimal Scope**: Install dependencies, set up DB, install n8n, generate config, and provide basic start scripts. Service management and hardening are optional/next steps.
- **Insecure Mode**: An optional mode that sets N8N_SECURE_COOKIE=false in the environment. Use this only for local development or testing (e.g., when running without HTTPS, to avoid cookie issues). It's not recommended for production as it reduces security (e.g., allows cookies over HTTP). Scripts will include a flag or prompt to enable it.

## Implementation Phases

### Phase 1: Directory Preparation
- Create subdirectories in the current directory:
  - `./config/` (for .env and sensitive files)
  - `./workflows/` (for custom workflows)
  - `./logs/` (for log files)
- Set basic permissions: `chmod 700 ./config/` for owner-only access.
- No backups or venv in minimal setup (add Python venv if needed for extensions later).

### Phase 2: System Dependencies
- **Node.js & npm**: Check for v18+; install via NodeSource if missing.
- **PostgreSQL**: Install if not present; create DB (n8n_db) and user (n8n_user) with auto-generated secure password.
- Skip other deps unless essential.

### Phase 3: N8N Installation & Configuration
- Install n8n globally: `npm install -g n8n`.
- Generate `./config/.env` with minimal vars:
```bash
DB_TYPE=postgresdb
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=n8n_db
DB_USERNAME=n8n_user
DB_PASSWORD=<auto_generated>
N8N_PORT=5678
N8N_HOST=0.0.0.0
WEBHOOK_URL=http://localhost:5678
N8N_USER_FOLDER=<current_dir>
WORKFLOWS_FOLDER=<current_dir>/workflows
N8N_ENCRYPTION_KEY=<auto_generated>
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_LOCATION=<current_dir>/logs/
```
- Set `chmod 600 ./config/.env`.
- For insecure mode: Add a script flag (e.g., `--insecure`) that appends `N8N_SECURE_COOKIE=false` to .env or exports it in start scripts. Warn users in output/docs.

### Phase 4: Basic Startup & Testing
- Create simple start scripts:
  - `./start_n8n.sh`: Sources .env and runs `n8n start`.
  - `./start_n8n_insecure.sh`: Same, but exports `N8N_SECURE_COOKIE=false`.
- Test: Verify DB connection, run n8n briefly, check logs.
- Access at http://localhost:5678.

## Implementation Scripts

### Main Setup Script (n8n_setup.sh)
- Interactive with minimal prompts (e.g., confirm insecure mode).
- Dynamic paths: `N8N_DIR=$(pwd)`.
- Error handling and logging to `./logs/setup.log`.
- Option: `--insecure` flag to enable insecure mode (add warning).

### Start Scripts
- As above, with insecure variant including export for `N8N_SECURE_COOKIE=false`.

## Security Considerations
- Auto-generate passwords/keys with openssl.
- Minimal privileges for DB user.
- Insecure mode: Only for dev/testing; document risks (e.g., "Use when HTTPS is not set up to avoid session issues, but switch to secure for prod").

## Usage Instructions

### Quick Setup
1. Run `./n8n_setup.sh` (add `--insecure` if needed).
2. Start with `./start_n8n.sh` or `./start_n8n_insecure.sh`.
3. Access: http://localhost:5678.

## Next Steps
- **Service Management**: Add systemd via a separate script (e.g., service_manager.sh with secure/insecure options).
- **Production Hardening**: Implement HTTPS (e.g., via Nginx reverse proxy + Let's Encrypt), firewall rules, log rotation.
- **Backups**: Add `./backup_n8n.sh` for DB dumps and workflow tars.
- **Testing/Validation**: Extend with `./test_setup.sh` for syntax checks.
- **Uninstall**: Script to drop DB, remove dirs.
- **Customization**: Prompts for custom ports/DB names; Python venv for extensions.
- **GitHub Repo**: Structure as in original plan, with examples and docs.

## Estimated Timeline
- **Core Setup**: 20-30 minutes.
- **With Next Steps**: Add 30-60 minutes.

This minimal plan provides a functional base; expand via next steps for full production readiness.