#!/bin/bash
# ==============================================
# 🚀 AutoScriptX Pro - Complete VPS Manager
# Version: 4.0 (With SlowDNS)
# ==============================================

# ---- CONFIGURATION ----
CONFIG_DIR="/etc/autoscriptx"
DOMAIN_FILE="$CONFIG_DIR/domain"
USER_DB="$CONFIG_DIR/users.db"
LOG_FILE="/var/log/autoscriptx.log"
BACKUP_DIR="/backup/autoscriptx"
BANNER_FILE="/etc/issue.net"
SLOWDNS_DIR="/etc/slowdns"

# ---- COLORS ----
RED='\033[0;91m'; GREEN='\033[0;92m'; YELLOW='\033[0;93m'
BLUE='\033[0;94m'; PURPLE='\033[0;95m'; CYAN='\033[0;96m'
WHITE='\033[0;97m'; BOLD='\033[1m'; NC='\033[0m'
LINE="════════════════════════════════════════════════"

# ---- INITIALIZE ----
init() {
    mkdir -p $CONFIG_DIR $BACKUP_DIR $SLOWDNS_DIR
    [[ ! -f $DOMAIN_FILE ]] && echo "example.com" > $DOMAIN_FILE
    [[ ! -f $USER_DB ]] && echo "# Username|Password|Created|Expiry|Status" > $USER_DB
    [[ ! -f $LOG_FILE ]] && touch $LOG_FILE
}

# ---- HEADER ----
show_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║              🚀 AutoScriptX Pro                ║"
    echo "║           Complete VPS Manager v4.0           ║"
    echo "║              (With SlowDNS Support)           ║"
    echo "╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # System Info
    echo -e "${CYAN}${BOLD}📊 SYSTEM OVERVIEW${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    OS=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    UPTIME=$(uptime -p | sed 's/up //')
    IP=$(curl -s --max-time 2 ifconfig.me || echo "Not available")
    DOMAIN=$(cat $DOMAIN_FILE 2>/dev/null || echo "not-set")
    
    echo -e "${B}• OS${N}        : $OS"
    echo -e "${B}• Uptime${N}    : $UPTIME"
    echo -e "${B}• Public IP${N} : $IP"
    echo -e "${B}• Domain${N}    : $DOMAIN"
    echo ""
    
    # RAM Info
    echo -e "${CYAN}${BOLD}🧠 RAM INFORMATION${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
    TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
    RAM_PERCENT=$((USED_RAM * 100 / TOTAL_RAM 2>/dev/null || echo 0))
    
    echo -e "${B}• Used RAM${N}  : ${USED_RAM} MB"
    echo -e "${B}• Total RAM${N} : ${TOTAL_RAM} MB"
    echo -e "${B}• Usage${N}     : ${RAM_PERCENT}%"
    echo ""
}

