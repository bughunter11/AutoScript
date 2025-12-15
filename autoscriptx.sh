
#!/bin/bash
# AutoScriptX - VPS Manager

P="\033[35m"; B="\033[36m"; G="\033[32m"
Y="\033[33m"; R="\033[31m"; N="\033[0m"

DOMAIN_FILE="/etc/autoscriptx/domain"
[[ ! -f $DOMAIN_FILE ]] && echo "not-set" > $DOMAIN_FILE

pause(){ read -p "Press Enter to continue..."; }

# Header
clear
echo -e "${P}# 🚀 AutoScriptX - VPS Manager${N}\n"
echo -e "${B}• OS${N}        : $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2)"
echo -e "${B}• Uptime${N}    : $(uptime -p)"
echo -e "${B}• Public IP${N} : $(curl -s ifconfig.me || echo 'Not available')"
echo -e "${B}• Domain${N}    : $(cat $DOMAIN_FILE)\n"

# Menu
echo -e "${P}# 📋 Main Menu${N}\n"
echo -e "${Y}Choose${N}"
echo -e "${G}> 1.${N} Create Account"
echo -e "${G}  2.${N} Delete Account"
echo -e "${G}  3.${N} Renew Account"
echo -e "${G}  4.${N} Lock/Unlock Account"
echo -e "${G}  5.${N} Edit Banner"
echo -e "${G}  6.${N} Edit 101 Response"
echo -e "${G}  7.${N} Change Domain"
echo -e "${G}  8.${N} Manage Services"
echo -e "${G}  9.${N} System Info"
echo -e "${G}  x.${N} Exit\n"

read -p "> " opt

# Functions
create_user(){
    read -p "Username: " u
    read -p "Password: " p
    read -p "Expiry (days): " d
    useradd -m $u
    echo "$u:$p" | chpasswd
    chage -E $(date -d "+$d days" +%F) $u
    echo -e "${G}✅ User created${N}"
    pause
}

delete_user(){
    read -p "Username: " u
    userdel -r $u
    echo -e "${R}🗑️ User deleted${N}"
    pause
}

renew_user(){
    read -p "Username: " u
    read -p "Extend days: " d
    chage -E $(date -d "+$d days" +%F) $u
    echo -e "${G}🔄 User renewed${N}"
    pause
}

lock_user(){
    read -p "Username: " u
    if passwd -S $u | grep -q L; then
        passwd -u $u && echo -e "${G}🔓 Unlocked${N}"
    else
        passwd -l $u && echo -e "${R}🔒 Locked${N}"
    fi
    pause
}

edit_banner(){
    nano /etc/issue.net
    systemctl restart ssh
    echo -e "${G}Banner updated${N}"
    pause
}

edit_101(){
    mkdir -p /var/www/html
    nano /var/www/html/101.html
    echo -e "${G}101 response updated${N}"
    pause
}

change_domain(){
    read -p "New domain: " d
    echo "$d" > $DOMAIN_FILE
    echo -e "${G}Domain updated${N}"
    pause
}

manage_services(){
    clear
    echo "1) Restart All Services"
    echo "2) Check Status"
    echo "0) Back"
    read -p "> " s
    case $s in
        1) systemctl restart ssh nginx xray ;;
        2) systemctl status ssh nginx xray --no-pager ;;
        0) return ;;
    esac
    pause
}

system_info(){
    clear
    echo "=== System Information ==="
    echo ""
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo ""
    echo "=== Memory Usage ==="
    free -h
    echo ""
    echo "=== Disk Usage ==="
    df -h
    pause
}

# Menu handler
case $opt in
    1) create_user ;;
    2) delete_user ;;
    3) renew_user ;;
    4) lock_user ;;
    5) edit_banner ;;
    6) edit_101 ;;
    7) change_domain ;;
    8) manage_services ;;
    9) system_info ;;
    x) exit 0 ;;
    *) echo -e "${R}Invalid option${N}"; sleep 1 ;;
esac

# Restart script
exec bash $0
