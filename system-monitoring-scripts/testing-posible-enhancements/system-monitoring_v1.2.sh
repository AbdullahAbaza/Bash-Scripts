#!/bin/bash

# Script Name: system-monitoring_v1.2.sh
# Description: Advanced system resource monitoring script with enhanced features
# Author: Abdullah Abaza
# Date: 2023-12-25
# Version: 1.2

# Exit on any error, undefined variable, and prevent pipe failures
set -euo pipefail

# Load configuration from external file if it exists
CONFIG_FILE="/etc/system-monitor/config.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Initialize checksum database
CHECKSUM_DB="/var/lib/system-monitor/checksums.db"
mkdir -p "$(dirname "$CHECKSUM_DB")"
touch "$CHECKSUM_DB"

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
readonly PURPLE=$(tput setaf 5)
readonly NORMAL=$(tput sgr0)

# Default Variables with readonly protection
readonly DEFAULT_DISK_THRESHOLD=80
readonly DEFAULT_CPU_THRESHOLD=90
readonly DEFAULT_MEM_THRESHOLD=90
readonly DEFAULT_LOAD_THRESHOLD=4
readonly DEFAULT_BANDWIDTH_THRESHOLD=80
readonly DEFAULT_OUTPUT_DIR="/var/log/system-monitor"
readonly DEFAULT_OUTPUT_FILE="system_monitor.log"
readonly HOSTNAME=$(hostname)
readonly DATE=$(date '+%Y-%m-%d %H:%M:%S')
readonly SCRIPT_VERSION="1.2"

# Alert configuration
declare -A ALERT_LEVELS=(
    ["CRITICAL"]=0
    ["WARNING"]=1
    ["INFO"]=2
)
ALERT_HISTORY_FILE="/var/log/system-monitor/alert_history.log"
ALERT_THROTTLE_SECONDS=300  # 5 minutes between similar alerts

# Notification endpoints
SLACK_WEBHOOK=""
DISCORD_WEBHOOK=""
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Configurable variables
DISK_THRESHOLD=$DEFAULT_DISK_THRESHOLD
CPU_THRESHOLD=$DEFAULT_CPU_THRESHOLD
MEM_THRESHOLD=$DEFAULT_MEM_THRESHOLD
LOAD_THRESHOLD=$DEFAULT_LOAD_THRESHOLD
BANDWIDTH_THRESHOLD=$DEFAULT_BANDWIDTH_THRESHOLD
SEND_NOTIFICATIONS=false
EMAIL_TO=""
EMAIL_FROM="system.monitor@$HOSTNAME"
EMAIL_SUBJECT="System Monitor Alert - $HOSTNAME"
OUTPUT_DIR=$DEFAULT_OUTPUT_DIR
OUTPUT_FILE=$DEFAULT_OUTPUT_FILE
VERBOSE=false
ENABLE_AUDIT=true
ENABLE_HISTORY=true
MAX_LOG_SIZE=10M  # Maximum size for log files
RETENTION_DAYS=30  # Days to keep historical data

# Temporary files and directories
readonly TMP_DIR=$(mktemp -d)
readonly CPU_CACHE="$TMP_DIR/cpu.cache"
readonly MEM_CACHE="$TMP_DIR/mem.cache"
readonly NETWORK_CACHE="$TMP_DIR/network.cache"
readonly IO_CACHE="$TMP_DIR/io.cache"

# Cleanup function
cleanup() {
    rm -rf "$TMP_DIR"
    # Kill background processes
    jobs -p | xargs -r kill
}
trap cleanup EXIT

# Enhanced logging function with severity levels
log() {
    local level=$1
    shift
    local color=""
    case $level in
        CRITICAL) color=$RED ;;
        WARNING) color=$YELLOW ;;
        INFO) color=$GREEN ;;
        DEBUG) color=$BLUE ;;
        *) color=$NORMAL ;;
    esac
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_message="[$timestamp] [$level] $*"
    
    echo -e "${color}${log_message}${NORMAL}"
    
    if [[ $ENABLE_AUDIT == true ]]; then
        echo "$log_message" >> "$OUTPUT_DIR/audit.log"
    fi
    
    if [[ $VERBOSE == true ]]; then
        echo -e "${color}${log_message}${NORMAL}" >&2
    fi
}

