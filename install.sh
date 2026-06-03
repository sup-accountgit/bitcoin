#!/bin/bash

# Bitcoin Core systemd Installation Script
# Run on target server with sudo

set -e

echo "========================================"
echo "Bitcoin Core systemd Installation"
echo "========================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Variables
BITCOIN_USER="bitcoin"
BITCOIN_GROUP="bitcoin"
BITCOIN_HOME="/var/lib/bitcoin"
BITCOIN_CONF_DIR="/etc/bitcoin"
BITCOIN_BIN_DIR="/usr/local/bin"

echo "[1/6] Creating bitcoin user and group..."
if ! id -u $BITCOIN_USER > /dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d $BITCOIN_HOME $BITCOIN_USER
    echo "✓ Created user: $BITCOIN_USER"
else
    echo "✓ User $BITCOIN_USER already exists"
fi

echo ""
echo "[2/6] Creating directories..."
mkdir -p $BITCOIN_HOME/wallets
mkdir -p $BITCOIN_CONF_DIR
mkdir -p /var/run/bitcoin
chown -R $BITCOIN_USER:$BITCOIN_GROUP $BITCOIN_HOME
chown -R $BITCOIN_USER:$BITCOIN_GROUP $BITCOIN_CONF_DIR
chown -R $BITCOIN_USER:$BITCOIN_GROUP /var/run/bitcoin
chmod 750 $BITCOIN_HOME
chmod 750 $BITCOIN_CONF_DIR
echo "✓ Directories created"

echo ""
echo "[3/6] Installing bitcoin.conf..."
if [ -f "./bitcoin.conf" ]; then
    cp ./bitcoin.conf $BITCOIN_CONF_DIR/bitcoin.conf
    chown $BITCOIN_USER:$BITCOIN_GROUP $BITCOIN_CONF_DIR/bitcoin.conf
    chmod 640 $BITCOIN_CONF_DIR/bitcoin.conf
    echo "✓ bitcoin.conf installed to $BITCOIN_CONF_DIR"
else
    echo "✗ bitcoin.conf not found in current directory"
    exit 1
fi

echo ""
echo "[4/6] Installing systemd service..."
if [ -f "./bitcoin.service" ]; then
    cp ./bitcoin.service /etc/systemd/system/bitcoin.service
    chmod 644 /etc/systemd/system/bitcoin.service
    systemctl daemon-reload
    echo "✓ bitcoin.service installed"
else
    echo "✗ bitcoin.service not found in current directory"
    exit 1
fi

echo ""
echo "[5/6] Verifying Bitcoin Core binary..."
if [ -f "$BITCOIN_BIN_DIR/bitcoind" ]; then
    BITCOIN_VERSION=$($BITCOIN_BIN_DIR/bitcoind --version | head -1)
    echo "✓ Bitcoin Core found: $BITCOIN_VERSION"
else
    echo "⚠ Warning: Bitcoin Core binary not found at $BITCOIN_BIN_DIR/bitcoind"
    echo "  Please ensure Bitcoin Core is installed and binaries are in $BITCOIN_BIN_DIR"
fi

echo ""
echo "[6/6] Post-installation setup..."
echo "✓ Installation complete"

echo ""
echo "========================================"
echo "Next Steps:"
echo "========================================"
echo "1. Edit the bitcoin.conf file:"
echo "   sudo nano $BITCOIN_CONF_DIR/bitcoin.conf"
echo "   - Replace \${RPC_USER} with your RPC username"
echo "   - Replace \${RPC_PASSWORD} with your RPC password"
echo ""
echo "2. Start the Bitcoin service:"
echo "   sudo systemctl start bitcoin"
echo ""
echo "3. Check service status:"
echo "   sudo systemctl status bitcoin"
echo ""
echo "4. Enable auto-start on boot:"
echo "   sudo systemctl enable bitcoin"
echo ""
echo "5. View logs:"
echo "   sudo journalctl -u bitcoin -f"
echo ""
echo "6. Test RPC connection:"
echo "   bitcoin-cli -conf=$BITCOIN_CONF_DIR/bitcoin.conf getblockchaininfo"
echo ""
echo "========================================"
