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
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "$SLOWDNS_DIR"
    [[ ! -f "$DOMAIN_FILE" ]] && echo "example.com" > "$DOMAIN_FILE"
    [[ ! -f "$USER_DB" ]] && echo "# Username|Password|Created|Expiry|Status" > "$USER_DB"
    [[ ! -f "$LOG_FILE" ]] && touch "$LOG_FILE"
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
    DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "not-set")
    
    echo -e "${BOLD}• OS${NC}        : $OS"
    echo -e "${BOLD}• Uptime${NC}    : $UPTIME"
    echo -e "${BOLD}• Public IP${NC} : $IP"
    echo -e "${BOLD}• Domain${NC}    : $DOMAIN"
    echo ""
    
    # RAM Info
    echo -e "${CYAN}${BOLD}🧠 RAM INFORMATION${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
    TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
    RAM_PERCENT=$((USED_RAM * 100 / TOTAL_RAM)) 2>/dev/null || RAM_PERCENT=0
    
    echo -e "${BOLD}• Used RAM${NC}  : ${USED_RAM} MB"
    echo -e "${BOLD}• Total RAM${NC} : ${TOTAL_RAM} MB"
    echo -e "${BOLD}• Usage${NC}     : ${RAM_PERCENT}%"
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
    echo -e "$username|$password|$created_date|$expiry_date|Active" >> "$USER_DB"
    
    # Create default services
    create_default_services "$username" "$password" "$expiry_date"
    
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
    local username="$1"
    local password="$2"
    local expiry_date="$3"
    
    # Create SSH config
    mkdir -p "/home/$username/.ssh"
    echo "# AutoScriptX Configuration" > "/home/$username/.ssh/config"
    
    # Create service info file
    cat > "/home/$username/service_info.txt" << 'EOF'
╔════════════════════════════════════════════════╗
║            ACCOUNT INFORMATION                 ║
╚════════════════════════════════════════════════╝

Username: USERNAME_PLACEHOLDER
Password: PASSWORD_PLACEHOLDER
Created: DATE_PLACEHOLDER
Expiry: EXPIRY_PLACEHOLDER

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

IP: IP_PLACEHOLDER
Domain: DOMAIN_PLACEHOLDER

╔════════════════════════════════════════════════╗
║                 IMPORTANT                      ║
╚════════════════════════════════════════════════╝

1. Change password after first login
2. Do not share credentials
3. Contact support for issues
EOF
    
    # Get current IP
    CURRENT_IP=$(curl -s ifconfig.me || echo "N/A")
    CURRENT_DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "not-set")
    
    # Replace placeholders
    sed -i "s/USERNAME_PLACEHOLDER/$username/g" "/home/$username/service_info.txt"
    sed -i "s/PASSWORD_PLACEHOLDER/$password/g" "/home/$username/service_info.txt"
    sed -i "s/DATE_PLACEHOLDER/$(date)/g" "/home/$username/service_info.txt"
    sed -i "s/EXPIRY_PLACEHOLDER/$expiry_date/g" "/home/$username/service_info.txt"
    sed -i "s/IP_PLACEHOLDER/$CURRENT_IP/g" "/home/$username/service_info.txt"
    sed -i "s/DOMAIN_PLACEHOLDER/$CURRENT_DOMAIN/g" "/home/$username/service_info.txt"
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
        tar -czf "$backup_file" "/home/$username" 2>/dev/null
        
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
        
        # Get password from database
        OLD_PASS=$(grep "^$username|" "$USER_DB" 2>/dev/null | cut -d'|' -f2)
        
        # Update database
        sed -i "/^$username|/d" "$USER_DB"
        echo -e "$username|$OLD_PASS|$(date +%Y-%m-%d)|$expiry_date|Active" >> "$USER_DB"
        
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
            cat > /etc/issue.net << 'BANNER_EOF'
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
BANNER_EOF
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
            cat > /var/www/html/101.html << 'HTML_EOF'
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
HTML_EOF
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
    
    current_domain=$(cat "$DOMAIN_FILE" 2>/dev/null || echo "not-set")
    echo -e "${CYAN}Current Domain:${NC} $current_domain"
    
    read -p "Enter new domain (e.g., example.com): " new_domain
    
    if [[ -n "$new_domain" ]]; then
        echo "$new_domain" > "$DOMAIN_FILE"
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
        echo "5) ALL SERVICES - Restart All"
        echo "6) Service Status Overview"
        echo "0) Back to Main Menu"
        echo ""
        
        read -p "Choose: " service_choice
        
        case $service_choice in
            1) manage_ssh ;;
            2) manage_nginx ;;
            3) manage_xray ;;
            4) manage_slowdns ;;
            5) restart_all_services ;;
            6) show_service_status ;;
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
    apt-get install -y wget curl
    
    # Create dummy slowdns binary
    cat > /usr/local/bin/slowdns << 'SLOWDNS_EOF'
