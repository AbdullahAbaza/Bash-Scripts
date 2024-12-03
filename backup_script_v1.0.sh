#!/bin/bash

# Script Name: backup-script.sh
# Description: Backup script to backup files and directories
# Usage: ./backup-script.sh
# Author: Abdullah Abaza
# Date: 2021-09-01
# Version: 1.0

# Variables
SOURCE_DIR="/root/backup"
REMOTE_DIR="/root/backups"
LOG_FILE="/var/log/backup.log"
REMOTE_HOST="root@192.168.33.10"
IDENTITY_FILE="$HOME/.ssh/id_rsa" # this script runs with root privilage so your identity file should be in root's home directory /root/.ssh/id_rsa



# Function to perform the backup
perform_backup() {
    echo -e "\n =============================== starting backup =====================================" >> "$LOG_FILE"
    rsync -Pavz -e "ssh -i $IDENTITY_FILE" "$SOURCE_DIR" "$REMOTE_HOST":"$REMOTE_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        
        echo "Backup was successful: $(date)" >> "$LOG_FILE"
    else
        echo "Backup failed: $(date)" >> "$LOG_FILE"
    fi
}


# Run the backup 

perform_backup