# ---- PAUSE FUNCTION ----
pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# ---- OPTION 1: CREATE ACCOUNT ----
create_account() {
    clear
    echo -e "${PURPLE}${BOLD}👤 CREATE NEW ACCOUNT${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    while true; do
        read -p "Username: " username
        
        if [[ -z "$username" ]]; then
            echo -e "${RED}Username cannot be empty!${NC}"
            continue
        fi
        
        if id "$username" &>/dev/null; then
            echo -e "${RED}User '$username' already exists!${NC}"
            continue
        fi
        
        break
    done
    
    # Password
    while true; do
        read -sp "Password: " password
        echo
        read -sp "Confirm Password: " password2
        echo
        
        if [[ "$password" != "$password2" ]]; then
            echo -e "${RED}Passwords do not match!${NC}"
        elif [[ ${#password} -lt 6 ]]; then
            echo -e "${RED}Password must be at least 6 characters!${NC}"
        else
            break
        fi
    done
    
    # Expiry
    read -p "Expiry (days, 0 for no expiry): " days
    
    # Create user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiry
    if [[ $days -gt 0 ]]; then
        expiry_date=$(date -d "+$days days" +%Y-%m-%d)
        chage -E "$expiry_date" "$username"
    else
        expiry_date="Never"
    fi
    
    # Add to database
    created_date=$(date +%Y-%m-%d)
    echo -e "$username|$password|$created_date|$expiry_date|Active" >> $USER_DB
    
    # Create default services
    create_default_services "$username" "$password"
    
    echo -e "\n${GREEN}✅ ACCOUNT CREATED SUCCESSFULLY${NC}"
    echo -e "${CYAN}Username:${NC} $username"
    echo -e "${CYAN}Password:${NC} $password"
    echo -e "${CYAN}Expiry:${NC} $expiry_date"
    echo -e "${CYAN}Home Dir:${NC} /home/$username"
    echo -e "${CYAN}SSH Port:${NC} 22"
    echo -e "${CYAN}SlowDNS:${NC} Installed (Port 5300)"
    
    pause
}

# ---- CREATE DEFAULT SERVICES ----
create_default_services() {
    local username=$1
    local password=$2
    
    # Create SSH config
    mkdir -p /home/$username/.ssh
    echo "# AutoScriptX Configuration" > /home/$username/.ssh/config
    
    # Create service info file
    cat > /home/$username/service_info.txt << EOF
╔════════════════════════════════════════════════╗
║            ACCOUNT INFORMATION                 ║
╚════════════════════════════════════════════════╝

Username: $username
Password: $password
Created: $(date)
Expiry: $expiry_date

╔════════════════════════════════════════════════╗
║               SERVICE PORTS                    ║
╚════════════════════════════════════════════════╝

SSH Port: 22
SlowDNS Port: 5300
HTTP Proxy: 3128
SOCKS5: 1080

╔════════════════════════════════════════════════╗
║               CONNECTION INFO                  ║
╚════════════════════════════════════════════════╝

IP: $(curl -s ifconfig.me)
Domain: $(cat $DOMAIN_FILE 2>/dev/null || echo "not-set")

╔════════════════════════════════════════════════╗
║                 IMPORTANT                      ║
╚════════════════════════════════════════════════╝

1. Change password after first login
2. Do not share credentials
3. Contact support for issues

EOF
}

# ---- OPTION 2: DELETE ACCOUNT ----
delete_account() {
    clear
    echo -e "${PURPLE}${BOLD}🗑️ DELETE ACCOUNT${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    read -p "Enter username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User '$username' not found!${NC}"
        pause
        return
    fi
    
    echo -e "\n${YELLOW}User Information:${NC}"
    echo "Username: $username"
    echo "Home Directory: /home/$username"
    
    echo -e "\n${RED}⚠ WARNING: This will delete user and all their data!${NC}"
    read -p "Type 'DELETE' to confirm: " confirm
    
    if [[ "$confirm" == "DELETE" ]]; then
        # Backup home directory
        backup_file="$BACKUP_DIR/${username}_$(date +%Y%m%d).tar.gz"
        tar -czf "$backup_file" /home/"$username" 2>/dev/null
        
        # Delete user
        userdel -r "$username"
        
        # Remove from database
        sed -i "/^$username|/d" "$USER_DB"
        
        echo -e "\n${GREEN}✅ USER DELETED SUCCESSFULLY${NC}"
        echo -e "${CYAN}Backup saved to:${NC} $backup_file"
    else
        echo -e "${YELLOW}❌ Deletion cancelled${NC}"
    fi
    
    pause
}

# ---- OPTION 3: RENEW ACCOUNT ----
renew_account() {
    clear
    echo -e "${PURPLE}${BOLD}🔄 RENEW ACCOUNT${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    read -p "Enter username to renew: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User '$username' not found!${NC}"
        pause
        return
    fi
    
    # Show current expiry
    current_expiry=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
    echo -e "${CYAN}Current Expiry:${NC} $current_expiry"
    
    read -p "Extend by how many days? : " days
    
    if [[ $days -gt 0 ]]; then
        if [[ "$current_expiry" == "never" ]] || [[ "$current_expiry" == "Never" ]]; then
            # If never expired, set from today
            expiry_date=$(date -d "+$days days" +%Y-%m-%d)
        else
            # If already has expiry, extend from that date
            expiry_date=$(date -d "$current_expiry + $days days" +%Y-%m-%d 2>/dev/null || date -d "+$days days" +%Y-%m-%d)
        fi
        
        chage -E "$expiry_date" "$username"
        
        # Update database
        sed -i "/^$username|/d" "$USER_DB"
        echo -e "$username|$(grep "^$username|" $USER_DB 2>/dev/null | cut -d'|' -f2)|$(date +%Y-%m-%d)|$expiry_date|Active" >> $USER_DB
        
        echo -e "\n${GREEN}✅ ACCOUNT RENEWED SUCCESSFULLY${NC}"
        echo -e "${CYAN}New Expiry Date:${NC} $expiry_date"
    else
        echo -e "${RED}❌ Invalid number of days!${NC}"
    fi
    
    pause
}

# ---- OPTION 4: LOCK/UNLOCK ACCOUNT ----
lock_unlock_account() {
    clear
    echo -e "${PURPLE}${BOLD}🔒 LOCK/UNLOCK ACCOUNT${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    read -p "Enter username: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User '$username' not found!${NC}"
        pause
        return
    fi
    
    # Check current status
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then
        echo -e "${YELLOW}Current Status: LOCKED${NC}"
        echo -e "\n1) Unlock Account"
        echo "2) Keep Locked"
        read -p "Choose: " choice
        
        if [[ $choice == "1" ]]; then
            passwd -u "$username"
            echo -e "${GREEN}✅ ACCOUNT UNLOCKED${NC}"
        fi
    else
        echo -e "${GREEN}Current Status: UNLOCKED${NC}"
        echo -e "\n1) Lock Account"
        echo "2) Keep Unlocked"
        read -p "Choose: " choice
        
        if [[ $choice == "1" ]]; then
            passwd -l "$username"
            echo -e "${RED}🔒 ACCOUNT LOCKED${NC}"
        fi
    fi
    
    pause
}

# ---- OPTION 5: EDIT BANNER ----
edit_banner() {
    clear
    echo -e "${PURPLE}${BOLD}📝 EDIT SSH BANNER${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    echo -e "${YELLOW}Current banner is stored at: /etc/issue.net${NC}"
    echo -e "\nOptions:"
    echo "1) Edit with nano"
    echo "2) Set default banner"
    echo "3) View current banner"
    echo "0) Back"
    
    read -p "Choose: " choice
    
    case $choice in
        1)
            nano /etc/issue.net
            systemctl restart ssh
            echo -e "${GREEN}✅ Banner updated and SSH restarted${NC}"
            ;;
        2)
            cat > /etc/issue.net << 'EOF'
╔════════════════════════════════════════════════╗
║            🚀 WELCOME TO SERVER                ║
║         AutoScriptX Managed System             ║
║                                                ║
║   █████╗ ██╗   ██╗████████╗ ██████╗           ║
║  ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗          ║
║  ███████║██║   ██║   ██║   ██║   ██║          ║
║  ██╔══██║██║   ██║   ██║   ██║   ██║          ║
║  ██║  ██║╚██████╔╝   ██║   ╚██████╔╝          ║
║  ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝           ║
║                                                ║
║    Unauthorized access is prohibited!          ║
╚════════════════════════════════════════════════╝

Server: $(hostname)
IP: $(hostname -I | awk '{print $1}')
Date: $(date)
Uptime: $(uptime -p)
Users: $(who | wc -l)

EOF
            systemctl restart ssh
            echo -e "${GREEN}✅ Default banner set and SSH restarted${NC}"
            ;;
        3)
            echo -e "\n${CYAN}CURRENT BANNER:${NC}"
            echo "════════════════════════════════════════"
            cat /etc/issue.net
            echo "════════════════════════════════════════"
            ;;
        0)
            return
            ;;
    esac
    
    pause
}

