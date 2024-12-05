#!/bin/bash

# Script Name: network-congig_v1.0.sh
# Description: script to configure nework interface settings on redhat destros with nmcli
# Usage: ./network-congig_v1.0.sh
# Author: Abdullah Abaza
# Date: 2021-09-05
# Version: 1.0

# Variables
INTERFACE="ens160"
STATIC_IP="192.168.43.2"
CIDR=24
GATEWAY="192.168.43.1"
DNS1="1.1.1.1"
DNS2="1.0.0.1"

# Function to set a static IP
configure_static_ip() {
    echo "Configuring satic IP..."
    sudo nmcli con add type ethernet autoconnect yes con-name $INTERFACE ifname $INTERFACE
    sudo nmcli con mod "$INTERFACE" ipv4.addresses "$STATIC_IP/$CIDR"
    sudo nmcli con mod "$INTERFACE" ipv4.gateway $GATEWAY
    sudo nmcli con mod "$INTERFACE" ipv4.dns $DNS1 $DNS2
    sudo nmcli con mod "$INTERFACE" ipv4.method manual
    echo "Static IP configuration done."
}

# Function to restart the network service 
restart_network() {
    echo "Restarting network service..."
    sudo nmcli con up "$INTERFACE"
    echo "Network service restarted."
}

# Function to display current network configuration 
show_network_config() {
    echo "Current network configuration:"
    ip addr show "$INTERFACE"
}

# Function to automate the whole network configuration
automate_network_configuration() {
    configure_static_ip
    restart_network
    show_network_config
}

# Excute the automation function

automate_network_configuration

