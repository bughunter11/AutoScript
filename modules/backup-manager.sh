#!/bin/bash
# Backup Manager Module

create_full_backup() {
    BACKUP_DIR="/backup/autoscriptx"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/full_$TIMESTAMP.tar.gz"
    
    echo "Creating backup..."
    tar -czf "$BACKUP_FILE" /etc/autoscriptx /home /var/www 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "Backup created: $BACKUP_FILE"
        echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
    else
        echo "Backup failed"
    fi
}

list_backups() {
    BACKUP_DIR="/backup/autoscriptx"
    
    if [ -d "$BACKUP_DIR" ]; then
        echo "=== AVAILABLE BACKUPS ==="
        ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups"
    else
        echo "Backup directory not found"
    fi
}

delete_old_backups() {
    find /backup/autoscriptx -name "*.tar.gz" -mtime +7 -delete
    echo "Old backups deleted"
}