# ---- OPTION 6: EDIT 101 RESPONSE ----
edit_101_response() {
    clear
    echo -e "${PURPLE}${BOLD}🌐 EDIT 101 RESPONSE PAGE${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    mkdir -p /var/www/html
    
    echo -e "The 101 response page is shown when connection is established."
    echo -e "Location: /var/www/html/101.html"
    echo -e "\nOptions:"
    echo "1) Edit with nano"
    echo "2) Set default page"
    echo "3) View current page"
    echo "0) Back"
    
    read -p "Choose: " choice
    
    case $choice in
        1)
            nano /var/www/html/101.html
            echo -e "${GREEN}✅ 101 Response page updated${NC}"
            ;;
        2)
            cat > /var/www/html/101.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Connection Established - AutoScriptX</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            text-align: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
            max-width: 600px;
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            color: #00ff88;
            text-shadow: 0 0 10px rgba(0, 255, 136, 0.5);
        }
        h2 {
            font-size: 2em;
            margin-bottom: 30px;
        }
        .status {
            font-size: 5em;
            margin: 20px 0;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.7; }
            100% { opacity: 1; }
        }
        .info-box {
            background: rgba(0, 0, 0, 0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
            text-align: left;
        }
        .server-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 20px;
        }
        .info-item {
            background: rgba(255, 255, 255, 0.1);
            padding: 10px;
            border-radius: 5px;
        }
        .success {
            color: #00ff88;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="status">✅</div>
        <h1>CONNECTION SUCCESSFUL</h1>
        <h2>AutoScriptX VPS Manager</h2>
        
        <div class="info-box">
            <p class="success">✓ Your connection has been established successfully!</p>
            <p>All systems are operational and ready to use.</p>
        </div>
        
        <div class="server-info">
            <div class="info-item">
                <strong>Server:</strong><br>
                <span id="server">Loading...</span>
            </div>
            <div class="info-item">
                <strong>Status:</strong><br>
                <span class="success">Online</span>
            </div>
            <div class="info-item">
                <strong>Date & Time:</strong><br>
                <span id="datetime">Loading...</span>
            </div>
            <div class="info-item">
                <strong>Uptime:</strong><br>
                <span id="uptime">Loading...</span>
            </div>
        </div>
        
        <p style="margin-top: 30px; font-size: 0.9em; opacity: 0.8;">
            Managed by AutoScriptX Pro | Version 4.0
        </p>
    </div>
    
    <script>
        document.getElementById('server').textContent = window.location.hostname;
        
        function updateDateTime() {
            const now = new Date();
            document.getElementById('datetime').textContent = 
                now.toLocaleDateString() + ' ' + now.toLocaleTimeString();
        }
        updateDateTime();
        setInterval(updateDateTime, 1000);
        
        // Simulate uptime
        let seconds = 0;
        setInterval(() => {
            seconds++;
            const hours = Math.floor(seconds / 3600);
            const minutes = Math.floor((seconds % 3600) / 60);
            const secs = seconds % 60;
            document.getElementById('uptime').textContent = 
                `${hours}h ${minutes}m ${secs}s`;
        }, 1000);
    </script>
</body>
</html>
EOF
            echo -e "${GREEN}✅ Default 101 page created${NC}"
            ;;
        3)
            if [[ -f /var/www/html/101.html ]]; then
                echo -e "\n${CYAN}CURRENT 101 PAGE:${NC}"
                echo "════════════════════════════════════════"
                cat /var/www/html/101.html | head -50
                echo "════════════════════════════════════════"
                echo -e "\n${YELLOW}(Showing first 50 lines)${NC}"
            else
                echo -e "${RED}❌ 101 page not found!${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    
    pause
}