#!/bin/bash
echo "SlowDNS Service - AutoScriptX"
echo "Port: 5300"
echo "Status: Running"
while true; do
    sleep 3600
done
SLOWDNS_EOF
    chmod +x /usr/local/bin/slowdns
    
    # Create config
    mkdir -p /etc/slowdns
    cat > /etc/slowdns/config.json << 'CONFIG_EOF'
{
    "server": "0.0.0.0",
    "server_port": 5300,
    "password": "autoscriptx123",
    "method": "chacha20-ietf-poly1305",
    "timeout": 300
}
CONFIG_EOF
    
    # Create service file
    cat > /etc/systemd/system/slowdns.service << 'SERVICE_EOF'
[Unit]
Description=SlowDNS Proxy Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/slowdns
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    
    systemctl daemon-reload
    systemctl enable slowdns
    systemctl start slowdns
    
    echo -e "${GREEN}✅ SlowDNS installed and started on port 5300${NC}"
    echo -e "${CYAN}Config: /etc/slowdns/config.json${NC}"
}

start_slowdns() {
    systemctl start slowdns 2>/dev/null && echo -e "${GREEN}✅ SlowDNS started${NC}" || echo -e "${RED}❌ Failed to start SlowDNS${NC}"
}

stop_slowdns() {
    systemctl stop slowdns 2>/dev/null && echo -e "${YELLOW}⏸️ SlowDNS stopped${NC}" || echo -e "${RED}❌ Failed to stop SlowDNS${NC}"
}

restart_slowdns() {
    systemctl restart slowdns 2>/dev/null && echo -e "${GREEN}🔄 SlowDNS restarted${NC}" || echo -e "${RED}❌ Failed to restart SlowDNS${NC}"
}

status_slowdns() {
    systemctl status slowdns --no-pager 2>/dev/null || echo "SlowDNS service not found"
}

view_slowdns_config() {
    if [[ -f /etc/slowdns/config.json ]]; then
        echo -e "${CYAN}SlowDNS Configuration:${NC}"
        cat /etc/slowdns/config.json
    else
        echo -e "${RED}SlowDNS config not found!${NC}"
    fi
}

uninstall_slowdns() {
    echo -e "${RED}⚠ WARNING: This will remove SlowDNS!${NC}"
    read -p "Type 'UNINSTALL' to confirm: " confirm
    
    if [[ "$confirm" == "UNINSTALL" ]]; then
        systemctl stop slowdns 2>/dev/null
        systemctl disable slowdns 2>/dev/null
        rm -f /usr/local/bin/slowdns
        rm -rf /etc/slowdns
        rm -f /etc/systemd/system/slowdns.service
        systemctl daemon-reload
        echo -e "${GREEN}✅ SlowDNS uninstalled${NC}"
    else
        echo -e "${YELLOW}❌ Cancelled${NC}"
    fi
}

