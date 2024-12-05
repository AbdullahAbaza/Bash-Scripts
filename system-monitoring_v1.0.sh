#!/bin/bash

# Author: Abdullah Abaza
# Date: 2023-11-14
# Version: 1.0
# Script Name: system-monitoring_v1.0.sh
# Description: script to monitor system resources 

# Usage: ./system-monitoring_v1.0.sh -e "your@email.com"
# Using SMTP server:
# ./system-monitoring_v1.0.sh -e "your@email.com" \
#     --smtp-server=smtp.gmail.com \
#     --smtp-port=587 \
#     --smtp-user=your@gmail.com \
#    
# With debugging:  ./system-monitoring_v1.0.sh -e "your@email.com" --mail-debug



# Exit on any error
set -e

# text's color values
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NORMAL="\033[0;39m"

# Default Variables
DISK_THRESHOLD=80
CPU_THRESHOLD=90
MEM_THRESHOLD=90
SEND_EMAIL=false

# Email Configuration
EMAIL_TO="mail@example.com"
EMAIL_FROM="system.monitor@$(hostname)"
EMAIL_SUBJECT="System Monitor Alert - $(hostname)"

# Add new email configuration variables
MAIL_CMD=""
MAIL_DEBUG=false
SMTP_SERVER=""
SMTP_PORT="587"
SMTP_USER=""
SMTP_PASS="xjbs dgya kkjv hkgk"

OUTPUT_DIR="/var/log/"
OUTPUT_FILE="system_monitor.log"

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "This Script Generates a System Monitoring Report"
    echo
    echo "Options:"
    echo "  -d DISK_THRESHOLD       Disk Usage Warning Threshold (default: 80%)"
    echo "  -c CPU_THRESHOLD        CPU Usage Warning Threshold (default: 90%)"
    echo "  -m MEM_THRESHOLD        Memory Usage Warning Threshold (default: 90%)"
    echo "  -o OUTPUT_FILE          Output Log File Name"
    echo "  -e EMAIL_TO             Email address to send alerts to"
    echo "  -h                      Show this help message"
    echo "  --smtp-server HOST      SMTP server for email alerts"
    echo "  --smtp-port PORT        SMTP port (default: 587)"
    echo "  --smtp-user USER        SMTP username"
    echo "  --smtp-pass PASS        SMTP password"
    echo "  --mail-debug           Enable email debugging"
    exit 0
}

# Parse command line arguments
while getopts "d:c:m:o:e:h-:" opt; do
    case $opt in
        d) DISK_THRESHOLD="$OPTARG" ;;
        c) CPU_THRESHOLD="$OPTARG";;
        m) MEM_THRESHOLD="$OPTARG";;
        o) OUTPUT_FILE="$OPTARG";;
        e) EMAIL_TO="$OPTARG";;
        h) show_help ;;
        -)
            case "${OPTARG}" in
                smtp-server=*) SMTP_SERVER="${OPTARG#*=}" ;;
                smtp-port=*) SMTP_PORT="${OPTARG#*=}" ;;
                smtp-user=*) SMTP_USER="${OPTARG#*=}" ;;
                smtp-pass=*) SMTP_PASS="${OPTARG#*=}" ;;
                mail-debug) MAIL_DEBUG=true ;;
                *) echo "Invalid option: --${OPTARG}" >&2; exit 1 ;;
            esac
            ;;
        ?) echo "Invalid option. Use -h for help."; exit 1 ;;
    esac
done 

# Function to check Disk Usage
check_disk_usage() {
    df -h

    root_file_system=$(df / | tail -1 | awk '{print $1}')

    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        SEND_EMAIL=true
        echo -e "${YELLOW}Warning: $root_file_system is above $DISK_THRESHOLD usage!${NORMAL}"
    else 
        echo -e "${GREEN}current Disk usage: $disk_usage%${NORMAL}"
    fi
}

# Funclion to check CPU Usage
check_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        SEND_EMAIL=true
        echo -e "${YELLOW}Warning: High CPU Usage: ${RED}$cpu_usage%${NORMAL}"
    else
        echo -e "Current CPU Usage: ${GREEN}$cpu_usage%${NORMAL}"
    fi
}

# Function to check Memory Usage 
check_memory_usage() {
    total_momory=$(free -h | grep Mem | awk '{print $2}' | sed 's/Mi/MB/g; s/Gi/GB/g')
    used_memory=$(free -h | grep Mem | awk '{print $3}' | sed 's/Mi/MB/g; s/Gi/GB/g')
    free_memory=$(free -h | grep Mem | awk '{print $4}' | sed 's/Mi/MB/g; s/Gi/GB/g')

    echo -e "Total Memory: ${YELLOW}$total_momory${NORMAL}"
    echo -e "Used Memory: ${YELLOW}$used_memory${NORMAL}"
    echo -e "Free Memory: ${YELLOW}$free_memory${NORMAL}"
    

    local mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

    if (( $(echo "$mem_usage > $MEM_THRESHOLD" | bc -l) )); then
        SEND_EMAIL=true
        echo -e "${YELLOW}Warning: Memory usage (high): ${RED}$mem_usage%${NORMAL}"
    else
        echo -e "Memory Usage(normal): ${GREEN}$mem_usage%${NORMAL}"
    fi

} 

