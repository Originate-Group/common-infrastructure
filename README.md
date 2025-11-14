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
│   ├── setup-caddy.sh                 # Caddy web server installation
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

### Caddy Web Server
- Install Caddy from official repository
- Configure multi-app architecture with import directory
- Create `/etc/caddy/conf.d/` for application snippets
- Set up automatic HTTPS with Let's Encrypt

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
- [GitHub Secrets and Variables Guide](./docs/GITHUB-SECRETS-VARIABLES.md) - Comprehensive reference for configuring secrets vs variables

## Claude Code Skills

### Repository-Local Skills

This repository provides reusable Claude Code skills for deployment repos:

- **`/github-secrets-variables`** - Interactive guidance for configuring GitHub Secrets and Variables correctly

#### Using Local Skills in Other Repos

To use these skills in your deployment repository, add to your `.claude/CLAUDE.md`:

```markdown
## Skills

- [GitHub Secrets/Variables](@Originate-Group/common-infrastructure:.claude/skills/github-secrets-variables.md) - Guidance on configuring GitHub Actions secrets and variables
```

### Global Skills

Global skills are installed to `~/.claude/skills/` and available across all projects:

#### `/deployment-sme` - Deployment Subject Matter Expert
**Location**: `~/.claude/skills/deployment-sme.md`

Expert guidance for GitHub Actions deployment workflows, based on 40+ production deployment commits.

**Capabilities**:
- Prevent 15 common deployment failures before they occur
- Proactively apply battle-tested patterns
- Fix YAML, Docker, SSH, and Caddy configuration issues
- Eliminate 20-30 iteration deployment cycles

**Key patterns**:
- YAML heredoc syntax (use brace groups, not heredocs)
- appleboy/ssh-action best practices
- Caddy multi-app snippet architecture
- Docker Compose v2 commands
- Python venv on Ubuntu 24.04
- Keycloak health check ports
- And 9 more proven patterns

**Usage**: Available globally in any deployment repository - Claude automatically applies learned patterns.

#### `/infrastructure-agent` - VPS Bootstrap Automation
**Location**: `~/.claude/skills/infrastructure-agent.md`

Autonomous agent for automating VPS infrastructure setup from fresh server to production-ready environment.

**Capabilities**:
- Bootstrap fresh VPS with password authentication
- Create deployment user and configure SSH keys
- Trigger automated hardening via GitHub Actions
- Monitor workflow progress
- Validate infrastructure state
- Security-first approach (never logs passwords)

**Workflow**:
1. Bootstrap VPS (one-time manual step with root password)
2. Trigger GitHub Actions hardening workflow
3. Monitor progress and report status
4. Validate Docker, Caddy, firewall, Python installed

**Usage**:
```
Bootstrap VPS at 192.168.1.100 with root password <password>
```

**See**: [infrastructure-agent.md](~/.claude/skills/infrastructure-agent.md) for detailed documentation

---

**Installation**: Global skills are already installed in `~/.claude/skills/` and available everywhere.

## Support

- **Technical Issues**: Create an issue in this repository
- **Business Questions**: Contact @originate-group/devops
- **Security Issues**: Contact @originate-group/security

## License

Proprietary - Originate Group © 2025
