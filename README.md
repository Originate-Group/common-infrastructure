# common-infrastructure

**Business**: Originate Group (Shared)
**Owner**: DevOps Team
**Maintained by**: @originate-group/devops

## Overview

Infrastructure provisioning and hardening scripts for VPS deployments across all Originate Group projects. This repository provides baseline security configurations and setup automation for fresh VPS instances.

## Purpose

Bootstrap and harden new VPS instances to be ready for application deployments. Scripts are designed to be run manually via SSH before automated CI/CD pipelines take over.

## Technology Stack

- **Platform**: Ubuntu 24.04 LTS
- **Execution**: Bash scripts (manual SSH execution)
- **Security**: UFW firewall, fail2ban, SSH hardening, unattended-upgrades
- **Container Runtime**: Docker + Docker Compose

## Repository Structure

```
common-infrastructure/
├── scripts/
│   ├── harden-ubuntu-vps.sh          # Main hardening script
│   ├── setup-docker.sh                # Docker installation
│   ├── setup-ssh-keys.sh              # SSH key configuration
│   └── setup-firewall.sh              # UFW firewall rules
├── docs/
│   ├── VPS-SETUP.md                   # Step-by-step setup guide
│   └── SSH-1PASSWORD.md               # 1Password SSH integration
├── CLAUDE.md                          # Repository context for Claude Code
└── README.md
```

## Quick Start

### Prerequisites

- Fresh Ubuntu 24.04 LTS VPS
- Root or sudo access
- 1Password SSH agent configured (for Wayne's machine)

### Basic Usage

```bash
# SSH to new VPS
ssh root@YOUR_VPS_IP

# Clone this repo
git clone https://github.com/Originate-Group/common-infrastructure.git
cd common-infrastructure

# Run hardening script
./scripts/harden-ubuntu-vps.sh

# Follow prompts to configure
```

## What Gets Configured

### Security Hardening
- SSH hardening (disable root login, password auth)
- UFW firewall (minimal open ports)
- Fail2ban (brute force protection)
- Automatic security updates

### User Setup
- Create deployment user with sudo access
- Configure SSH key authentication
- Set up authorized_keys for CI/CD

### Docker Setup
- Install Docker Engine
- Install Docker Compose plugin
- Add deployment user to docker group

### System Baseline
- Update all packages
- Configure timezone
- Set up basic logging
- Install essential tools (git, curl, vim, etc.)

## Related Repositories

- [common-devops-agent](https://github.com/Originate-Group/common-devops-agent): CI/CD workflows (runs after VPS is hardened)
- [originate-keycloak-deployment](https://github.com/Originate-Group/originate-keycloak-deployment): Keycloak SSO deployment
- [originate-requirements-service](https://github.com/Originate-Group/originate-requirements-service): RaaS application

## Documentation

- [VPS Setup Guide](./docs/VPS-SETUP.md) - Detailed setup instructions
- [1Password SSH Integration](./docs/SSH-1PASSWORD.md) - SSH key management for CI/CD

## Support

- **Technical Issues**: Create an issue in this repository
- **Business Questions**: Contact @originate-group/devops
- **Security Issues**: Contact @originate-group/security

## License

Proprietary - Originate Group © 2025
