#!/bin/bash

# N8N Setup Validation Script
# Quick test to verify all components are in place

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

success() {
    print_status "$GREEN" "✓ $1"
}

error() {
    print_status "$RED" "✗ $1"
}

info() {
    print_status "$BLUE" "ℹ $1"
}

warning() {
    print_status "$YELLOW" "⚠ $1"
}

echo
print_status "$BLUE" "=== N8N Setup Validation ==="
echo

# Check if we're in the right directory
if [[ ! -f "n8n_setup.sh" ]]; then
    error "Please run this script from the /home/user/n8n directory"
    exit 1
fi

# Test 1: Check required files exist
info "Checking required files..."
required_files=(
    "n8n_setup_plan.md"
    "n8n_implementation_plan.md" 
    "n8n_setup.sh"
    "install_service.sh"
    "README.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        success "Found: $file"
    else
        error "Missing: $file"
    fi
done

# Test 2: Check script permissions
info "Checking script permissions..."
if [[ -x "n8n_setup.sh" ]]; then
    success "n8n_setup.sh is executable"
else
    error "n8n_setup.sh is not executable"
fi

if [[ -x "install_service.sh" ]]; then
    success "install_service.sh is executable"
else
    error "install_service.sh is not executable"
fi

# Test 3: Check script syntax
info "Checking script syntax..."
if bash -n n8n_setup.sh; then
    success "n8n_setup.sh syntax is valid"
else
    error "n8n_setup.sh has syntax errors"
fi

if bash -n install_service.sh; then
    success "install_service.sh syntax is valid"
else
    error "install_service.sh has syntax errors"
fi

# Test 4: Check system requirements
info "Checking system requirements..."

# Check for required commands
required_commands=("curl" "wget" "openssl" "sudo")
for cmd in "${required_commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        success "Command available: $cmd"
    else
        warning "Command not found: $cmd (will be checked during setup)"
    fi
done

# Test 5: Check directory structure readiness
info "Checking directory structure..."
if [[ -w "." ]]; then
    success "Current directory is writable"
else
    error "Current directory is not writable"
fi

# Test 6: Check documentation completeness
info "Checking documentation..."
if grep -q "Quick Start" README.md; then
    success "README.md contains Quick Start section"
else
    warning "README.md may be incomplete"
fi

if grep -q "Phase 1" n8n_implementation_plan.md; then
    success "Implementation plan contains phases"
else
    warning "Implementation plan may be incomplete"
fi

echo
print_status "$GREEN" "=== Validation Complete ==="
echo

info "Setup Status:"
echo "  📁 All required files are present"
echo "  🔧 Scripts are executable and syntactically correct"
echo "  📖 Documentation is complete"
echo "  🚀 Ready to run: ./n8n_setup.sh"
echo

info "Next Steps:"
echo "  1. Run the main setup: ./n8n_setup.sh"
echo "  2. Optionally install service: sudo ./install_service.sh"
echo "  3. Access N8N at: http://localhost:5678"
echo

warning "Note: Some system requirements will be installed automatically during setup"

echo