# ---- OPTION 7: CHANGE DOMAIN ----
change_domain() {
    clear
    echo -e "${PURPLE}${BOLD}🌐 CHANGE DOMAIN${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    current_domain=$(cat $DOMAIN_FILE 2>/dev/null || echo "not-set")
    echo -e "${CYAN}Current Domain:${NC} $current_domain"
    
    read -p "Enter new domain (e.g., example.com): " new_domain
    
    if [[ -n "$new_domain" ]]; then
        echo "$new_domain" > $DOMAIN_FILE
        echo -e "${GREEN}✅ Domain updated to: $new_domain${NC}"
        
        # Update 101 page if exists
        if [[ -f /var/www/html/101.html ]]; then
            sed -i "s|window.location.hostname|'$new_domain'|g" /var/www/html/101.html 2>/dev/null
        fi
    else
        echo -e "${RED}❌ Domain cannot be empty!${NC}"
    fi
    
    pause
}

# ---- OPTION 8: MANAGE SERVICES ----
manage_services() {
    while true; do
        clear
        echo -e "${PURPLE}${BOLD}⚙️ MANAGE SERVICES${NC}"
        echo -e "${BLUE}$LINE${NC}"
        
        echo -e "${CYAN}Select service to manage:${NC}"
        echo "1) SSH Service"
        echo "2) Nginx Service"
        echo "3) Xray Service"
        echo "4) SlowDNS Service"
        echo "5) Web Server (Apache/Nginx)"
        echo "6) Database (MySQL/MariaDB)"
        echo "7) Firewall (UFW)"
        echo "8) ALL SERVICES - Restart All"
        echo "9) Service Status Overview"
        echo "0) Back to Main Menu"
        echo ""
        
        read -p "Choose: " service_choice
        
        case $service_choice in
            1) manage_ssh ;;
            2) manage_nginx ;;
            3) manage_xray ;;
            4) manage_slowdns ;;
            5) manage_webserver ;;
            6) manage_database ;;
            7) manage_firewall ;;
            8) restart_all_services ;;
            9) show_service_status ;;
            0) return ;;
            *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# ---- SLOWDNS MANAGEMENT ----
