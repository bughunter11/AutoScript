#!/bin/bash
# Service Manager Module

show_all_services() {
    echo "=== SERVICE STATUS ==="
    echo ""
    services=("ssh" "nginx" "xray" "mysql" "apache2")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "✅ $service: RUNNING"
        else
            echo "❌ $service: STOPPED"
        fi
    done
}

restart_service() {
    read -p "Service name: " service
    systemctl restart "$service" 2>/dev/null && echo "$service restarted" || echo "Failed"
}

enable_service() {
    read -p "Service name: " service
    systemctl enable "$service" 2>/dev/null && echo "$service enabled" || echo "Failed"
}
