# Bitcoin Core Deployment Guide

This guide covers deploying Bitcoin Core with systemd management using GitHub Actions.

## Files Included

- **bitcoin.service** - systemd service unit file for Bitcoin Core
- **bitcoin.conf** - Bitcoin Core configuration file
- **install.sh** - Installation script for setting up the service
- **.github/workflows/deploy.yml** - GitHub Actions workflow for automated deployment

## Quick Start

### 1. Set Up GitHub Secrets

In your repository settings, add the following secrets:

- `RPC_USER` - RPC username for Bitcoin Core
- `RPC_PASSWORD` - RPC password (keep secure)
- `SSH_PRIVATE_KEY` - Your SSH private key for server access
- `SSH_HOST` - Target server IP or hostname
- `SSH_USER` - SSH user on target server
- `SSH_PORT` - SSH port (default: 22)

### 2. Manual Deployment

```bash
# Clone the repository
git clone https://github.com/sup-accountgit/bitcoin.git
cd bitcoin

# Copy files to your server
scp bitcoin.conf bitcoin.service install.sh user@your-server:/tmp/bitcoin-deploy/

# SSH into server and run installation
ssh user@your-server
cd /tmp/bitcoin-deploy
sudo bash install.sh
```

### 3. Configure Bitcoin

Edit the configuration file on your server:

```bash
sudo nano /etc/bitcoin/bitcoin.conf
```

Replace:
- `${RPC_USER}` with your RPC username
- `${RPC_PASSWORD}` with your secure RPC password

### 4. Start the Service

```bash
# Start Bitcoin Core
sudo systemctl start bitcoin

# Check status
sudo systemctl status bitcoin

# Enable auto-start on boot
sudo systemctl enable bitcoin

# View logs
sudo journalctl -u bitcoin -f
```

## Configuration Details

### bitcoin.service

Systemd service unit with:
- Auto-restart on failure
- Security hardening (PrivateTmp, ProtectSystem, etc.)
- Journal logging
- Proper user/group permissions

### bitcoin.conf

Key settings:
- **Network**: Configured for mainnet
- **RPC**: Bound to localhost (127.0.0.1) for security
- **Data Directory**: `/var/lib/bitcoin`
- **Logging**: Enabled with timestamps and IP logging
- **Performance**: dbcache=450, maxmempool=300

## Automated Deployment (GitHub Actions)

Push to the `deployment/systemd-github-actions` branch to trigger the workflow:

```bash
git checkout -b deployment/systemd-github-actions
git push origin deployment/systemd-github-actions
```

The workflow will:
1. Validate configuration files
2. Prepare deployment package
3. Deploy to your server (if SSH secrets are configured)
4. Generate deployment instructions

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status bitcoin

# View detailed logs
sudo journalctl -u bitcoin -n 50

# Validate configuration
bitcoind -conf=/etc/bitcoin/bitcoin.conf -datadir=/var/lib/bitcoin -testnet
```

### RPC Connection Issues

```bash
# Test RPC connection
bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf getblockchaininfo

# Check if bitcoind is listening
netstat -tuln | grep 8332
```

### Permission Issues

```bash
# Fix permissions
sudo chown -R bitcoin:bitcoin /var/lib/bitcoin
sudo chown -R bitcoin:bitcoin /etc/bitcoin
sudo chmod 750 /var/lib/bitcoin
sudo chmod 750 /etc/bitcoin
```

## Security Considerations

1. **RPC Password**: Use a strong, randomly generated password
2. **Network Access**: RPC is bound to localhost only
3. **Firewall**: Ensure port 8333 (P2P) is appropriately configured
4. **SSH Keys**: Use SSH key-based authentication, not passwords
5. **File Permissions**: Configuration files are protected (640)

## Advanced Configuration

### Enable Testnet

Edit `/etc/bitcoin/bitcoin.conf`:

```
testnet=1
rpcport=18332
```

Restart: `sudo systemctl restart bitcoin`

### Custom Data Directory

Edit `/etc/bitcoin/bitcoin.conf` and `/etc/systemd/system/bitcoin.service`:

```
datadir=/custom/path/bitcoin
```

Reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart bitcoin
```

## Support

For Bitcoin Core issues, visit: https://github.com/bitcoin/bitcoin

For deployment issues, check the GitHub Actions logs in your repository.
