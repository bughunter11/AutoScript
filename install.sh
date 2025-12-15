#!/bin/bash
# ============================================
# 🚀 AutoScriptX Installer v4.0
# ============================================

set -e

RED='\033[0;91m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'
BLUE='\033[0;94m'; PURPLE='\033[0;95m'; CYAN='\033[0;96m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╔════════════════════════════════════════╗"
echo "║        AutoScriptX Installer           ║"
echo "╚════════════════════════════════════════╝${NC}"
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Run with: sudo bash install.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
apt-get update > /dev/null 2>&1
apt-get install -y curl wget nano > /dev/null 2>&1

echo -e "${YELLOW}[2/5] Creating directories...${NC}"
mkdir -p /opt/autoscriptx /etc/autoscriptx /var/log/autoscriptx /backup/autoscriptx

echo -e "${YELLOW}[3/5] Downloading main script...${NC}"
wget -q https://raw.githubusercontent.com/bughunter11/AutoScript/main/autoscriptx.sh -O /opt/autoscriptx/autoscriptx.sh
chmod +x /opt/autoscriptx/autoscriptx.sh

echo -e "${YELLOW}[4/5] Setting up system...${NC}"
ln -sf /opt/autoscriptx/autoscriptx.sh /usr/local/bin/autoscriptx
chmod +x /usr/local/bin/autoscriptx

# Create configs
echo "example.com" > /etc/autoscriptx/domain
echo "# Username|Password|Created|Expiry|Status" > /etc/autoscriptx/users.db
chmod 600 /etc/autoscriptx/*

# Create alias
echo "alias vps='autoscriptx'" >> ~/.bashrc
echo "alias vps='autoscriptx'" >> /root/.bashrc

echo -e "${YELLOW}[5/5] Creating uninstaller...${NC}"
cat > /opt/autoscriptx/uninstall.sh << 'EOF'
#!/bin/bash
echo "Removing AutoScriptX..."
rm -f /usr/local/bin/autoscriptx
rm -rf /opt/autoscriptx
sed -i '/alias vps=/d' ~/.bashrc /root/.bashrc
echo "Uninstalled!"
EOF
chmod +x /opt/autoscriptx/uninstall.sh

echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║        INSTALLATION COMPLETE!         ║"
echo "╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${GREEN}autoscriptx${NC}     - Run script"
echo -e "  ${GREEN}vps${NC}             - Shortcut"
echo ""
echo -e "${YELLOW}Run: source ~/.bashrc && autoscriptx${NC}"
