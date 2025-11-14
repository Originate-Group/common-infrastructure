# GitHub Secrets and Variables Configuration

Comprehensive guide for configuring GitHub Secrets and Variables across Originate Group repositories.

## Table of Contents

- [Overview](#overview)
- [Secrets vs Variables](#secrets-vs-variables)
- [Organization-level Configuration](#organization-level-configuration)
- [Repository-level Configuration](#repository-level-configuration)
- [Configuration Guide](#configuration-guide)
- [Usage in Workflows](#usage-in-workflows)
- [Migration from Secrets to Variables](#migration-from-secrets-to-variables)
- [Security Best Practices](#security-best-practices)

## Overview

GitHub provides two mechanisms for storing configuration data:

1. **Secrets**: Encrypted storage for sensitive data (passwords, keys, tokens)
2. **Variables**: Plain text storage for non-sensitive configuration

Both support organization-level (shared) and repository-level (specific) scoping.

## Secrets vs Variables

### When to Use Secrets (Encrypted)

Use **Secrets** for sensitive data that must be protected:

- Private keys (SSH, GPG, etc.)
- Passwords and passphrases
- API tokens and credentials
- Database connection strings with passwords
- OAuth client secrets
- Encryption keys

**Characteristics:**
- Encrypted at rest
- Masked in workflow logs (shows `***`)
- Cannot be retrieved after creation (only updated)
- Requires special permissions to view/edit

### When to Use Variables (Plain Text)

Use **Variables** for non-sensitive configuration:

- Hostnames and IP addresses
- Usernames
- Port numbers
- Domain names
- Email addresses
- Environment names (prod, staging, dev)
- Feature flags
- Timeout values

**Characteristics:**
- Stored as plain text
- Visible in workflow logs
- Can be viewed/edited freely in GitHub UI
- Better UX for configuration management

### Common Misconception

**IP addresses and hostnames are NOT secret** - they are publicly routable and discoverable. Storing them as secrets provides no security benefit and makes them harder to manage.

## Organization-level Configuration

Configuration shared across all Originate Group repositories (or selected repos).

### Organization Secrets

**Location**: GitHub Organization → Settings → Secrets and variables → Actions → Secrets tab

| Name | Value | Purpose |
|------|-------|---------|
| `SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | Private key for CI/CD deployments to VPS instances |

**Scope**: All repositories (or selected repositories)

**Usage**: Authenticate GitHub Actions workflows to VPS instances as `originate-devops` user

### Organization Variables

**Location**: GitHub Organization → Settings → Secrets and variables → Actions → Variables tab

| Name | Example Value | Purpose |
|------|---------------|---------|
| `SSH_USER` | `originate-devops` | Username for CI/CD deployments (corresponds to SSH_PRIVATE_KEY) |
| `SSH_PORT` | `22` | Default SSH port (can be overridden per repo if needed) |
| `ADMIN_EMAIL` | `admin@originate.group` | Contact email for Let's Encrypt certificates |

**Scope**: All repositories

**Benefits**:
- Consistent configuration across all deployments
- Easy to update globally (e.g., change SSH_USER once, affects all repos)
- Visible in GitHub UI for verification

## Repository-level Configuration

Configuration specific to individual applications.

### Repository Variables

**Location**: Repository → Settings → Secrets and variables → Actions → Variables tab

Each application repository should set its own:

| Name | Example Value | Purpose | Notes |
|------|---------------|---------|-------|
| `VPS_HOST` | `192.168.1.100` | IP address or hostname of target VPS | Different per app if using separate VPS instances |
| `DOMAIN_NAME` | `auth.originate.group` | Public domain for the application | Used by Caddy for reverse proxy config |
| `APP_PORT` | `8080` | Internal port the application listens on | Varies by application (Keycloak: 8080, RaaS: 8000) |
| `CADDY_SNIPPET_NAME` | `keycloak` | Name for Caddy config snippet | Creates `/etc/caddy/conf.d/{name}.caddy` |

### Repository Secrets

**Location**: Repository → Settings → Secrets and variables → Actions → Secrets tab

**Generally not needed** if using organization-level `SSH_PRIVATE_KEY`.

Exceptions:
- Application-specific API keys (e.g., third-party service tokens)
- Database passwords unique to the application
- OAuth secrets for the specific app

## Configuration Guide

### Step 1: Configure Organization-level Items

**For Organization Administrators:**

1. Navigate to: `https://github.com/organizations/Originate-Group/settings/secrets/actions`

2. **Add Organization Secret** (Secrets tab):
   ```
   Name: SSH_PRIVATE_KEY
   Value: [Paste the private key content]
   Repository access: All repositories (or selected repositories)
   ```

3. **Add Organization Variables** (Variables tab):
   ```
   Name: SSH_USER
   Value: originate-devops
   Repository access: All repositories

   Name: SSH_PORT
   Value: 22
   Repository access: All repositories

   Name: ADMIN_EMAIL
   Value: admin@originate.group
   Repository access: All repositories
   ```

### Step 2: Configure Repository-level Variables

**For each application repository:**

#### Example: originate-keycloak-deployment

1. Navigate to: `https://github.com/Originate-Group/originate-keycloak-deployment/settings/variables/actions`

2. **Add Repository Variables** (Variables tab):
   ```
   Name: VPS_HOST
   Value: 192.168.1.100

   Name: DOMAIN_NAME
   Value: auth.originate.group

   Name: APP_PORT
   Value: 8080

   Name: CADDY_SNIPPET_NAME
   Value: keycloak
   ```

#### Example: originate-requirements-service

1. Navigate to: `https://github.com/Originate-Group/originate-requirements-service/settings/variables/actions`

2. **Add Repository Variables** (Variables tab):
   ```
   Name: VPS_HOST
   Value: 192.168.1.100

   Name: DOMAIN_NAME
   Value: raas.originate.group

   Name: APP_PORT
   Value: 8000

   Name: CADDY_SNIPPET_NAME
   Value: raas
   ```

### Step 3: Verify Configuration

1. Go to repository → Actions → Run workflow
2. Check workflow logs to verify values are correct
3. Variables will be visible in logs (secrets will show `***`)

## Usage in Workflows

### Accessing Organization Variables

```yaml
name: Deploy Application

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          # Organization-level variable
          username: ${{ vars.SSH_USER }}

          # Organization-level variable
          port: ${{ vars.SSH_PORT }}

          # Organization-level secret
          key: ${{ secrets.SSH_PRIVATE_KEY }}

          # Repository-level variable
          host: ${{ vars.VPS_HOST }}

          script: |
            echo "Deploying to ${{ vars.DOMAIN_NAME }}"
```

### Accessing Repository Variables

```yaml
- name: Configure Caddy
  run: |
    ssh ${{ vars.SSH_USER }}@${{ vars.VPS_HOST }} << 'EOF'
      cat > /etc/caddy/conf.d/${{ vars.CADDY_SNIPPET_NAME }}.caddy << 'CADDY'
      ${{ vars.DOMAIN_NAME }} {
          reverse_proxy localhost:${{ vars.APP_PORT }}

          header {
              Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
              X-Frame-Options "SAMEORIGIN"
              X-Content-Type-Options "nosniff"
          }

          log {
              output file /var/log/caddy/${{ vars.CADDY_SNIPPET_NAME }}-access.log
              format json
          }
      }
      CADDY

      caddy validate --config /etc/caddy/Caddyfile
      systemctl reload caddy
    EOF
```

### Environment Variables in Workflow

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest

    env:
      # Set as environment variables for easier access
      SSH_USER: ${{ vars.SSH_USER }}
      SSH_HOST: ${{ vars.VPS_HOST }}
      SSH_PORT: ${{ vars.SSH_PORT }}
      DOMAIN: ${{ vars.DOMAIN_NAME }}
      APP_PORT: ${{ vars.APP_PORT }}

    steps:
      - name: Deploy
        run: |
          echo "Deploying to $SSH_USER@$SSH_HOST:$SSH_PORT"
          echo "Domain: $DOMAIN"
          echo "App Port: $APP_PORT"
```

## Migration from Secrets to Variables

If you previously stored non-sensitive data as secrets, migrate to variables:

### Step 1: Create Variables

1. Go to repository/organization settings
2. Navigate to Secrets and variables → Actions → Variables tab
3. Create new variables with same names (or better names)

### Step 2: Update Workflows

```yaml
# OLD (using secrets)
host: ${{ secrets.SSH_HOST }}
username: ${{ secrets.SSH_USER }}
key: ${{ secrets.SSH_PRIVATE_KEY }}

# NEW (using variables for non-sensitive data)
host: ${{ vars.VPS_HOST }}
username: ${{ vars.SSH_USER }}
key: ${{ secrets.SSH_PRIVATE_KEY }}
```

### Step 3: Test Workflows

1. Run workflows to verify variables are accessible
2. Check logs to ensure values are correct
3. Verify deployments work as expected

### Step 4: Remove Old Secrets

1. Once verified, delete the old secrets
2. They'll show as undefined if accidentally referenced

## Security Best Practices

### Do's

✓ **Use secrets for actual sensitive data** (keys, passwords, tokens)
✓ **Use variables for configuration** (hostnames, ports, usernames)
✓ **Set organization-level items for shared infrastructure** (SSH_USER, SSH_PORT)
✓ **Set repository-level items for app-specific config** (VPS_HOST, DOMAIN_NAME)
✓ **Document what each secret/variable is for** (in repository docs)
✓ **Rotate secrets regularly** (especially SSH keys)
✓ **Use descriptive names** (`VPS_HOST` not `HOST`, `SSH_PRIVATE_KEY` not `KEY`)

### Don'ts

✗ **Don't store non-sensitive data as secrets** (harder to manage, no security benefit)
✗ **Don't expose secrets in logs** (use variables for visible values)
✗ **Don't share secrets between environments** (prod key ≠ dev key)
✗ **Don't hardcode secrets in workflows** (always use secrets/variables)
✗ **Don't commit secrets to git** (use .gitignore, check with git-secrets)
✗ **Don't use generic names** (`PASSWORD`, `TOKEN` - be specific)

### Audit Checklist

Periodically review your configuration:

- [ ] All sensitive data stored as secrets?
- [ ] All non-sensitive config stored as variables?
- [ ] Organization-level items properly scoped?
- [ ] Repository-specific items not duplicated at org level?
- [ ] Unused secrets/variables removed?
- [ ] Secrets rotated within last 12 months?
- [ ] Documentation up to date?

## Common Patterns

### Pattern 1: Shared Infrastructure

**Scenario**: Multiple apps deploy to same VPS

**Organization Variables:**
```
SSH_USER=originate-devops
SSH_PORT=22
```

**Organization Secrets:**
```
SSH_PRIVATE_KEY=[shared key]
```

**Repository Variables:**
```
VPS_HOST=192.168.1.100  (same for all)
DOMAIN_NAME=app1.example.com  (different per app)
APP_PORT=8080  (different per app)
```

### Pattern 2: Separate VPS per App

**Scenario**: Each app has dedicated VPS

**Organization Variables:**
```
SSH_USER=originate-devops
SSH_PORT=22
```

**Organization Secrets:**
```
SSH_PRIVATE_KEY=[shared key, authorized on all VPS]
```

**Repository Variables:**
```
VPS_HOST=192.168.1.100  (different per app)
DOMAIN_NAME=app1.example.com  (different per app)
APP_PORT=8080  (different per app)
```

### Pattern 3: Environment-specific Deployments

**Scenario**: Same app, multiple environments (staging, prod)

**Option A: Separate Workflows**
```yaml
# .github/workflows/deploy-staging.yml
env:
  VPS_HOST: ${{ vars.STAGING_VPS_HOST }}
  DOMAIN: ${{ vars.STAGING_DOMAIN }}

# .github/workflows/deploy-prod.yml
env:
  VPS_HOST: ${{ vars.PROD_VPS_HOST }}
  DOMAIN: ${{ vars.PROD_DOMAIN }}
```

**Repository Variables:**
```
STAGING_VPS_HOST=192.168.1.100
STAGING_DOMAIN=staging.example.com
PROD_VPS_HOST=192.168.1.200
PROD_DOMAIN=example.com
```

## Troubleshooting

### Variable Not Found

**Error**: `The workflow is not valid. ... 'vars.VPS_HOST' is not defined`

**Solutions:**
1. Verify variable exists in GitHub UI (Settings → Variables)
2. Check variable name spelling (case-sensitive)
3. Ensure variable is at correct level (org vs repo)
4. Verify repository has access to org-level variable

### Secret Shows in Logs

**Problem**: Value appears unmasked in workflow logs

**Cause**: Value is stored as variable, not secret

**Solution**: If truly sensitive, migrate to secret. If not sensitive, this is expected behavior for variables.

### Cannot View Secret Value

**Problem**: Need to verify secret content but can't view it

**Workaround**: Secrets can only be updated, not viewed. To verify:
1. Update workflow to test the secret (e.g., SSH connection)
2. Check workflow logs for success/failure
3. Never echo secrets directly

## Resources

- [GitHub Actions: Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions: Variables](https://docs.github.com/en/actions/learn-github-actions/variables)
- [Security Hardening for GitHub Actions](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## Support

- **Configuration Questions**: Contact @originate-group/devops
- **Access Issues**: Contact GitHub organization administrators
- **Security Concerns**: Contact @originate-group/security
