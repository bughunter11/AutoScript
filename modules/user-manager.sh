#!/bin/bash
# User Manager Module

show_all_users() {
    echo "=== ALL SYSTEM USERS ==="
    echo ""
    cut -d: -f1 /etc/passwd | grep -E "^[a-z]" | sort
}

check_password_expiry() {
    echo "=== PASSWORD EXPIRY ==="
    echo ""
    for user in $(ls /home); do
        if id "$user" &>/dev/null; then
            expiry=$(chage -l "$user" | grep "Password expires" | cut -d: -f2 | xargs)
            echo "$user: $expiry"
        fi
    done
}

reset_user_password() {
    read -p "Username: " username
    if id "$username" &>/dev/null; then
        passwd "$username"
        echo "Password changed for $username"
    else
        echo "User not found"
    fi
}
