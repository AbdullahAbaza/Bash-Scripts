#!/bin/bash

# Script Name: backup-script_v1.1.sh
# Description: Backup script to backup files and directories
# Usage: ./backup-script.sh
# Author: Abdullah Abaza
# Date: 2021-09-01
# Version: 1.1

# Variables
SOURCE_DIR="/root/backup"
REMOTE_DIR="/root/backups"
LOG_FILE="/var/log/backup.log"
REMOTE_HOST="root@192.168.33.10"
IDENTITY_FILE="$HOME/.ssh/id_rsa" # this script runs with root privilage so your identity file should be in root's home directory /root/.ssh/id_rsa

# Function to log messages
log_message() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to perform the backup
perform_backup() {
    log_message "starting backup............................."
    
    # Validate source directory
    if [ ! -d "$SOURCE_DIR" ]; then
        log_message "Error: Source directory $SOURCE_DIR does not exist!"
        exit 1
    fi

    # Validate identity file
    if [ ! -f "$IDENTITY_FILE" ]; then
        log_message "Error: Identity file $IDENTITY_FILE does not exist!"
        exit 1
    fi

    # Validate remote host connectivity
    if ! ssh -i "$IDENTITY_FILE" "$REMOTE_HOST" "exit" &>/dev/null; then
        log_message "Error: Unable to connect to $REMOTE_HOST!"
        exit 1
    fi

    # Ensure remote directory exists
    ssh -i "$IDENTITY_FILE" "$REMOTE_HOST" "mkdir -p $REMOTE_DIR" &>/dev/null

    # Perform the backup
    rsync -Pavz -e "ssh -i $IDENTITY_FILE" "$SOURCE_DIR" "$REMOTE_HOST:$REMOTE_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log_message "Backup completed successfully."
    else
        log_message "Backup failed."
    fi
}

# Run the backup
perform_backup