# Function to rotate logs
rotate_logs() {
    local log_file=$1
    if [[ -f "$log_file" ]]; then
        local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file")
        if (( size > $(numfmt --from=auto "$MAX_LOG_SIZE") )); then
            local timestamp=$(date +%Y%m%d-%H%M%S)
            gzip -c "$log_file" > "${log_file}.${timestamp}.gz"
            : > "$log_file"
            log INFO "Rotated log file: $log_file"
            
            # Clean old logs
            find "$(dirname "$log_file")" -name "$(basename "$log_file")*.gz" -mtime +"$RETENTION_DAYS" -delete
        fi
    fi
}

# Function to check system file integrity
check_system_integrity() {
    local files_to_check=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/sudoers"
    )
    
    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            local current_sum=$(sha256sum "$file" | cut -d' ' -f1)
            local stored_sum=$(grep "^${file}:" "$CHECKSUM_DB" | cut -d: -f2)
            
            if [[ -z "$stored_sum" ]]; then
                echo "${file}:${current_sum}" >> "$CHECKSUM_DB"
            elif [[ "$current_sum" != "$stored_sum" ]]; then
                log CRITICAL "System file changed: $file"
                send_alert "CRITICAL" "System file integrity violation detected: $file"
            fi
        fi
    done
}

# Enhanced disk usage check with I/O statistics
check_disk_usage() {
    local disk_info
    disk_info=$(df -h | awk 'NR>1 {print $6,$5}' | sort)
    
    # Get disk I/O stats
    local io_stats
    if [[ ! -f $IO_CACHE ]] || [[ $(( $(date +%s) - $(stat -c %Y "$IO_CACHE") )) -gt 60 ]]; then
        io_stats=$(iostat -x 1 2 | tail -n +4)
        echo "$io_stats" > "$IO_CACHE"
    else
        io_stats=$(cat "$IO_CACHE")
    fi
    
    echo -e "\n${BLUE}Disk I/O Statistics:${NORMAL}"
    echo "$io_stats"
    
    while IFS= read -r line; do
        local mount_point usage_percent
        mount_point=$(echo "$line" | awk '{print $1}')
        usage_percent=$(echo "$line" | awk '{print $2}' | tr -d '%')
        
        if [ "$usage_percent" -gt "$DISK_THRESHOLD" ]; then
            log WARNING "High disk usage on $mount_point: $usage_percent%"
            send_alert "WARNING" "High disk usage on $mount_point: $usage_percent%"
        fi
        
        # Store historical data
        if [[ $ENABLE_HISTORY == true ]]; then
            echo "$DATE,$mount_point,$usage_percent" >> "$OUTPUT_DIR/disk_history.csv"
        fi
    done <<< "$disk_info"
}

# Network bandwidth monitoring
check_network_bandwidth() {
    local interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v "lo"))
    
    for interface in "${interfaces[@]}"; do
        local rx_bytes_start tx_bytes_start
        rx_bytes_start=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
        tx_bytes_start=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
        
        sleep 1
        
        local rx_bytes_end tx_bytes_end
        rx_bytes_end=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
        tx_bytes_end=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
        
        local rx_rate=$((rx_bytes_end - rx_bytes_start))
        local tx_rate=$((tx_bytes_end - tx_bytes_start))
        
        echo -e "\n${BLUE}Network Interface: $interface${NORMAL}"
        echo "RX Rate: $(numfmt --to=iec-i --suffix=B/s $rx_rate)"
        echo "TX Rate: $(numfmt --to=iec-i --suffix=B/s $tx_rate)"
        
        # Store historical data
        if [[ $ENABLE_HISTORY == true ]]; then
            echo "$DATE,$interface,$rx_rate,$tx_rate" >> "$OUTPUT_DIR/network_history.csv"
        fi
    done
}

# Enhanced service monitoring
check_services() {
    local services=(
        "sshd"
        "nginx"
        "apache2"
        "mysql"
        "postgresql"
    )
    
    echo -e "\n${BLUE}Service Status:${NORMAL}"
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}$service: Running${NORMAL}"
        else
            log WARNING "Service $service is not running"
            send_alert "WARNING" "Service $service is not running"
        fi
    done
}

