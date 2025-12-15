#!/bin/bash
# AutoScriptX Uninstaller

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
NC='\033[0m'

echo -e "${YELLOW}Are you sure you want to uninstall AutoScriptX?${NC}"
read -p "Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}Uninstallation cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}[*] Uninstalling AutoScriptX...${NC}"

# Remove symlink
rm -f /usr/local/bin/autoscriptx

# Remove alias from bashrc
sed -i '/alias vps=/d' ~/.bashrc 2>/dev/null
sed -i '/alias vps=/d' /root/.bashrc 2>/dev/null

# Remove directories (with confirmation)
echo -e "${YELLOW}[*] Removing directories...${NC}"
echo "The following directories will be removed:"
echo "  /opt/autoscriptx"
echo "  /etc/autoscriptx"
echo "  /var/log/autoscriptx"
read -p "Remove these directories? (y/N): " remove_dirs

if [[ $remove_dirs == "y" || $remove_dirs == "Y" ]]; then
    rm -rf /opt/autoscriptx
    rm -rf /etc/autoscriptx
    rm -rf /var/log/autoscriptx
    echo -e "${GREEN}✅ Directories removed${NC}"
else
    echo -e "${YELLOW}⚠ Directories kept${NC}"
fi

echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║     Uninstallation Complete!           ║"
echo "╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Note: User accounts and service configurations were not removed.${NC}"
echo -e "${YELLOW}To completely remove, run:${NC}"
echo -e "  ${RED}rm -rf /backup/autoscriptx${NC}"
