#!/usr/bin/env bash
# Backup detections database to S3-compatible storage using rclone
set -e

source /etc/birdnet/birdnet.conf

# Check if backup is enabled
if [ "$S3_BACKUP_ENABLED" != "true" ]; then
  exit 0
fi

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
  echo "Error: rclone is not installed. Skipping backup."
  exit 1
fi

# Check if rclone remote and bucket are configured
if [ -z "$RCLONE_REMOTE" ] || [ -z "$RCLONE_BUCKET" ]; then
  echo "Error: RCLONE_REMOTE or RCLONE_BUCKET not configured in birdnet.conf. Skipping backup."
  exit 1
fi

DB_FILE="$HOME/BirdNET-Pi/scripts/birds.db"
DATE=$(date +%F)
CSV_FILE="/tmp/BirdNET-Pi-detections-${DATE}.csv"
LAST_RUN_FILE="$HOME/.birdnet_backup_last_run"

# Check if DB exists
if [ ! -f "$DB_FILE" ]; then
  echo "Error: Database not found at $DB_FILE. Skipping backup."
  exit 1
fi

# Parse arguments
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
  echo "[DRY RUN] Simulating backup..."
fi

# Dump SQLite DB to CSV
echo "Dumping database to CSV..."
echo "Date,Time,Sci_Name,Com_Name,Confidence,Lat,Lon,Cutoff,Week,Sens,Overlap" > "$CSV_FILE"
sqlite3 -header -csv "$DB_FILE" "SELECT Date, Time, Sci_Name, Com_Name, Confidence, Lat, Lon, Cutoff, Week, Sens, Overlap FROM detections;" >> "$CSV_FILE"

if [ $? -ne 0 ]; then
  echo "Error: Failed to dump database to CSV."
  rm -f "$CSV_FILE"
  exit 1
fi

if [ "$DRY_RUN" == "true" ]; then
  echo "[DRY RUN] CSV created at $CSV_FILE. Skipping upload."
  rm -f "$CSV_FILE"
  exit 0
fi

# Upload to S3 via rclone
echo "Uploading $CSV_FILE to ${RCLONE_REMOTE}:${RCLONE_BUCKET}${RCLONE_PATH}${DATE}.csv ..."
rclone copyto "$CSV_FILE" "${RCLONE_REMOTE}:${RCLONE_BUCKET}${RCLONE_PATH}${DATE}.csv" --progress

if [ $? -eq 0 ]; then
  echo "Backup successful."
  date +%s > "$LAST_RUN_FILE"
  rm -f "$CSV_FILE"
else
  echo "Error: Backup failed."
  rm -f "$CSV_FILE"
  exit 1
fi