# S3 Backup Feature Design Document

## 1. Overview
This feature provides automated, secure, and resilient backups of the BattyBirdNET-Pi detections database (`birds.db`) to an S3-compatible object store (e.g., OVH, IONOS) using `rclone`.

## 2. Architecture
- **Tooling**: `rclone` for S3 interaction.
- **Triggering**: 
  - **Daily Timer**: Systemd timer running at a user-configurable time (default 02:00).
  - **Watchdog Timer**: Systemd timer running every 30 minutes to check for connectivity and overdue backups.
- **Configuration**: Stored in `/etc/birdnet/birdnet.conf`.
- **Credentials**: Managed manually via `rclone config` (secure). UI only stores Remote Name and Bucket Name.

## 3. Configuration Variables (`birdnet.conf`)
- `S3_BACKUP_ENABLED=false`: Master switch for the feature.
- `S3_BACKUP_TIME="02:00"`: Daily backup time.
- `S3_BACKUP_WATCHDOG_INTERVAL="30min"`: Frequency of connectivity checks.
- `S3_BACKUP_PING_HOST="8.8.8.8"`: Host to ping for connectivity verification.
- `RCLONE_REMOTE="BackupStorageS3"`: Name of the rclone remote configured by the user.
- `RCLONE_BUCKET="your_bucket_name"`: Target S3 bucket.
- `RCLONE_PATH="db/"`: Subdirectory within the bucket.

## 4. Data Flow
1. **Trigger**: Daily Timer or Watchdog (if offline and now online) initiates `backup_detections.sh`.
2. **Dump**: Script exports `birds.db` to a timestamped CSV in `/tmp/`.
3. **Upload**: Script uses `rclone copyto` to upload CSV to `RCLONE_REMOTE:RCLONE_BUCKET/RCLONE_PATH/detections-YYYY-MM-DD.csv`.
4. **Logging**: Success/Failure logged to `journalctl`.
5. **Cleanup**: Temp CSV removed. Timestamp of last success saved to `~/.birdnet_backup_last_run`.

## 5. Reliability Strategy (Offline Devices)
- **Persistent Timers**: Systemd timers use `Persistent=true` to catch up on missed runs after reboot.
- **Watchdog**: A separate service runs every `S3_BACKUP_WATCHDOG_INTERVAL`. It pings `S3_BACKUP_PING_HOST`. If ping succeeds AND the last backup was >24 hours ago, it triggers an immediate backup. This handles scenarios where the device is running but offline (e.g., remote field work) and suddenly connects to a network.

## 6. Security
- **Credentials**: Users run `rclone config` via SSH. Keys are stored in `~/.config/rclone/rclone.conf` (user-only access).
- **UI Safety**: The Web UI (`www-data`) never sees keys. It only updates `birdnet.conf` with Remote/Bucket names.
- **Sudoers**: A specific `sudoers` rule allows `www-data` to run `scripts/update_backup_timer.sh` to reload systemd timers when the user changes `S3_BACKUP_TIME` in the UI.

## 7. Testing
- **Dry Run**: `backup_detections.sh --dry-run` simulates the process (dump CSV, check ping) without uploading to S3.
- **Unit Tests**: Scripts include basic error handling for missing DB, missing rclone, and failed pings.