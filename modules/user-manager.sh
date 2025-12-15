#!/bin/bash
# User Manager Module

list_users(){
    echo "=== Active Users ==="
    echo ""
    echo "Username     Status     Expiry"
    echo "--------------------------------"
    
    for user in $(ls /home); do
        if id "$user" &>/dev/null; then
            status=$(passwd -S "$user" | awk '{print $2}')
            expiry=$(chage -l "$user" | grep "Account expires" | cut -d: -f2 | xargs)
            printf "%-12s %-10s %s\n" "$user" "$status" "$expiry"
        fi
    done
}

reset_password(){
    read -p "Username: " username
    if id "$user" &>/dev/null; then
        passwd "$username"
        echo "✅ Password changed"
    else
        echo "❌ User not found"
    fi
}

check_expiry(){
    echo "=== Expiry Check ==="
    echo ""
    today=$(date +%s)
    
    for user in $(ls /home); do
        if id "$user" &>/dev/null; then
            expiry_date=$(chage -l "$user" | grep "Account expires" | cut -d: -f2)
            if [[ "$expiry_date" != "never" ]]; then
                expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
                if [ $? -eq 0 ] && [ $expiry_epoch -lt $today ]; then
                    echo "❌ $user - EXPIRED ($expiry_date)"
                fi
            fi
        fi
    done
}
