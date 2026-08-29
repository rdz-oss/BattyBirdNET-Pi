#!/usr/bin/env bash
# Validation test for Phase 2 S3 Backup artifacts (Watchdog)
set -e

echo "🧪 Running Phase 2 S3 Backup Tests..."

# Test 1: Bash Syntax Check
echo "✅ Test 1: Checking bash syntax..."
bash -n scripts/backup_watchdog.sh
echo "   PASS: No syntax errors in backup_watchdog.sh"

# Test 2: Logic Presence
echo "✅ Test 2: Verifying watchdog logic..."
if ! grep -q "LOCK_FILE" scripts/backup_watchdog.sh; then
  echo "   FAIL: Missing lock file logic in watchdog"
  exit 1
fi
if ! grep -q "ping" scripts/backup_watchdog.sh; then
  echo "   FAIL: Missing ping connectivity check in watchdog"
  exit 1
fi
if ! grep -q "OVERDUE_SECONDS" scripts/backup_watchdog.sh; then
  echo "   FAIL: Missing overdue check logic in watchdog"
  exit 1
fi
echo "   PASS: Watchdog logic components present"

# Test 3: Config Variable Consistency
echo "✅ Test 3: Checking config variables used by watchdog..."
REQUIRED_VARS=("S3_BACKUP_ENABLED" "S3_BACKUP_PING_HOST")
for var in "${REQUIRED_VARS[@]}"; do
  if ! grep -q "$var" scripts/backup_watchdog.sh; then
    echo "   FAIL: Watchdog missing usage of $var"
    exit 1
  fi
done
echo "   PASS: Watchdog uses correct config variables"

echo ""
echo "🎉 All Phase 2 tests passed!"