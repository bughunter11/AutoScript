#!/bin/bash
# AutoScriptX Uninstaller

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
NC='\033[0m'

echo -e "${YELLOW}AutoScriptX Uninstaller${NC}"
read -p "Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Cancelled${NC}"
    exit 0
fi

echo "Removing AutoScriptX..."

# Remove symlink
rm -f /usr/local/bin/autoscriptx

# Remove alias
sed -i '/alias vps=/d' ~/.bashrc /root/.bashrc 2>/dev/null

# Ask about directories
echo -e "${YELLOW}Remove directories? (y/N): ${NC}"
read remove_dirs

if [[ $remove_dirs == "y" ]]; then
    rm -rf /opt/autoscriptx /etc/autoscriptx /var/log/autoscriptx
    echo -e "${GREEN}Directories removed${NC}"
fi

echo -e "${GREEN}✅ Uninstalled!${NC}"