# Function to check top 5 memory consuming processes
check_top5_mem_proc() {
    ps -eo pid,ppid,cmd,comm,%mem,%cpu --sort=-%mem | head -6
}

# Function to check mail command availability
check_mail_command() {
    # Check for available mail commands
    if command -v mailx >/dev/null 2>&1; then
        MAIL_CMD="mailx"
    elif command -v mail >/dev/null 2>&1; then
        MAIL_CMD="mail"
    else
        echo "ERROR: Neither 'mail' nor 'mailx' command found. Please install mailutils package."
        return 1
    fi

    # Test mail configuration
    if [ "$MAIL_DEBUG" = true ]; then
        echo "Using mail command: $MAIL_CMD"
        $MAIL_CMD -V 2>&1 || true
    fi
    return 0
}

# Function to send email alert
send_email_alert() {
    local output_path="$1"
    local email_body="System monitoring alert from $(hostname).\n\n"
    email_body+="The following thresholds have been exceeded:\n"
    
    if [ "$(df / | tail -1 | awk '{print $5}' | sed 's/%//')" -gt "$DISK_THRESHOLD" ]; then
        email_body+="- Disk usage is above ${DISK_THRESHOLD}%\n"
    fi
    
    if (( $(echo "$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}') > $CPU_THRESHOLD" | bc -l) )); then
        email_body+="- CPU usage is above ${CPU_THRESHOLD}%\n"
    fi
    
    if (( $(echo "$(free | grep Mem | awk '{print $3/$2 * 100.0}') > $MEM_THRESHOLD" | bc -l) )); then
        email_body+="- Memory usage is above ${MEM_THRESHOLD}%\n"
    fi
    
    email_body+="\nPlease check the attached report for details.\n"
    
    # Check mail command availability
    if ! check_mail_command; then
        echo "ERROR: Email alert could not be sent - mail command not available"
        return 1
    fi

    # Prepare mail command based on available configuration
    local mail_opts=()
    case "$MAIL_CMD" in
        "mailx")
            mail_opts+=("-s" "$EMAIL_SUBJECT")
            if [ -n "$SMTP_SERVER" ]; then
                mail_opts+=("-S" "smtp=$SMTP_SERVER:$SMTP_PORT")
                [ -n "$SMTP_USER" ] && mail_opts+=("-S" "smtp-auth=login" "-S" "smtp-auth-user=$SMTP_USER")
                [ -n "$SMTP_PASS" ] && mail_opts+=("-S" "smtp-auth-password=$SMTP_PASS")
            fi
            mail_opts+=("-a" "$output_path")
            ;;
        "mail")
            mail_opts+=("-s" "$EMAIL_SUBJECT" "-a" "$output_path")
            ;;
    esac

    # Send email with error handling
    if [ "$MAIL_DEBUG" = true ]; then
        echo "Sending email with command: $MAIL_CMD ${mail_opts[*]} $EMAIL_TO"
    fi

    if echo -e "$email_body" | $MAIL_CMD "${mail_opts[@]}" "$EMAIL_TO" 2>/tmp/mail.err; then
        echo "Alert email sent successfully to $EMAIL_TO"
        [ "$MAIL_DEBUG" = true ] && cat /tmp/mail.err
    else
        echo "ERROR: Failed to send email alert"
        cat /tmp/mail.err
        return 1
    fi

    [ -f /tmp/mail.err ] && rm /tmp/mail.err
    return 0
}

# Function to automate monitoring
generate_report() {
    # Create output directory if it doesn't exist
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
    fi

    # Full path for the output file
    local output_path="${OUTPUT_DIR}/${OUTPUT_FILE}"

    {
        echo -e "\n$(date '+%Y-%m-%d %H:%M:%S')\n${BLUE}System Monitoring Report - $(date '+%Y-%m-%d %H:%M:%S')${NORMAL}"
        echo -e "====================================================================\n"

        echo -e "${BLUE}CPU Usage:${NORMAL}"
        check_cpu_usage

        echo -e "\n${BLUE}Memory Usage:${NORMAL}"
        check_memory_usage

        echo -e "\n${BLUE}Disk Usage:${NORMAL}"
        check_disk_usage

        echo -e "\n${BLUE}Top 5 Memory-Consuming Processes:${NORMAL}"
        check_top5_mem_proc

        echo -e "\n========================================================================="
    } | tee -a "$output_path"

    echo -e "\nReport has been saved to: $output_path"

    # Send email if thresholds are exceeded
    if [ "$SEND_EMAIL" = true ]; then
        send_email_alert "$output_path"
    fi
}

# Run
generate_report 
