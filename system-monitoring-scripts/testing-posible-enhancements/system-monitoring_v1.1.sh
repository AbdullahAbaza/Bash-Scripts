#!/bin/bash

# Script Name: system-monitoring_v1.1.sh
# Description: Enhanced system resource monitoring script
# Author: Abdullah Abaza
# Date: 2023-11-14
# Version: 1.1

# Exit on any error, undefined variable, and prevent pipe failures
set -euo pipefail

# Cache sudo credentials if needed
if [[ $EUID -ne 0 ]]; then
    sudo -v
    # Keep sudo alive in background
    (while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null) &
fi

# ANSI color codes using tput for better portability
readonly RED=$(tput setaf 1)
readonly GREEN=$(tput setaf 2)
readonly YELLOW=$(tput setaf 3)
readonly BLUE=$(tput setaf 4)
readonly NORMAL=$(tput sgr0)

# Default Variables with readonly protection
readonly DEFAULT_DISK_THRESHOLD=80
readonly DEFAULT_CPU_THRESHOLD=90
readonly DEFAULT_MEM_THRESHOLD=90
readonly DEFAULT_OUTPUT_DIR="/var/log"
readonly DEFAULT_OUTPUT_FILE="system_monitor.log"
readonly HOSTNAME=$(hostname)
readonly DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Configurable variables
DISK_THRESHOLD=$DEFAULT_DISK_THRESHOLD
CPU_THRESHOLD=$DEFAULT_CPU_THRESHOLD
MEM_THRESHOLD=$DEFAULT_MEM_THRESHOLD
SEND_EMAIL=false
EMAIL_TO=""
EMAIL_FROM="system.monitor@$HOSTNAME"
EMAIL_SUBJECT="System Monitor Alert - $HOSTNAME"
OUTPUT_DIR=$DEFAULT_OUTPUT_DIR
OUTPUT_FILE=$DEFAULT_OUTPUT_FILE
VERBOSE=false

# Temporary files for caching
readonly TMP_DIR=$(mktemp -d)
readonly CPU_CACHE="$TMP_DIR/cpu.cache"
readonly MEM_CACHE="$TMP_DIR/mem.cache"
trap 'rm -rf "$TMP_DIR"' EXIT

# Help function with improved formatting
show_help() {
    cat << EOF
    Usage: $(basename "$0") [OPTIONS]
    Generate a comprehensive system monitoring report

    Options:
    -d THRESHOLD  Disk usage warning threshold (default: ${DEFAULT_DISK_THRESHOLD}%)
    -c THRESHOLD  CPU usage warning threshold (default: ${DEFAULT_CPU_THRESHOLD}%)
    -m THRESHOLD  Memory usage warning threshold (default: ${DEFAULT_MEM_THRESHOLD}%)
    -o FILE       Output log file name (default: ${DEFAULT_OUTPUT_FILE})
    -e EMAIL      Email address to send alerts to
    -v           Verbose output
    -h           Show this help message

    Example:
    $(basename "$0") -d 75 -c 85 -m 80 -e admin@example.com -o custom_report.log
EOF
    exit 0
}

# Improved logging function
log() {
    local level=$1
    shift
    local color=""
    case $level in
        INFO) color=$GREEN ;;
        WARN) color=$YELLOW ;;
        ERROR) color=$RED ;;
        *) color=$NORMAL ;;
    esac
    echo -e "${color}[$level] $*${NORMAL}"
    if [[ $VERBOSE == true ]]; then
        echo -e "${color}[$level] $*${NORMAL}" >&2
    fi
}

# Function to check if command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || { log ERROR "Required command '$1' not found. Please install it."; exit 1; }
}

# Enhanced disk usage check with improved formatting and caching
check_disk_usage() {
    local disk_info
    disk_info=$(df -h | awk 'NR>1 {print $6,$5}' | sort)
    
    while IFS= read -r line; do
        local mount_point usage_percent
        mount_point=$(echo "$line" | awk '{print $1}')
        usage_percent=$(echo "$line" | awk '{print $2}' | tr -d '%')
        
        if [ "$usage_percent" -gt "$DISK_THRESHOLD" ]; then
            log WARN "High disk usage on $mount_point: $usage_percent%"
            echo -e "${RED}$mount_point: $usage_percent%${NORMAL}"
        else
            echo -e "${GREEN}$mount_point: $usage_percent%${NORMAL}"
        fi
    done <<< "$disk_info"
}

# Optimized CPU usage check with caching
check_cpu_usage() {
    local cpu_usage
    if [[ ! -f $CPU_CACHE ]] || [[ $(( $(date +%s) - $(stat -c %Y "$CPU_CACHE") )) -gt 60 ]]; then
        cpu_usage=$(top -bn2 -d0.5 | grep "Cpu(s)" | tail -n1 | awk '{print $2+$4}')
        echo "$cpu_usage" > "$CPU_CACHE"
    else
        cpu_usage=$(cat "$CPU_CACHE")
    fi
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        log WARN "High CPU usage: $cpu_usage%"
        echo -e "${RED}CPU Usage: $cpu_usage%${NORMAL}"
    else
        echo -e "${GREEN}CPU Usage: $cpu_usage%${NORMAL}"
    fi
}