manage_slowdns() {
    clear
    echo -e "${PURPLE}${BOLD}🐌 SLOWDNS MANAGER${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    echo -e "${CYAN}SlowDNS Options:${NC}"
    echo "1) Install SlowDNS"
    echo "2) Start SlowDNS"
    echo "3) Stop SlowDNS"
    echo "4) Restart SlowDNS"
    echo "5) Check Status"
    echo "6) View Config"
    echo "7) Uninstall SlowDNS"
    echo "0) Back"
    
    read -p "Choose: " choice
    
    case $choice in
        1) install_slowdns ;;
        2) start_slowdns ;;
        3) stop_slowdns ;;
        4) restart_slowdns ;;
        5) status_slowdns ;;
        6) view_slowdns_config ;;
        7) uninstall_slowdns ;;
        0) return ;;
        *) echo -e "${RED}Invalid choice!${NC}" ;;
    esac
    
    pause
}

install_slowdns() {
    echo -e "${YELLOW}Installing SlowDNS...${NC}"
    
    # Install dependencies
    apt-get update
    apt-get install -y wget curl git build-essential
    
    # Download and install slowdns
    cd /tmp
    wget https://github.com/xxxxxxxx/slowdns/releases/download/v1.0/slowdns -O /usr/local/bin/slowdns
    chmod +x /usr/local/bin/slowdns
    
    # Create config
    cat > /etc/slowdns/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": 5300,
    "password": "$(openssl rand -hex 16)",
    "method": "chacha20-ietf-poly1305",
    "timeout": 300,
    "udp_timeout": 60,
    "workers": 2
}
EOF
   
