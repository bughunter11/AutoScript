#!/bin/bash
# ==============================================
# 🚀 AutoScriptX - Complete All-in-One Installer
# GitHub: https://github.com/bughunter11/AutoScript
# ==============================================

set -e

# Colors
RED='\033[0;91m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'
BLUE='\033[0;94m'; PURPLE='\033[0;95m'; CYAN='\033[0;96m'
NC='\033[0m'

# Banner
echo -e "${PURPLE}"
echo "╔════════════════════════════════════════╗"
echo "║        AutoScriptX Installer           ║"
echo "║      One-Command Complete Setup        ║"
echo "╚════════════════════════════════════════╝${NC}"
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Run as root: sudo bash <(curl -s ...)${NC}"
    exit 1
fi

# Main installation function
install_autoscriptx() {
    echo -e "${CYAN}[1/5] Creating directories...${NC}"
    
    # Create all necessary directories
    mkdir -p /opt/autoscriptx
    mkdir -p /etc/autoscriptx
    mkdir -p /var/log/autoscriptx
    mkdir -p /backup/autoscriptx
    mkdir -p /opt/autoscriptx/modules
    
    # Create main script
    echo -e "${CYAN}[2/5] Creating main script...${NC}"
    cat > /opt/autoscriptx/autoscriptx.sh << 'EOF'
#!/bin/bash
# ==============================================
# 🚀 AutoScriptX - VPS Manager
# Version: 2.0
# ==============================================

# Colors
P="\033[35m"; B="\033[36m"; G="\033[32m"
Y="\033[33m"; R="\033[31m"; N="\033[0m"

# Config
CONFIG_DIR="/etc/autoscriptx"
DOMAIN_FILE="$CONFIG_DIR/domain"
USER_DB="$CONFIG_DIR/users.db"
LOG_FILE="/var/log/autoscriptx/activity.log"

# Initialize
init() {
    [[ ! -f $DOMAIN_FILE ]] && echo "example.com" > $DOMAIN_FILE
    [[ ! -f $USER_DB ]] && echo "# Username|Password|Created|Expiry|Status" > $USER_DB
}

# Display header
show_header() {
    clear
    echo -e "${P}# 🚀 AutoScriptX - VPS Manager${N}\n"
    echo -e "${B}• OS${N}        : $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${B}• Uptime${N}    : $(uptime -p)"
    echo -e "${B}• IP${N}        : $(curl -s ifconfig.me || echo 'N/A')"
    echo -e "${B}• Domain${N}    : $(cat $DOMAIN_FILE 2>/dev/null || echo 'not-set')"
    echo ""
}

# User functions
create_user() {
    echo -e "\n${G}CREATE USER${N}"
    read -p "Username: " u
    read -p "Password: " p
    read -p "Expiry (days): " d
    
    useradd -m $u
    echo "$u:$p" | chpasswd
    
    if [[ $d -gt 0 ]]; then
        chage -E $(date -d "+$d days" +%F) $u
    fi
    
    echo "$u|$p|$(date +%Y-%m-%d)|$([[ $d -gt 0 ]] && date -d "+$d days" +%Y-%m-%d || echo "Never")|Active" >> $USER_DB
    
    echo -e "${G}✅ User created${N}"
    read -p "Press Enter..."
}

delete_user() {
    echo -e "\n${R}DELETE USER${N}"
    read -p "Username: " u
    
    if ! id "$u" &>/dev/null; then
        echo -e "${R}❌ User not found${N}"
        read -p "Press Enter..."
        return
    fi
    
    echo -e "${Y}⚠ Delete user $u? (y/N): ${N}"
    read confirm
    if [[ $confirm == "y" || $confirm == "Y" ]]; then
        userdel -r $u
        sed -i "/^$u|/d" $USER_DB
        echo -e "${G}✅ User deleted${N}"
    else
        echo -e "${Y}❌ Cancelled${N}"
    fi
    read -p "Press Enter..."
}

list_users() {
    echo -e "\n${B}📋 USER LIST${N}"
    echo "================================="
    printf "%-15s %-12s %-12s\n" "Username" "Created" "Expiry"
    echo "---------------------------------"
    
    tail -n +2 $USER_DB 2>/dev/null | while IFS='|' read -r user pass created expiry status; do
        printf "%-15s %-12s %-12s\n" "$user" "$created" "$expiry"
    done
    
    echo -e "\nTotal: $(($(wc -l < $USER_DB 2>/dev/null || echo 1) - 1)) users"
    read -p "Press Enter..."
}

# Service manager
service_manager() {
    while true; do
        clear
        echo -e "${B}⚙️ SERVICE MANAGER${N}"
        echo "1) Restart SSH"
        echo "2) Restart Nginx"
        echo "3) Restart Xray"
        echo "4) Restart All"
        echo "5) Check Status"
        echo "0) Back"
        
        read -p "> " choice
        
        case $choice in
            1) systemctl restart ssh; echo "SSH restarted" ;;
            2) systemctl restart nginx; echo "Nginx restarted" ;;
            3) systemctl restart xray; echo "Xray restarted" ;;
            4) systemctl restart ssh nginx xray; echo "All services restarted" ;;
            5) 
                echo -e "\n${G}Service Status:${N}"
                systemctl is-active ssh &>/dev/null && echo "✅ SSH: Running" || echo "❌ SSH: Stopped"
                systemctl is-active nginx &>/dev/null && echo "✅ Nginx: Running" || echo "❌ Nginx: Stopped"
                systemctl is-active xray &>/dev/null && echo "✅ Xray: Running" || echo "❌ Xray: Stopped"
                ;;
            0) return ;;
        esac
        [[ $choice -ne 0 ]] && read -p "Press Enter..."
    done
}