# Function to send alerts through multiple channels
send_alert() {
    local level=$1
    local message=$2
    local alert_key="${level}_${message}"
    local last_alert_time
    
    # Check alert throttling
    if [[ -f "$ALERT_HISTORY_FILE" ]]; then
        last_alert_time=$(grep "^${alert_key}:" "$ALERT_HISTORY_FILE" | tail -1 | cut -d: -f2)
        if [[ -n "$last_alert_time" ]]; then
            local time_diff=$(($(date +%s) - last_alert_time))
            if (( time_diff < ALERT_THROTTLE_SECONDS )); then
                return
            fi
        fi
    fi
    
    # Record alert
    echo "${alert_key}:$(date +%s)" >> "$ALERT_HISTORY_FILE"
    
    # Email notification
    if [[ -n "$EMAIL_TO" ]]; then
        send_email_alert "$level" "$message"
    fi
    
    # Slack notification
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"[$level] $message\"}" \
            "$SLACK_WEBHOOK"
    fi
    
    # Discord notification
    if [[ -n "$DISCORD_WEBHOOK" ]]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"content\":\"[$level] $message\"}" \
            "$DISCORD_WEBHOOK"
    fi
    
    # Telegram notification
    if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        curl -s -X POST \
            "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=[$level] $message"
    fi
}

# Enhanced report generation
generate_report() {
    mkdir -p "$OUTPUT_DIR"
    local output_path="${OUTPUT_DIR}/${OUTPUT_FILE}"
    
    # Rotate logs if needed
    rotate_logs "$output_path"
    
    {
        echo -e "${BLUE}System Monitoring Report - $DATE${NORMAL}"
        echo -e "Version: $SCRIPT_VERSION"
        echo -e "====================================================================\n"
        
        # System information
        echo -e "${BLUE}System Information:${NORMAL}"
        echo "Hostname: $HOSTNAME"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo "Last boot: $(who -b | awk '{print $3,$4}')"
        
        # Resource usage
        check_cpu_usage
        check_memory_usage
        check_disk_usage
        check_network_bandwidth
        check_services
        
        # Process information
        echo -e "\n${BLUE}Top 5 CPU-Consuming Processes:${NORMAL}"
        ps aux --sort=-%cpu | head -6
        
        echo -e "\n${BLUE}Top 5 Memory-Consuming Processes:${NORMAL}"
        ps aux --sort=-%mem | head -6
        
        # Security checks
        if [[ $ENABLE_AUDIT == true ]]; then
            check_system_integrity
            echo -e "\n${BLUE}Failed Login Attempts:${NORMAL}"
            grep "Failed password" /var/log/auth.log | tail -5
        fi
        
        echo -e "\n${BLUE}Open Network Connections:${NORMAL}"
        ss -tuln
        
        echo -e "\n========================================================================="
    } | tee "$output_path"
    
    log INFO "Report generated: $output_path"
}

# Parse command line arguments
parse_arguments() {
    while getopts "d:c:m:l:b:o:e:s:t:vah" opt; do
        case $opt in
            d) DISK_THRESHOLD=$OPTARG ;;
            c) CPU_THRESHOLD=$OPTARG ;;
            m) MEM_THRESHOLD=$OPTARG ;;
            l) LOAD_THRESHOLD=$OPTARG ;;
            b) BANDWIDTH_THRESHOLD=$OPTARG ;;
            o) OUTPUT_FILE=$OPTARG ;;
            e) 
                EMAIL_TO=$OPTARG
                SEND_NOTIFICATIONS=true
                ;;
            s) SLACK_WEBHOOK=$OPTARG ;;
            t) 
                TELEGRAM_BOT_TOKEN=$OPTARG
                read -p "Enter Telegram Chat ID: " TELEGRAM_CHAT_ID
                ;;
            v) VERBOSE=true ;;
            a) ENABLE_AUDIT=true ;;
            h) show_help ;;
            ?) log ERROR "Invalid option. Use -h for help."; exit 1 ;;
        esac
    done
}

# Main execution
parse_arguments "$@"
generate_report