#!/bin/bash
# Backup Manager Module

create_backup(){
    BACKUP_DIR="/backup/autoscriptx"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
    
    echo "Creating backup..."
    
    # Backup important directories
    tar -czf "$BACKUP_FILE" \
        /etc/ssh/ \
        /etc/nginx/ \
        /etc/xray/ \
        /home/ \
        /var/www/ 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup created: $BACKUP_FILE"
        echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    else
        echo "❌ Backup failed"
    fi
}

list_backups(){
    BACKUP_DIR="/backup/autoscriptx"
    
    if [ -d "$BACKUP_DIR" ]; then
        echo "=== Available Backups ==="
        echo ""
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"
    else
        echo "Backup directory not found"
    fi
}

restore_backup(){
    BACKUP_DIR="/backup/autoscriptx"
    
    echo "Available backups:"
    ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | nl
    
    read -p "Enter backup number: " num
    backup_file=$(ls "$BACKUP_DIR"/*.tar.gz | sed -n "${num}p")
    
    if [ -f "$backup_file" ]; then
        echo "Restoring from $backup_file..."
        tar -xzf "$backup_file" -C /
        echo "✅ Restore completed"
    else
        echo "❌ Invalid selection"
    fi
}
