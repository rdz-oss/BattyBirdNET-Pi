#!/usr/bin/env bash
# Sudoers Helper: Updates systemd timers based on current birdnet.conf settings
# This script is designed to be run by www-data via sudoers.

set -e

CONFIG_FILE="/etc/birdnet/birdnet.conf"
TEMPLATES_DIR="$HOME/BirdNET-Pi/templates"
SYSTEMD_DIR="/etc/systemd/system"

# Source config to get values
source "$CONFIG_FILE"

# Update Daily Timer
if [ -f "$TEMPLATES_DIR/backup_detections_daily.timer" ]; then
  sed "s/\${S3_BACKUP_TIME}/$S3_BACKUP_TIME/g" "$TEMPLATES_DIR/backup_detections_daily.timer" > "$SYSTEMD_DIR/backup_detections_daily.timer"
  echo "Updated daily timer to $S3_BACKUP_TIME"
fi

# Update Watchdog Timer
if [ -f "$TEMPLATES_DIR/backup_watchdog.timer" ]; then
  sed "s/\${S3_BACKUP_WATCHDOG_INTERVAL}/$S3_BACKUP_WATCHDOG_INTERVAL/g" "$TEMPLATES_DIR/backup_watchdog.timer" > "$SYSTEMD_DIR/backup_watchdog.timer"
  echo "Updated watchdog interval to $S3_BACKUP_WATCHDOG_INTERVAL"
fi

# Reload and restart timers
systemctl daemon-reload
systemctl restart backup_detections_daily.timer 2>/dev/null || true
systemctl restart backup_watchdog.timer 2>/dev/null || true

echo "Backup timers updated successfully."