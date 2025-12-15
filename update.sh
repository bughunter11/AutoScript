#!/bin/bash
# AutoScriptX Update Script

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
NC='\033[0m'

echo -e "${YELLOW}[*] Checking for updates...${NC}"

RAW_URL="https://raw.githubusercontent.com/bughunter11/AutoScript/main"

# Backup current version
BACKUP_DIR="/backup/autoscriptx"
mkdir -p $BACKUP_DIR
cp /opt/autoscriptx/autoscriptx.sh "$BACKUP_DIR/backup_$(date +%Y%m%d).sh"

# Download new version
echo -e "${YELLOW}[*] Downloading update...${NC}"
wget -q $RAW_URL/autoscriptx.sh -O /tmp/autoscriptx_new.sh

if [ $? -eq 0 ]; then
    # Compare versions
    OLD_VER=$(grep "Version:" /opt/autoscriptx/autoscriptx.sh | head -1 | awk '{print $3}')
    NEW_VER=$(grep "Version:" /tmp/autoscriptx_new.sh | head -1 | awk '{print $3}')
    
    echo -e "${GREEN}Current: $OLD_VER${NC}"
    echo -e "${GREEN}New: $NEW_VER${NC}"
    
    if [ "$OLD_VER" != "$NEW_VER" ]; then
        echo -e "${YELLOW}[*] Updating to version $NEW_VER...${NC}"
        mv /tmp/autoscriptx_new.sh /opt/autoscriptx/autoscriptx.sh
        chmod +x /opt/autoscriptx/autoscriptx.sh
        echo -e "${GREEN}✅ Update successful!${NC}"
    else
        echo -e "${YELLOW}⚠ Already up to date${NC}"
        rm /tmp/autoscriptx_new.sh
    fi
else
    echo -e "${RED}❌ Update failed! Check internet connection.${NC}"
fi

echo -e "${YELLOW}[*] Update completed.${NC}"
