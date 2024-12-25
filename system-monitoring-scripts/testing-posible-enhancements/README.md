# System Monitoring Scripts

A comprehensive collection of Bash scripts for monitoring system resources, performance metrics, and sending automated alerts through multiple channels.

## Version History

- **v1.0**: Basic system monitoring with email alerts
- **v1.1**: Enhanced monitoring with improved error handling and caching
- **v1.2**: Advanced monitoring with multi-channel notifications, security features, and historical data tracking

## Features

### Core Monitoring
- Real-time system resource monitoring
  - CPU usage and load average
  - Memory utilization (RAM and swap)
  - Disk space usage and I/O statistics
  - Network bandwidth monitoring
  - System processes and services
- Customizable alert thresholds
- Historical data tracking and trend analysis
- Service status monitoring
- System file integrity checking

### Alert System
- Multi-channel notifications:
  - Email (via Postfix/Gmail SMTP)
  - Slack
  - Discord
  - Telegram
- Alert throttling to prevent notification spam
- Configurable alert severity levels
- Alert history tracking

### Security Features
- System file integrity monitoring
- Failed login attempt tracking
- Audit logging
- Secure credential handling

### Data Management
- Automatic log rotation
- Historical data retention
- CSV format data export
- Compressed log archives

## Installation

### 1. Dependencies
```bash
# Install required packages
sudo apt update
sudo apt install -y \
    postfix \
    mailutils \
    libsasl2-modules \
    sysstat \
    curl \
    gzip \
    bc
```

### 2. Email Configuration (Gmail SMTP)

1. Generate Gmail App Password:
   - Go to Google Account Settings
   - Security → 2-Step Verification → App passwords
   - Create new App password for "Mail"

2. Configure Postfix:
```bash
sudo nano /etc/postfix/main.cf
```
Add/modify:
```
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

3. Create SASL password file:
```bash
sudo nano /etc/postfix/sasl_passwd
```
Add:
```
[smtp.gmail.com]:587 your-email@gmail.com:your-app-password
```

4. Secure the configuration:
```bash
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix
```

## Configuration

### 1. Script Configuration
Create configuration file:
```bash
sudo mkdir -p /etc/system-monitor
sudo nano /etc/system-monitor/config.conf
```

Example configuration:
```bash
# Thresholds
DISK_THRESHOLD=80
CPU_THRESHOLD=90
MEM_THRESHOLD=85
LOAD_THRESHOLD=4
BANDWIDTH_THRESHOLD=80

# Notification Settings
EMAIL_TO="your-email@gmail.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/YOUR/WEBHOOK/URL"
TELEGRAM_BOT_TOKEN="your-bot-token"
TELEGRAM_CHAT_ID="your-chat-id"

# Data Management
MAX_LOG_SIZE=10M
RETENTION_DAYS=30
ENABLE_AUDIT=true
ENABLE_HISTORY=true
```

### 2. Directory Setup
```bash
sudo mkdir -p /var/log/system-monitor
sudo mkdir -p /var/lib/system-monitor
sudo chmod 755 /var/log/system-monitor
sudo chmod 700 /var/lib/system-monitor
```

## Usage

### Basic Usage
```bash
# Run with default settings
./system-monitoring_v1.2.sh

# Run with email notifications
./system-monitoring_v1.2.sh -e your-email@gmail.com

# Run with custom thresholds
./system-monitoring_v1.2.sh -d 75 -c 85 -m 80

# Run with verbose output
./system-monitoring_v1.2.sh -v

