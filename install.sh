#!/bin/bash
set -e

# FastProbe Client Installation Script

# Define installation paths
BIN_DIR="/usr/local/bin"
CONF_DIR="/etc/fastprobe-client"
CONF_FILE="$CONF_DIR/config.json"
SERVICE_FILE="/etc/systemd/system/fastprobe-client.service"
BIN_NAME="fastprobe-client"

echo "====================================="
echo " FastProbe Client Installation"
echo "====================================="

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or using sudo)."
  exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)
    RELEASE_ARCH="amd64"
    ;;
  aarch64|arm64)
    RELEASE_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

OS="linux"
REPO="luoxufeiyan/FastProbeClient"

install_or_upgrade() {
    local mode=$1
    echo "Fetching latest release information..."
    LATEST_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest | grep "browser_download_url" | grep "fastprobe-client-$OS-$RELEASE_ARCH" | cut -d '"' -f 4)

    if [ -z "$LATEST_URL" ]; then
        # Fallback to constructing URL if github API rate limited or no release yet
        echo "Could not find latest release via API, assuming v1.0.0 for fallback (you may need to install manually if this fails)."
        LATEST_URL="https://github.com/$REPO/releases/latest/download/fastprobe-client-$OS-$RELEASE_ARCH"
    fi

    echo "Downloading $LATEST_URL..."
    
    if [ "$mode" == "upgrade" ]; then
        systemctl stop fastprobe-client || true
    fi

    curl -L -o "$BIN_DIR/$BIN_NAME" "$LATEST_URL"
    chmod +x "$BIN_DIR/$BIN_NAME"

    echo "Binary installed to $BIN_DIR/$BIN_NAME"
    
    if [ "$mode" == "install" ]; then
        # Prompt for configuration
        echo "-------------------------------------"
        echo " Configuration"
        echo "-------------------------------------"
        read -p "Enter FastProbe Server URL (e.g., https://status.yourdomain.com/report): " SERVER_URL
        read -p "Enter your Node Token: " NODE_TOKEN

        mkdir -p "$CONF_DIR"

        # Create config.json
        cat > "$CONF_FILE" <<EOF
{
  "url": "$SERVER_URL",
  "token": "$NODE_TOKEN"
}
EOF
        echo "Configuration saved to $CONF_FILE"

        # Create systemd service
        echo "Setting up systemd service..."

        cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=FastProbe Client Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$BIN_DIR/$BIN_NAME -config $CONF_FILE
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable fastprobe-client
        systemctl start fastprobe-client
        echo "====================================="
        echo " Installation Complete!"
        echo " FastProbe Client is now running."
        echo " You can check the status with: systemctl status fastprobe-client"
        echo "====================================="
    else
        systemctl daemon-reload
        systemctl start fastprobe-client
        echo "====================================="
        echo " Upgrade Complete!"
        echo " FastProbe Client is now running."
        echo "====================================="
    fi
}

uninstall() {
    echo "Uninstalling FastProbe Client..."
    systemctl stop fastprobe-client || true
    systemctl disable fastprobe-client || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    rm -f "$BIN_DIR/$BIN_NAME"
    
    read -p "Do you want to remove the configuration directory ($CONF_DIR)? [y/N]: " REMOVE_CONF
    if [[ "$REMOVE_CONF" =~ ^[Yy]$ ]]; then
        rm -rf "$CONF_DIR"
        echo "Configuration removed."
    fi
    echo "====================================="
    echo " Uninstallation Complete!"
    echo "====================================="
}

# Check if already installed
if [ -f "$BIN_DIR/$BIN_NAME" ]; then
    VERSION=$("$BIN_DIR/$BIN_NAME" -v 2>/dev/null || echo "Unknown/Old version")
    echo "FastProbe Client is already installed."
    echo "Current Version: $VERSION"
    echo "-------------------------------------"
    echo "Select an action:"
    echo "  1) Upgrade to the latest version"
    echo "  2) Uninstall"
    echo "  3) Cancel"
    read -p "Enter your choice [1-3]: " CHOICE

    case "$CHOICE" in
        1)
            install_or_upgrade "upgrade"
            ;;
        2)
            uninstall
            ;;
        *)
            echo "Operation cancelled."
            exit 0
            ;;
    esac
else
    echo "FastProbe Client is not installed."
    read -p "Do you want to install it now? [Y/n]: " CHOICE_INSTALL
    if [[ "$CHOICE_INSTALL" =~ ^[Nn]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
    install_or_upgrade "install"
fi
