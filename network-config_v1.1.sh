#!/bin/bash

# Script Name: network-config_v1.1.sh
# Description: Script to configure network interface settings on RedHat distros with nmcli
# Usage: ./network-config_v1.1.sh [-i INTERFACE] [-p IP_ADDRESS] [-c CIDR] [-g GATEWAY] [-d "DNS1 DNS2"]
# Usage Example with custom settings :
#       sudo ./network-config_v1.1.sh -i eth0 -p 192.168.1.100 -c 24 -g 192.168.1.1 -d "8.8.8.8 8.8.4.4"
# Author: Abdullah Abaza
# Date: 2023-11-14
# Version: 1.1

# Exit on any error
set -e

# Default Variables
INTERFACE="ens160"
CONNECTION_NAME="static"
STATIC_IP="192.168.43.2"
CIDR=24
GATEWAY="192.168.43.1"
DNS1="1.1.1.1"
DNS2="1.0.0.1"
BACKUP_DIR="/tmp/network-backup"
VERBOSE=false
DHCP=false

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Configure network interface with static IP settings"
    echo
    echo "Options:"
    echo "  -i INTERFACE    Network interface (default: ens160)"
    echo "  -p IP_ADDRESS   Static IP address (default: 192.168.43.2)"
    echo "  -c CIDR        CIDR notation (default: 24)"
    echo "  -g GATEWAY     Gateway address (default: 192.168.43.1)"
    echo "  -d DNS        DNS servers, space-separated (default: '1.1.1.1 1.0.0.1')"
    echo "  -v            Enable verbose output"
    echo "  -h            Show this help message"
    echo "  -a            Enable DHCP configuration"
    exit 0
}

# Parse command line arguments
while getopts "i:p:c:g:d:vha" opt; do
    case $opt in
        i) INTERFACE="$OPTARG" ;;
        p) STATIC_IP="$OPTARG" ;;
        c) CIDR="$OPTARG" ;;
        g) GATEWAY="$OPTARG" ;;
        d) DNS_SERVERS="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) show_help ;;
        a) DHCP=true ;;
        ?) echo "Invalid option. Use -h for help."; exit 1 ;;
    esac
done

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message"
}

# Verbose logging function
verbose() {
    if [[ "$VERBOSE" = true ]]; then
        log "DEBUG" "$@"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root or with sudo privileges"
        exit 1
    fi
}

# Check if required commands exist
check_requirements() {
    local commands=("nmcli" "ip" "ping")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "Required command '$cmd' not found"
            exit 1
        fi
    done
}

# Validate IP address format
validate_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log "ERROR" "Invalid IP address format: $ip"
        exit 1
    fi
}

# Backup current network configuration
backup_network_config() {
    log "INFO" "Creating network configuration backup..."
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/network_backup_$timestamp"
    
    nmcli con show "$INTERFACE" > "${backup_file}_connection.txt" 2>/dev/null || true
    ip addr show > "${backup_file}_ip_addr.txt"
    
    log "INFO" "Backup saved in $BACKUP_DIR"
    verbose "Backup files created: ${backup_file}_connection.txt, ${backup_file}_ip_addr.txt"
}

# Validate interface existence
validate_interface() {
    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        log "ERROR" "Interface $INTERFACE does not exist"
        echo "Available interfaces:"
        ip link show | grep -E '^[0-9]+:' | cut -d: -f2
        exit 1
    fi
    verbose "Interface $INTERFACE validated successfully"
}

# Function to set a static IP
configure_static_ip() {
    log "INFO" "Configuring static IP..."
    
    # Validate IP addresses
    validate_ip "$STATIC_IP"
    validate_ip "$GATEWAY"
    
    # Remove existing connection if it exists
    verbose "Removing existing connection named 'static' if it exists"
    nmcli con delete "$CONNECTION_NAME" 2>/dev/null || true
    
    # Create new connection with the name "static"
    if ! nmcli con add type ethernet autoconnect yes con-name "$CONNECTION_NAME" ifname "$INTERFACE"; then
        log "ERROR" "Failed to add network connection"
        exit 1
    fi
    
    # Configure IP settings
    verbose "Setting IP address: $STATIC_IP/$CIDR"
    nmcli con mod "$CONNECTION_NAME" ipv4.addresses "$STATIC_IP/$CIDR"
    
    verbose "Setting gateway: $GATEWAY"
    nmcli con mod "$CONNECTION_NAME" ipv4.gateway "$GATEWAY"
    
    verbose "Setting DNS servers: $DNS1 $DNS2"
    nmcli con mod "$CONNECTION_NAME" ipv4.dns "$DNS1 $DNS2"
    
    verbose "Setting method to manual"
    nmcli con mod "$CONNECTION_NAME" ipv4.method manual
    
    log "INFO" "Static IP configuration completed successfully"
}

# Function to rollback to previous network configuration
rollback_network_config() {
    log "INFO" "Rolling back to previous network configuration..."
    local latest_backup=$(ls -t "$BACKUP_DIR" | grep '_connection.txt' | head -n 1)
    if [[ -n "$latest_backup" ]]; then
        local backup_file="${BACKUP_DIR}/${latest_backup%_connection.txt}"
        nmcli con load "${backup_file}_connection.txt" || log "ERROR" "Failed to load previous connection settings"
        log "INFO" "Rollback completed successfully"
    else
        log "ERROR" "No backup found to rollback"
    fi
}

# Function to set DHCP
configure_dhcp() {
    log "INFO" "Configuring DHCP..."
    
    # Remove existing connection if it exists
    verbose "Removing existing connection for $INTERFACE if it exists"
    nmcli con delete "$INTERFACE" 2>/dev/null || true
    
    # Create new connection with DHCP
    if ! nmcli con add type ethernet autoconnect yes con-name "$INTERFACE" ifname "$INTERFACE"; then
        log "ERROR" "Failed to add network connection"
        exit 1
    fi
    
    verbose "Setting method to auto"
    nmcli con mod "$INTERFACE" ipv4.method auto
    
    log "INFO" "DHCP configuration completed successfully"
}

# Function to restart the network service 
restart_network() {
    log "INFO" "Restarting network service..."
    if [[ "$DHCP" = true ]]; then
        nmcli con down "$INTERFACE"
        nmcli con up "$INTERFACE"
    else
        nmcli con down "static"
        if ! nmcli con up "static"; then
            log "ERROR" "Failed to bring up network interface"
            log "INFO" "Rolling back to previous configuration..."
            rollback_network_config
            exit 1
        fi
    fi
    log "INFO" "Network service restarted successfully"
}

# Function to display current network configuration 
show_network_config() {
    log "INFO" "Current network configuration:"
    echo "----------------------------"
    ip addr show "$INTERFACE"
    echo "----------------------------"
    echo "Connection status:"
    nmcli
    echo "----------------------------"
    
    # Test connectivity
    log "INFO" "Testing connectivity..."
    if ping -c 1 "$GATEWAY" >/dev/null 2>&1; then
        log "INFO" "Gateway is reachable"
    else
        log "WARNING" "Cannot reach gateway"
    fi
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log "INFO" "Internet is reachable"
    else
        log "WARNING" "Cannot reach internet"
    fi
}

# Function to automate the whole network configuration
automate_network_configuration() {
    check_root
    check_requirements
    validate_interface
    backup_network_config
    if [[ "$DHCP" = true ]]; then
        configure_dhcp
    else
        configure_static_ip
    fi
    restart_network
    show_network_config
}

# Trap for cleanup on script exit
trap 'log "INFO" "Script execution completed"' EXIT

# Main execution
log "INFO" "Starting network configuration..."
automate_network_configuration 