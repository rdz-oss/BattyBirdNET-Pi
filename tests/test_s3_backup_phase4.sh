#!/usr/bin/env bash
# Validation test for Phase 4 S3 Backup artifacts (Sudoers Helper)
set -e

echo "🧪 Running Phase 4 S3 Backup Tests..."

# Test 1: Bash Syntax Check
echo "✅ Test 1: Checking bash syntax..."
bash -n scripts/update_backup_timer.sh
echo "   PASS: No syntax errors in update_backup_timer.sh"

# Test 2: Logic Presence
echo "✅ Test 2: Verifying helper logic..."
if ! grep -q "sed" scripts/update_backup_timer.sh; then
  echo "   FAIL: Missing sed replacement logic in helper"
  exit 1
fi
if ! grep -q "daemon-reload" scripts/update_backup_timer.sh; then
  echo "   FAIL: Missing daemon-reload in helper"
  exit 1
fi
if ! grep -q "backup_detections_daily.timer" scripts/update_backup_timer.sh; then
  echo "   FAIL: Missing daily timer update in helper"
  exit 1
fi
if ! grep -q "backup_watchdog.timer" scripts/update_backup_timer.sh; then
  echo "   FAIL: Missing watchdog timer update in helper"
  exit 1
fi
echo "   PASS: Sudoers helper logic components present"

echo ""
echo "🎉 All Phase 4 tests passed!"