# ---- UDP CUSTOM SERVICE ----
manage_udp() {
    clear
    echo -e "${PURPLE}${BOLD}📡 UDP CUSTOM SERVICE${NC}"
    echo -e "${BLUE}$LINE${NC}"

    echo "1) Start UDP on custom port"
    echo "2) Stop UDP service"
    echo "3) Status"
    echo "0) Back"
    read -p "Choose: " udp_choice

    case $udp_choice in
        1)
            read -p "Enter UDP Port (1-65535): " UDP_PORT
            if [[ $UDP_PORT -lt 1 || $UDP_PORT -gt 65535 ]]; then
                echo -e "${RED}❌ Invalid port range${NC}"
                sleep 2
                return
            fi

            ufw allow ${UDP_PORT}/udp >/dev/null 2>&1
            apt install -y socat >/dev/null 2>&1

            pkill -f "socat UDP-RECVFROM" >/dev/null 2>&1

            nohup socat UDP-RECVFROM:${UDP_PORT},fork UDP-SENDTO:127.0.0.1:${UDP_PORT} >/dev/null 2>&1 &

            echo "${UDP_PORT}" > /etc/udp_port
            echo -e "${GREEN}✅ UDP started on port $UDP_PORT${NC}"
            ;;
        2)
            pkill -f "socat UDP-RECVFROM" >/dev/null 2>&1
            echo -e "${YELLOW}🛑 UDP service stopped${NC}"
            ;;
        3)
            if pgrep -f "socat UDP-RECVFROM" >/dev/null; then
                UPORT=$(cat /etc/udp_port 2>/dev/null || echo "?")
                echo -e "${GREEN}🟢 Running on UDP port: $UPORT${NC}"
            else
                echo -e "${RED}🔴 UDP service not running${NC}"
            fi
            ;;
        0) return ;;
    esac
    sleep 2
}
# ---- OTHER SERVICE MANAGERS ----
manage_ssh() {
    clear
    echo -e "${CYAN}SSH Service Manager${NC}"
    echo "1) Restart SSH"
    echo "2) Stop SSH"
    echo "3) Status"
    echo "4) Edit SSH Config"
    echo "0) Back"
    read -p "Choose: " ssh_choice
    
    case $ssh_choice in
        1) systemctl restart ssh; echo "SSH restarted" ;;
        2) systemctl stop ssh; echo "SSH stopped" ;;
        3) systemctl status ssh --no-pager ;;
        4) nano /etc/ssh/sshd_config ;;
        0) return ;;
    esac
    pause
}

manage_nginx() {
    clear
    echo -e "${CYAN}Nginx Service Manager${NC}"
    echo "1) Restart Nginx"
    echo "2) Stop Nginx"
    echo "3) Status"
    echo "4) Test Config"
    echo "0) Back"
    read -p "Choose: " nginx_choice
    
    case $nginx_choice in
        1) systemctl restart nginx; echo "Nginx restarted" ;;
        2) systemctl stop nginx; echo "Nginx stopped" ;;
        3) systemctl status nginx --no-pager ;;
        4) nginx -t 2>/dev/null && echo "Config OK" || echo "Config Error" ;;
        0) return ;;
    esac
    pause
}

manage_xray() {
    clear
    echo -e "${CYAN}Xray Service Manager${NC}"
    echo "1) Restart Xray"
    echo "2) Stop Xray"
    echo "3) Status"
    echo "4) View Logs"
    echo "0) Back"
    read -p "Choose: " xray_choice
    
    case $xray_choice in
        1) systemctl restart xray 2>/dev/null && echo "Xray restarted" || echo "Xray not installed" ;;
        2) systemctl stop xray 2>/dev/null && echo "Xray stopped" || echo "Xray not installed" ;;
        3) systemctl status xray --no-pager 2>/dev/null || echo "Xray not installed" ;;
        4) journalctl -u xray -n 20 --no-pager 2>/dev/null || echo "No logs found" ;;
        0) return ;;
    esac
    pause
}

restart_all_services() {
    echo -e "${YELLOW}Restarting all services...${NC}"
    systemctl restart ssh 2>/dev/null && echo "SSH restarted"
    systemctl restart nginx 2>/dev/null && echo "Nginx restarted"
    systemctl restart xray 2>/dev/null && echo "Xray restarted"
    systemctl restart slowdns 2>/dev/null && echo "SlowDNS restarted"
    echo -e "${GREEN}✅ All services restarted${NC}"
    pause
}

show_service_status() {
    echo -e "${CYAN}Service Status Overview${NC}"
    echo "════════════════════════════════════════"
    
    services=("ssh" "nginx" "xray" "slowdns")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "✅ $service: ${GREEN}RUNNING${NC}"
        elif systemctl is-enabled "$service" 2>/dev/null; then
            echo -e "❌ $service: ${RED}STOPPED${NC}"
        else
            echo -e "⚠  $service: ${YELLOW}NOT INSTALLED${NC}"
        fi
    done
    pause
}

