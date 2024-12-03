#!/bin/bash
# Description: This script rotates log files based on size and age

# Variables
LOG_DIR="/var/log/myapp"
MAX_LOG_SIZE=5000000 # 5 MB
MAX_LOG_AGE=30 # 30 days


# Function To Rotate Logs
rotate_logs() {
    # Check if log directory exists
    if [ ! -d $LOG_DIR ]; then
        echo "Log directory does not exist"
        exit 1
    fi

    # Check if log files exist
    if [ ! "$(ls -A $LOG_DIR)" ]; then
        echo "No log files found"
        exit 1
    fi

    for log_file in "$LOG_DIR"/*.log;
    do 
        if [ $(stat -c%s "$log_file") -gt $MAX_LOG_SIZE ]; then
            mv "$log_file" "$log_file.$(date +'%Y%m%d')"
            gzip "$log_file.$(date +'%Y%m%d')"
            echo "Log Rotated $log_file"
        fi
    done
}


# Function clean up old logs
clean_old_logs() {
    find "$LOG_DIR" -name "*.gz" -mtime +$MAX_LOG_AGE -exec rm {} \;
    echo "Old logs cleaned up"
}


# Run the functions

rotate_logs
clean_old_logs