# Run with all features enabled
./system-monitoring_v1.2.sh -e your-email@gmail.com -v -a
```

### Command Line Options
```
-d THRESHOLD  Disk usage warning threshold (default: 80%)
-c THRESHOLD  CPU usage warning threshold (default: 90%)
-m THRESHOLD  Memory usage warning threshold (default: 90%)
-l THRESHOLD  Load average threshold (default: 4)
-b THRESHOLD  Bandwidth usage threshold (default: 80%)
-o FILE       Output log file name
-e EMAIL      Email address for alerts
-s URL        Slack webhook URL
-t TOKEN      Telegram bot token
-v            Enable verbose output
-a            Enable audit logging
-h            Show help message
```

### Running as a Service

1. Create systemd service file:
```bash
sudo nano /etc/systemd/system/system-monitor.service
```

```ini
[Unit]
Description=System Monitoring Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/system-monitoring_v1.2.sh -e your-email@gmail.com -a
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
```

2. Enable and start the service:
```bash
sudo systemctl enable system-monitor
sudo systemctl start system-monitor
```

## Monitoring Data

### Log Files
- Main log: `/var/log/system-monitor/system_monitor.log`
- Audit log: `/var/log/system-monitor/audit.log`
- Alert history: `/var/log/system-monitor/alert_history.log`

### Historical Data (CSV)
- Disk usage: `/var/log/system-monitor/disk_history.csv`
- Network usage: `/var/log/system-monitor/network_history.csv`

### System Integrity
- Checksum database: `/var/lib/system-monitor/checksums.db`

## Troubleshooting

### Common Issues

1. Email notifications not working:
   - Check Postfix logs: `sudo tail -f /var/log/mail.log`
   - Verify Gmail App password
   - Ensure correct permissions on sasl_passwd

2. High resource usage:
   - Adjust monitoring intervals
   - Increase alert thresholds
   - Check log file sizes
   - Adjust MAX_LOG_SIZE in config

3. Missing data points:
   - Check disk space
   - Verify write permissions
   - Check service status

4. Permission issues:
   - Run with sudo for system file monitoring
   - Check directory permissions
   - Verify user permissions for log files

## Security Considerations

1. Protect sensitive files:
   - Keep Gmail App password secure
   - Protect webhook URLs
   - Secure the config.conf file

2. Regular maintenance:
   - Monitor log file growth
   - Review alert history
   - Update checksums database
   - Clean old log archives

3. Access control:
   - Restrict script execution to authorized users
   - Protect monitoring data
   - Secure notification endpoints

## Contributing

Feel free to contribute by:
- Reporting bugs
- Suggesting new features
- Submitting pull requests
- Improving documentation

## License

This project is licensed under the terms of the LICENSE file included in this repository.

---

# Experimental System Monitoring Enhancements

This directory contains experimental enhancements to the original system monitoring script. These versions (v1.1 and v1.2) explore additional features and improvements but are currently in testing phase.

## Version Overview

### Version 1.1
Enhanced version with improved error handling and performance optimizations:
- Better error handling with `set -euo pipefail`
- Improved caching mechanism for system stats
- Enhanced logging capabilities
- Better code organization and documentation

### Version 1.2
Advanced features exploration with multi-channel notifications:
- Multiple notification channels (Slack, Discord, Telegram)
- Security enhancements (file integrity, audit logging)
- Historical data tracking and analysis
- Advanced service monitoring
- Network bandwidth monitoring
- Log rotation and management

## ⚠️ Important Note
These versions are experimental and under testing. For production use, please refer to the stable v1.0 in the parent directory.

## Directory Structure
```
testing-posible-enhancements/
├── system-monitoring_v1.1.sh
├── system-monitoring_v1.2.sh
└── README.md
```

## Testing Status

### Version 1.1
- [x] Basic functionality testing
- [x] Error handling improvements
- [x] Performance optimization
- [ ] Production environment testing
- [ ] Long-term stability testing

### Version 1.2
- [x] Feature implementation
- [ ] Security testing
- [ ] Performance impact assessment
- [ ] Integration testing
- [ ] Load testing
- [ ] Documentation completion

## Future Considerations
1. Integration with monitoring platforms
2. Container environment support
3. Cloud service integration
4. Machine learning for anomaly detection
5. Advanced visualization capabilities

## Contributing
Feel free to test these versions and provide feedback. Please note any issues or suggestions for improvement.

## License
This project is licensed under the terms of the LICENSE file included in the root repository.
