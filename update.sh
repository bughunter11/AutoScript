#!/bin/bash
# AutoScriptX Update Script

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;93m'
NC='\033[0m'

echo -e "${YELLOW}Updating AutoScriptX...${NC}"

# Backup current
BACKUP_DIR="/backup/autoscriptx"
mkdir -p $BACKUP_DIR
cp /opt/autoscriptx/autoscriptx.sh "$BACKUP_DIR/backup_$(date +%Y%m%d).sh"

# Download new version
echo "Downloading update..."
wget -q https://raw.githubusercontent.com/bughunter11/AutoScript/main/autoscriptx.sh -O /tmp/autoscriptx_new.sh

if [ $? -eq 0 ]; then
    mv /tmp/autoscriptx_new.sh /opt/autoscriptx/autoscriptx.sh
    chmod +x /opt/autoscriptx/autoscriptx.sh
    echo -e "${GREEN}✅ Update successful!${NC}"
else
    echo -e "${RED}❌ Update failed!${NC}"
fi
