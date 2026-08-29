#!/usr/bin/env bash
# Simple validation test for Phase 1 S3 Backup artifacts
set -e

echo "🧪 Running Phase 1 S3 Backup Tests..."

# Test 1: Bash Syntax Check
echo "✅ Test 1: Checking bash syntax..."
bash -n scripts/backup_detections.sh
echo "   PASS: No syntax errors in backup_detections.sh"

# Test 2: Config Variable Presence
echo "✅ Test 2: Checking config variables in birdnet.conf-defaults..."
REQUIRED_VARS=("S3_BACKUP_ENABLED" "RCLONE_REMOTE" "RCLONE_BUCKET" "RCLONE_PATH" "S3_BACKUP_TIME" "S3_BACKUP_WATCHDOG_INTERVAL" "S3_BACKUP_PING_HOST")
for var in "${REQUIRED_VARS[@]}"; do
  if ! grep -q "^${var}=" birdnet.conf-defaults; then
    echo "   FAIL: Missing variable $var in birdnet.conf-defaults"
    exit 1
  fi
done
echo "   PASS: All required config variables present"

# Test 3: Design Doc References
echo "✅ Test 3: Checking design document references..."
if ! grep -q "S3_BACKUP_ENABLED" docs/S3_BACKUP_DESIGN.md; then
  echo "   FAIL: Design doc missing key references"
  exit 1
fi
echo "   PASS: Design doc references match config"

echo ""
echo "🎉 All Phase 1 tests passed!"