# Enhanced memory usage check with caching
check_memory_usage() {
    local mem_info
    if [[ ! -f $MEM_CACHE ]] || [[ $(( $(date +%s) - $(stat -c %Y "$MEM_CACHE") )) -gt 60 ]]; then
        mem_info=$(free -h | grep -v +)
        echo "$mem_info" > "$MEM_CACHE"
    else
        mem_info=$(cat "$MEM_CACHE")
    fi
    
    local total used free usage_percent
    total=$(echo "$mem_info" | awk '/Mem:/ {print $2}')
    used=$(echo "$mem_info" | awk '/Mem:/ {print $3}')
    free=$(echo "$mem_info" | awk '/Mem:/ {print $4}')
    usage_percent=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    
    if (( $(echo "$usage_percent > $MEM_THRESHOLD" | bc -l) )); then
        log WARN "High memory usage: $usage_percent%"
        echo -e "${RED}Memory Usage:${NORMAL}"
    else
        echo -e "${GREEN}Memory Usage:${NORMAL}"
    fi
    echo "Total: $total"
    echo "Used: $used"
    echo "Free: $free"
}

# Improved process monitoring
check_top5_mem_proc() {
    ps aux --sort=-%mem | head -n 6 | tail -n 5 | \
        awk 'BEGIN {printf "%-20s %-10s %-10s %s\n", "USER", "PID", "MEM%", "COMMAND"} 
             {printf "%-20s %-10s %-10s %s\n", $1, $2, $4, $11}'
}

# Enhanced email alert function with HTML formatting
send_email_alert() {
    local output_path=$1
    local email_body="<html><body>"
    email_body+="<h2>System Monitoring Alert - $HOSTNAME</h2>"
    email_body+="<p>The following thresholds have been exceeded:</p><ul>"
    
    local threshold_exceeded=false
    
    if [ "$(df / | tail -1 | awk '{print $5}' | tr -d '%')" -gt "$DISK_THRESHOLD" ]; then
        email_body+="<li style='color: red;'>Disk usage is above ${DISK_THRESHOLD}%</li>"
        threshold_exceeded=true
    fi
    
    if (( $(echo "$(cat "$CPU_CACHE") > $CPU_THRESHOLD" | bc -l) )); then
        email_body+="<li style='color: red;'>CPU usage is above ${CPU_THRESHOLD}%</li>"
        threshold_exceeded=true
    fi
    
    local mem_percent
    mem_percent=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    if (( $(echo "$mem_percent > $MEM_THRESHOLD" | bc -l) )); then
        email_body+="<li style='color: red;'>Memory usage is above ${MEM_THRESHOLD}%</li>"
        threshold_exceeded=true
    fi
    
    email_body+="</ul><p>Please check the attached report for details.</p>"
    email_body+="</body></html>"
    
    if [[ $threshold_exceeded == true ]] && [[ -n $EMAIL_TO ]]; then
        if command -v mail >/dev/null 2>&1; then
            echo -e "Content-Type: text/html\n$email_body" | mail -s "$(echo -e "Subject: $EMAIL_SUBJECT\nContent-Type: text/html")" -a "$output_path" "$EMAIL_TO"
            log INFO "Alert email sent to $EMAIL_TO"
        else
            log ERROR "'mail' command not found. Please install mailutils to enable email alerts."
        fi
    fi
}

# Main report generation function with improved error handling
generate_report() {
    local output_path="${OUTPUT_DIR}/${OUTPUT_FILE}"
    
    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR" || { log ERROR "Failed to create output directory"; exit 1; }
    
    # Check required commands
    check_command "top"
    check_command "ps"
    check_command "df"
    check_command "free"
    check_command "bc"
    
    {
        echo -e "${BLUE}System Monitoring Report - $DATE${NORMAL}"
        echo -e "====================================================================\n"
        
        echo -e "${BLUE}System Information:${NORMAL}"
        echo "Hostname: $HOSTNAME"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        
        echo -e "\n${BLUE}CPU Usage:${NORMAL}"
        check_cpu_usage
        
        echo -e "\n${BLUE}Memory Usage:${NORMAL}"
        check_memory_usage
        
        echo -e "\n${BLUE}Disk Usage:${NORMAL}"
        check_disk_usage
        
        echo -e "\n${BLUE}Top 5 Memory-Consuming Processes:${NORMAL}"
        check_top5_mem_proc
        
        echo -e "\n${BLUE}Network Connections:${NORMAL}"
        netstat -tuln | grep LISTEN
        
        echo -e "\n========================================================================="
    } | tee "$output_path"
    
    log INFO "Report has been saved to: $output_path"
    
    # Send email if configured
    if [[ $SEND_EMAIL == true ]]; then
        send_email_alert "$output_path"
    fi
}

# Parse command line arguments with improved validation
while getopts "d:c:m:o:e:vh" opt; do
    case $opt in
        d) 
            if [[ $OPTARG =~ ^[0-9]+$ ]] && [ "$OPTARG" -ge 0 ] && [ "$OPTARG" -le 100 ]; then
                DISK_THRESHOLD=$OPTARG
            else
                log ERROR "Invalid disk threshold: $OPTARG (must be 0-100)"
                exit 1
            fi
            ;;
        c)
            if [[ $OPTARG =~ ^[0-9]+$ ]] && [ "$OPTARG" -ge 0 ] && [ "$OPTARG" -le 100 ]; then
                CPU_THRESHOLD=$OPTARG
            else
                log ERROR "Invalid CPU threshold: $OPTARG (must be 0-100)"
                exit 1
            fi
            ;;
        m)
            if [[ $OPTARG =~ ^[0-9]+$ ]] && [ "$OPTARG" -ge 0 ] && [ "$OPTARG" -le 100 ]; then
                MEM_THRESHOLD=$OPTARG
            else
                log ERROR "Invalid memory threshold: $OPTARG (must be 0-100)"
                exit 1
            fi
            ;;
        o) OUTPUT_FILE=$OPTARG ;;
        e) 
            EMAIL_TO=$OPTARG
            SEND_EMAIL=true
            ;;
        v) VERBOSE=true ;;
        h) show_help ;;
        ?) log ERROR "Invalid option. Use -h for help."; exit 1 ;;
    esac
done

# Run the main function
generate_report
