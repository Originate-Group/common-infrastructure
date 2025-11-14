#!/bin/bash
set -euo pipefail

###########################################
# Caddy Web Server Installation Script
###########################################
# Purpose: Install Caddy web server with multi-app configuration
# Target: Ubuntu 24.04 LTS (compatible with 22.04)
# Usage: Run as root during VPS hardening
# Notes:
#   - Installs Caddy from official repository
#   - Sets up multi-app configuration with import directory
#   - Creates /etc/caddy/conf.d/ for application snippets
#   - Each deployed app writes its own .caddy file
###########################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@originate.group}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Check if Caddy is already installed
check_existing_caddy() {
    if command -v caddy &> /dev/null; then
        log_warn "Caddy is already installed:"
        caddy version
        read -p "Reinstall Caddy? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Caddy installation"
            # Still ensure directories exist
            ensure_directories
            exit 0
        fi
        log_info "Removing existing Caddy installation..."
        systemctl stop caddy || true
        apt-get remove -y caddy || true
    fi
}

# Install prerequisites
install_prerequisites() {
    log_info "Installing prerequisites..."
    apt-get update
    apt-get install -y \
        debian-keyring \
        debian-archive-keyring \
        apt-transport-https \
        curl
}

# Add Caddy's official repository
setup_caddy_repo() {
    log_info "Setting up Caddy repository..."

    # Add Caddy's GPG key
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | \
        gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

    # Add Caddy's repository
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | \
        tee /etc/apt/sources.list.d/caddy-stable.list

    log_info "Caddy repository configured"
}

# Install Caddy
install_caddy() {
    log_info "Installing Caddy..."

    apt-get update
    apt-get install -y caddy

    log_info "Caddy installed successfully"
}

# Create directory structure
ensure_directories() {
    log_info "Setting up Caddy directory structure..."

    # Create conf.d directory for application snippets
    mkdir -p /etc/caddy/conf.d
    chmod 755 /etc/caddy/conf.d

    # Create log directory
    mkdir -p /var/log/caddy
    chown caddy:caddy /var/log/caddy
    chmod 755 /var/log/caddy

    log_info "Directory structure created"
}

# Configure main Caddyfile
configure_caddyfile() {
    log_info "Configuring main Caddyfile..."

    # Backup existing Caddyfile if it exists and isn't empty
    if [[ -f /etc/caddy/Caddyfile && -s /etc/caddy/Caddyfile ]]; then
        cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d-%H%M%S)
        log_info "Backed up existing Caddyfile"
    fi

    # Create new main Caddyfile with import directive
    cat > /etc/caddy/Caddyfile <<EOF
# =============================================================================
# Main Caddy Configuration
# =============================================================================
# This file is managed by common-infrastructure repo
# DO NOT add application-specific configurations here
#
# Application configurations should be placed in:
#   /etc/caddy/conf.d/<app-name>.caddy
#
# Each application deployment writes its own snippet file.
# =============================================================================

{
    # Global options
    email ${ADMIN_EMAIL}

    # Enable admin API on localhost only
    admin localhost:2019

    # Optional: Uncomment for production logging
    # log {
    #     output file /var/log/caddy/access.log
    #     format json
    # }
}

# Import all application configurations
import /etc/caddy/conf.d/*.caddy

# =============================================================================
# Default catch-all (optional)
# =============================================================================
# Uncomment to return 404 for unconfigured domains
# :80, :443 {
#     respond "Not found" 404
# }
EOF

    chmod 644 /etc/caddy/Caddyfile
    log_info "Main Caddyfile configured"
}

# Create example snippet
create_example_snippet() {
    log_info "Creating example application snippet..."

    cat > /etc/caddy/conf.d/example.caddy.disabled <<'EOF'
# =============================================================================
# Example Application Configuration
# =============================================================================
# This is an example snippet showing how applications should configure Caddy.
# To use this example, rename it to remove the .disabled extension.
#
# Each application deployment should create its own .caddy file here.
# =============================================================================

# Example: Simple reverse proxy to local application
# example.originate.group {
#     reverse_proxy localhost:3000
#
#     # Security headers
#     header {
#         Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
#         X-Frame-Options "SAMEORIGIN"
#         X-Content-Type-Options "nosniff"
#         Referrer-Policy "strict-origin-when-cross-origin"
#     }
#
#     # Application-specific logging
#     log {
#         output file /var/log/caddy/example-access.log
#         format json
#     }
# }
EOF

    chmod 644 /etc/caddy/conf.d/example.caddy.disabled
    log_info "Example snippet created: /etc/caddy/conf.d/example.caddy.disabled"
}

# Configure Caddy service
configure_service() {
    log_info "Configuring Caddy service..."

    # Enable and start Caddy
    systemctl enable caddy
    systemctl restart caddy

    # Wait a moment for service to start
    sleep 2

    # Check service status
    if systemctl is-active --quiet caddy; then
        log_info "Caddy service is running"
    else
        log_error "Caddy service failed to start"
        log_error "Check logs: journalctl -u caddy -n 50"
        exit 1
    fi
}

# Verify installation
verify_installation() {
    log_info "Verifying Caddy installation..."

    if caddy version &> /dev/null; then
        log_info "Caddy version:"
        caddy version
    else
        log_error "Caddy installation verification failed"
        exit 1
    fi

    # Validate Caddyfile
    log_info "Validating Caddyfile syntax..."
    if caddy validate --config /etc/caddy/Caddyfile &> /dev/null; then
        log_info "Caddyfile syntax is valid"
    else
        log_error "Caddyfile validation failed"
        caddy validate --config /etc/caddy/Caddyfile
        exit 1
    fi

    # Check if admin API is accessible
    if curl -s http://localhost:2019/config/ &> /dev/null; then
        log_info "Caddy admin API is accessible"
    else
        log_warn "Caddy admin API is not accessible (this is normal if Caddy just started)"
    fi
}

# Display post-installation info
show_post_install_info() {
    echo
    log_info "Caddy installation complete!"
    echo
    log_info "Directory structure:"
    log_info "  /etc/caddy/Caddyfile           - Main configuration (DO NOT MODIFY)"
    log_info "  /etc/caddy/conf.d/*.caddy      - Application snippets (add yours here)"
    log_info "  /var/log/caddy/                - Log files"
    echo
    log_info "How applications should deploy:"
    log_info "  1. Write snippet to: /etc/caddy/conf.d/<app-name>.caddy"
    log_info "  2. Reload Caddy: sudo systemctl reload caddy"
    log_info "  3. DO NOT overwrite /etc/caddy/Caddyfile"
    echo
    log_info "Example snippet locations:"
    log_info "  Keycloak: /etc/caddy/conf.d/keycloak.caddy"
    log_info "  RaaS:     /etc/caddy/conf.d/raas.caddy"
    log_info "  Docs:     /etc/caddy/conf.d/docs.caddy"
    echo
    log_info "Common Caddy commands:"
    log_info "  sudo systemctl status caddy    # Check service status"
    log_info "  sudo systemctl reload caddy    # Reload configuration"
    log_info "  sudo journalctl -u caddy -f    # View logs"
    log_info "  caddy validate --config /etc/caddy/Caddyfile  # Validate config"
    echo
    log_info "Admin email: ${ADMIN_EMAIL}"
    log_info "  (used for Let's Encrypt certificate notifications)"
}

# Main execution
main() {
    log_info "Starting Caddy installation..."
    echo

    check_existing_caddy
    install_prerequisites
    setup_caddy_repo
    install_caddy
    ensure_directories
    configure_caddyfile
    create_example_snippet
    configure_service
    verify_installation
    show_post_install_info
}

main "$@"
