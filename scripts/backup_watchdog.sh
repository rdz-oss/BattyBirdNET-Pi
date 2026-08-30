#!/usr/bin/env bash
# Watchdog script: Checks connectivity and triggers backup if overdue
set -e

source /etc/birdnet/birdnet.conf

# Check if backup is enabled
if [ "$S3_BACKUP_ENABLED" != "true" ]; then
  exit 0
fi

LOCK_FILE="$HOME/.birdnet_backup_lock"
LAST_RUN_FILE="$HOME/.birdnet_backup_last_run"
OVERDUE_SECONDS=86400 # 24 hours

# Parse arguments
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
fi

# Check for lock file (prevent overlapping runs)
if [ -f "$LOCK_FILE" ]; then
  echo "Backup already running (lock file exists). Skipping."
  exit 0
fi

# Create lock file
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Check connectivity
echo "Checking connectivity to $S3_BACKUP_PING_HOST..."
if ! ping -c 1 -W 5 "$S3_BACKUP_PING_HOST" > /dev/null 2>&1; then
  echo "No internet connection. Skipping backup."
  exit 0
fi

# Check if backup is overdue
CURRENT_TIME=$(date +%s)
LAST_RUN=0
if [ -f "$LAST_RUN_FILE" ]; then
  LAST_RUN=$(cat "$LAST_RUN_FILE")
fi

TIME_DIFF=$((CURRENT_TIME - LAST_RUN))

if [ "$TIME_DIFF" -lt "$OVERDUE_SECONDS" ]; then
  echo "Backup is not overdue (last run ${TIME_DIFF}s ago). Skipping."
  exit 0
fi

echo "Internet available and backup is overdue. Triggering backup..."

# Trigger the backup script
# We use the full path to ensure it runs correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/backup_detections.sh" "$DRY_RUN"

echo "Watchdog backup cycle complete."