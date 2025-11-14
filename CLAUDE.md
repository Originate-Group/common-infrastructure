# common-infrastructure

## Repository Purpose

Infrastructure provisioning and hardening scripts for VPS deployments across all Originate Group projects.

## Scope

This repository contains:
- **Bootstrap scripts**: Initial VPS hardening and setup
- **Manual execution**: Scripts run via SSH by operators (not automated via GH Actions)
- **Reusable across projects**: Used by all Originate Group entities (not specific to any single business)

## Key Use Cases

1. **New VPS setup**: Harden fresh Ubuntu VPS instances
2. **SSH configuration**: Set up deployment users and SSH keys for CI/CD
3. **Security baseline**: Firewall, fail2ban, automatic updates
4. **Docker installation**: Prepare for containerized deployments
5. **1Password SSH integration**: Configure for Wayne's SSH key management

## Relationship to Other Repos

- **common-devops-agent**: CI/CD workflows that deploy TO infrastructure (runs after this repo hardens the VPS)
- **originate-keycloak-deployment**: Application deployment that requires hardened VPS
- **originate-requirements-service**: Application deployment that requires hardened VPS

## Execution Model

```
Fresh VPS
  ↓ (operator SSH access)
./scripts/harden-ubuntu-vps.sh
  ↓ (creates deployment user, SSH keys, firewall)
Hardened VPS
  ↓ (now ready for GH Actions)
Applications can deploy via CI/CD
```

## SSH Key Management

- **Operator access**: Via 1Password SSH agent (Windows-based)
- **CI/CD access**: Via GitHub Secrets (SSH_PRIVATE_KEY)
- **Never**: Store SSH keys as local files in WSL2

## Target Environments

- Ubuntu 24.04 LTS (primary)
- Ubuntu 22.04 LTS (legacy support)
- Minimum 2GB RAM for Docker-based deployments
