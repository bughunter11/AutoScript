
---

## **2. `install.sh`**
```bash
#!/bin/bash
# AutoScriptX Installer

RED='\033[0;91m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'
BLUE='\033[0;94m'; NC='\033[0m'

echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║        AutoScriptX Installer           ║"
echo "╚════════════════════════════════════════╝${NC}"
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Run as root: sudo bash install.sh${NC}" 
   exit 1
fi

# Variables
REPO_URL="https://github.com/bughunter11/AutoScript"
RAW_URL="https://raw.githubusercontent.com/bughunter11/AutoScript/main"

echo -e "${YELLOW}[1/4] Installing dependencies...${NC}"
apt-get update > /dev/null 2>&1
apt-get install -y curl wget nano > /dev/null 2>&1

echo -e "${YELLOW}[2/4] Downloading scripts...${NC}"
mkdir -p /opt/autoscriptx
mkdir -p /etc/autoscriptx
mkdir -p /var/log/autoscriptx

# Download main script
wget -q $RAW_URL/autoscriptx.sh -O /opt/autoscriptx/autoscriptx.sh
chmod +x /opt/autoscriptx/autoscriptx.sh

# Create symlink
ln -sf /opt/autoscriptx/autoscriptx.sh /usr/local/bin/autoscriptx
chmod +x /usr/local/bin/autoscriptx

# Download uninstaller
wget -q $RAW_URL/uninstall.sh -O /opt/autoscriptx/uninstall.sh
chmod +x /opt/autoscriptx/uninstall.sh

# Create alias
echo "alias vps='sudo autoscriptx'" >> ~/.bashrc
source ~/.bashrc

echo -e "${YELLOW}[3/4] Setting up configuration...${NC}"
echo "example.com" > /etc/autoscriptx/domain
echo "# Username|Password|Created|Expiry|Status" > /etc/autoscriptx/users.db
chmod 600 /etc/autoscriptx/*

echo -e "${YELLOW}[4/4] Finalizing installation...${NC}"
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║     Installation Complete!             ║"
echo "╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${GREEN}autoscriptx${NC}     - Run AutoScriptX"
echo -e "  ${GREEN}vps${NC}             - Shortcut"
echo ""
echo -e "${YELLOW}Type 'vps' to start.${NC}"