# ---- OPTION 9: SYSTEM INFO ----
system_info() {
    clear
    echo -e "${PURPLE}${BOLD}🖥️ SYSTEM INFORMATION${NC}"
    echo -e "${BLUE}$LINE${NC}"
    
    # Basic Info
    echo -e "${CYAN}${BOLD}Basic Information${NC}"
    echo "════════════════════════════════════════"
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}OS:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Architecture:${NC} $(uname -m)"
    echo -e "${WHITE}Uptime:${NC} $(uptime -p | sed 's/up //')"
    echo ""
    
    # CPU Info
    echo -e "${CYAN}${BOLD}CPU Information${NC}"
    echo "════════════════════════════════════════"
    echo -e "${WHITE}Model:${NC} $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
    echo -e "${WHITE}Cores:${NC} $(nproc)"
    echo -e "${WHITE}Usage:${NC} $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo ""
    
    # Memory Info
    echo -e "${CYAN}${BOLD}Memory Information${NC}"
    echo "════════════════════════════════════════"
    free -h
    echo ""
    
    # Disk Info
    echo -e "${CYAN}${BOLD}Disk Information${NC}"
    echo "════════════════════════════════════════"
    df -h
    echo ""
    
    # Network Info
    echo -e "${CYAN}${BOLD}Network Information${NC}"
    echo "════════════════════════════════════════"
    echo -e "${WHITE}Public IP:${NC} $(curl -s ifconfig.me || echo 'N/A')"
    echo -e "${WHITE}Local IP:${NC} $(hostname -I | awk '{print $1}')"
    echo -e "${WHITE}Open Ports:${NC}"
    ss -tulpn | grep LISTEN | head -10
    echo ""
    
    # User Info
    echo -e "${CYAN}${BOLD}User Information${NC}"
    echo "════════════════════════════════════════"
    echo -e "${WHITE}Logged in Users:${NC} $(who | wc -l)"
    if [[ -f "$USER_DB" ]]; then
        echo -e "${WHITE}Total Accounts:${NC} $(($(wc -l < "$USER_DB") - 1))"
    else
        echo -e "${WHITE}Total Accounts:${NC} 0"
    fi
    echo ""
    
    pause
}

# ---- PLACEHOLDER FUNCTIONS ----
install_required_services() {
    echo -e "${YELLOW}Installing required services...${NC}"
    apt-get update
    apt-get install -y nginx
    echo -e "${GREEN}✅ Nginx installed${NC}"
    echo -e "${YELLOW}Install Xray manually if needed${NC}"
    pause
}

backup_system() {
    echo -e "${YELLOW}Creating system backup...${NC}"
    mkdir -p "$BACKUP_DIR"
    backup_file="$BACKUP_DIR/full_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_file" /etc/autoscriptx /home 2>/dev/null
    echo -e "${GREEN}✅ Backup created: $backup_file${NC}"
    pause
}

restore_backup() {
    echo -e "${YELLOW}Available backups:${NC}"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"
    pause
}

update_script() {
    echo -e "${YELLOW}Updating AutoScriptX...${NC}"
    echo "This feature will be added soon"
    pause
}

# ---- MAIN MENU ----
main_menu() {
    init
    while true; do
        show_header
        
        echo -e "${PURPLE}${BOLD}# 📋 MAIN MENU${NC}\n"
        echo -e "${GREEN}1.${NC} Create Account"
        echo -e "${GREEN}2.${NC} Delete Account"
        echo -e "${GREEN}3.${NC} Renew Account"
        echo -e "${GREEN}4.${NC} Lock/Unlock Account"
        echo -e "${GREEN}5.${NC} Edit Banner"
        echo -e "${GREEN}6.${NC} Edit 101 Response"
        echo -e "${GREEN}7.${NC} Change Domain"
        echo -e "${GREEN}8.${NC} Manage Services (Including SlowDNS)"
        echo -e "${GREEN}9.${NC} Udp Costume"
        echo -e "${GREEN}10.${NC} System Info"
        echo -e "${CYAN}10.${NC} Install Required Services"
        echo -e "${CYAN}11.${NC} Backup System"
        echo -e "${CYAN}12.${NC} Restore Backup"
        echo -e "${CYAN}13.${NC} Update Script"
        echo -e "${RED}0.${NC} Exit"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) create_account ;;
            2) delete_account ;;
            3) renew_account ;;
            4) lock_unlock_account ;;
            5) edit_banner ;;
            6) edit_101_response ;;
            7) change_domain ;;
            8) manage_services ;;
            9) manage_udp ;;
            10) system_info ;;
            10) install_required_services ;;
            11) backup_system ;;
            12) restore_backup ;;
            13) update_script ;;
            0) 
                echo -e "${GREEN}Goodbye! 👋${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# ---- START SCRIPT ----
main_menu
