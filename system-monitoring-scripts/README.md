# System Monitoring Script (v1.0)

A reliable Bash script for monitoring system resources and sending email alerts using Gmail SMTP.

## Overview
This script provides essential system monitoring capabilities with email notifications for Linux systems. It tracks CPU, memory, and disk usage, and alerts when specified thresholds are exceeded.

## Features
- System resource monitoring:
  - CPU usage tracking
  - Memory utilization
  - Disk space monitoring
  - Process monitoring
- Email notifications via Gmail SMTP
- Customizable thresholds
- Detailed logging
- Top process monitoring

## Prerequisites
- Linux-based operating system
- Postfix mail server
- mailutils package
- Gmail account with App Password

## Installation

### 1. Install Required Packages
```bash
sudo apt update
sudo apt install postfix mailutils libsasl2-modules
```

### 2. Configure Gmail SMTP
1. Generate Gmail App Password:
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Generate new App password for "Mail"

2. Configure Postfix:
```bash
sudo nano /etc/postfix/main.cf
```
Add:
```
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

3. Set up SMTP credentials:
```bash
sudo nano /etc/postfix/sasl_passwd
```
Add:
```
[smtp.gmail.com]:587 your-email@gmail.com:your-app-password
```

4. Secure and apply settings:
```bash
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix
```

## Usage

### Basic Usage
```bash
./system-monitoring_v1.0.sh -e "your@email.com"
```

### With SMTP Configuration
```bash
./system-monitoring_v1.0.sh -e "your@email.com" \
    --smtp-server=smtp.gmail.com \
    --smtp-port=587 \
    --smtp-user=your@gmail.com
```

### Command Line Options
```
-d THRESHOLD       Disk Usage Warning Threshold (default: 80%)
-c THRESHOLD       CPU Usage Warning Threshold (default: 90%)
-m THRESHOLD       Memory Usage Warning Threshold (default: 90%)
-o FILE           Output Log File Name
-e EMAIL          Email address to send alerts to
-h                Show help message
--smtp-server     SMTP server for email alerts
--smtp-port       SMTP port (default: 587)
--smtp-user       SMTP username
--mail-debug      Enable email debugging
```

## Configuration
The script uses the following default thresholds:
```bash
DISK_THRESHOLD=80   # 80% disk usage
CPU_THRESHOLD=90    # 90% CPU usage
MEM_THRESHOLD=90    # 90% memory usage
```

## Monitoring Checks

### Disk Usage Monitoring
- Monitors all mounted filesystems
- Alerts when usage exceeds threshold
- Shows usage percentage and available space

### CPU Usage Monitoring
- Tracks CPU utilization percentage
- Alerts on sustained high usage
- Shows top CPU-consuming processes

### Memory Usage Monitoring
- Monitors RAM and swap usage
- Tracks memory-intensive processes
- Shows detailed memory statistics

### Process Monitoring
- Lists top 5 memory-consuming processes
- Shows process user, PID, and resource usage
- Helps identify resource-heavy applications

## Log Files
- System statistics: `/var/log/system_monitor.log`
- Contains timestamped monitoring data
- Includes alert history and thresholds

## Testing
```bash
# Test email configuration
echo "Test email" | mail -s "Test Subject" your-email@gmail.com

# Run with debugging
./system-monitoring_v1.0.sh -e "your@email.com" --mail-debug
```

## Troubleshooting

### Email Issues
1. Check Postfix logs:
```bash
sudo tail -f /var/log/mail.log
```
2. Verify Gmail App password
3. Check Postfix configuration
4. Ensure proper permissions on config files

### Script Issues
1. Check execute permissions:
```bash
chmod +x system-monitoring_v1.0.sh
```
2. Verify required packages are installed
3. Check log files for errors

## Experimental Versions
Enhanced versions (v1.1 and v1.2) with additional features are available in the `testing-posible-enhancements` directory. These versions are under testing and not recommended for production use.

## License
This project is licensed under the terms of the LICENSE file included in this repository.