# System info
system_info() {
    clear
    echo -e "${B}🖥️ SYSTEM INFORMATION${N}"
    echo "================================="
    echo -e "${G}Hostname:${N} $(hostname)"
    echo -e "${G}Kernel:${N} $(uname -r)"
    echo -e "${G}Architecture:${N} $(uname -m)"
    echo ""
    
    echo -e "${G}Memory Usage:${N}"
    free -h
    
    echo -e "\n${G}Disk Usage:${N}"
    df -h
    
    echo -e "\n${G}CPU Info:${N}"
    lscpu | grep "Model name" | cut -d':' -f2 | xargs
    
    read -p "Press Enter..."
}

# Domain setup
domain_setup() {
    current=$(cat $DOMAIN_FILE 2>/dev/null || echo "not-set")
    echo -e "\n${B}🌐 DOMAIN SETUP${N}"
    echo "Current: $current"
    read -p "New domain: " new_domain
    
    if [[ -n $new_domain ]]; then
        echo "$new_domain" > $DOMAIN_FILE
        echo -e "${G}✅ Domain updated${N}"
    else
        echo -e "${R}❌ Invalid domain${N}"
    fi
    read -p "Press Enter..."
}

# Main menu
main_menu() {
    init
    while true; do
        show_header
        
        echo -e "${P}# 📋 MAIN MENU${N}\n"
        echo -e "${G}1.${N} Create User"
        echo -e "${G}2.${N} Delete User"
        echo -e "${G}3.${N} List Users"
        echo -e "${G}4.${N} Renew User"
        echo -e "${G}5.${N} Service Manager"
        echo -e "${G}6.${N} System Info"
        echo -e "${G}7.${N} Domain Setup"
        echo -e "${G}8.${N} Backup Tools"
        echo -e "${G}9.${N} Security Check"
        echo -e "${R}0.${N} Exit"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) create_user ;;
            2) delete_user ;;
            3) list_users ;;
            4) renew_user ;;
            5) service_manager ;;
            6) system_info ;;
            7) domain_setup ;;
            8) backup_tools ;;
            9) security_check ;;
            0) 
                echo -e "${G}Goodbye! 👋${N}"
                exit 0
                ;;
            *) 
                echo -e "${R}Invalid option${N}"
                sleep 1
                ;;
        esac
    done
}

# Placeholder functions
renew_user() {
    echo -e "${Y}Feature coming soon${N}"
    read -p "Press Enter..."
}

backup_tools() {
    echo -e "${Y}Backup tools - coming soon${N}"
    read -p "Press Enter..."
}

security_check() {
    echo -e "\n${B}🛡️ SECURITY CHECK${N}"
    echo "Open ports:"
    ss -tulpn | grep LISTEN | head -10
    echo -e "\nFailed SSH logins (last 5):"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 || echo "No failed logins"
    read -p "Press Enter..."
}

# Start
main_menu
EOF
    
    chmod +x /opt/autoscriptx/autoscriptx.sh
    
    echo -e "${CYAN}[3/5] Creating system links...${NC}"
    
    # Create symlink
    ln -sf /opt/autoscriptx/autoscriptx.sh /usr/local/bin/autoscriptx
    chmod +x /usr/local/bin/autoscriptx
    
    # Create alias
    echo "alias vps='autoscriptx'" >> ~/.bashrc
    echo "alias vps='autoscriptx'" >> /root/.bashrc
    
    # Create config files
    echo "example.com" > /etc/autoscriptx/domain
    echo "# Username|Password|Created|Expiry|Status" > /etc/autoscriptx/users.db
    chmod 600 /etc/autoscriptx/*
    
    echo -e "${CYAN}[4/5] Installing dependencies...${NC}"
    
    # Install basic tools
    apt-get update > /dev/null 2>&1
    apt-get install -y curl wget nano htop net-tools > /dev/null 2>&1
    
    # Create update script
    cat > /opt/autoscriptx/update.sh << 'EOF'
#!/bin/bash
echo "AutoScriptX - Update Tool"
echo "Checking GitHub for updates..."
# Update logic here
echo "Update system coming soon"
EOF
    chmod +x /opt/autoscriptx/update.sh
    
    echo -e "${CYAN}[5/5] Finalizing installation...${NC}"
    
    # Set permissions
    chown -R root:root /opt/autoscriptx
    chmod -R 750 /opt/autoscriptx
    
    # Reload bashrc
    source ~/.bashrc 2>/dev/null || true
    
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════╗"
    echo "║     INSTALLATION COMPLETE!            ║"
    echo "╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}🚀 Quick Start:${NC}"
    echo -e "  ${GREEN}autoscriptx${NC}     - Run AutoScriptX"
    echo -e "  ${GREEN}vps${NC}             - Shortcut (after restart)"
    echo ""
    echo -e "${YELLOW}📌 First run command:${NC}"
    echo -e "  ${CYAN}source ~/.bashrc && autoscriptx${NC}"
    echo ""
    echo -e "${BLUE}📁 Files installed at:${NC}"
    echo -e "  ${CYAN}/opt/autoscriptx/${NC}"
    echo -e "  ${CYAN}/etc/autoscriptx/${NC}"
    echo ""
}

# Main execution
echo -e "${YELLOW}AutoScriptX will be installed on your system.${NC}"
read -p "Continue? [Y/n]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

install_autoscriptx

# Run the script
echo -e "\n${GREEN}Starting AutoScriptX...${NC}"
echo -e "${YELLOW}If script doesn't start automatically, run:${NC}"
echo -e "${CYAN}  autoscriptx${NC}"
echo ""

# Start script
autoscriptx
