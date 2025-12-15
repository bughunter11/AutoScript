#!/bin/bash
# Service Manager Module

show_service_status(){
    echo "=== Service Status ==="
    echo ""
    
    services=("ssh" "nginx" "xray" "dropbear" "stunnel4")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            echo "✅ $service: RUNNING"
        else
            echo "❌ $service: STOPPED"
        fi
    done
}

restart_all_services(){
    echo "Restarting all services..."
    systemctl restart ssh nginx xray dropbear stunnel4
    echo "✅ Services restarted"
}

enable_on_boot(){
    read -p "Service name: " service
    systemctl enable "$service"
    echo "✅ $service enabled on boot"
}

disable_on_boot(){
    read -p "Service name: " service
    systemctl disable "$service"
    echo "✅ $service disabled on boot"
}
