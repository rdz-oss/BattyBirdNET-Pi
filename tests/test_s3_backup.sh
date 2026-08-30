#!/usr/bin/env bash
# Consolidated validation test for S3 Backup system
# Replaces test_s3_backup_phase1..5.sh
set -e

echo "Running Consolidated S3 Backup Tests..."

PASS=0
FAIL=0

pass() {
  echo "   PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "   FAIL: $1"
  FAIL=$((FAIL + 1))
}

# Test 1: Config variables in birdnet.conf-defaults
echo "Test 1: Config variables in birdnet.conf-defaults..."
REQUIRED_VARS=("S3_BACKUP_ENABLED" "RCLONE_REMOTE" "RCLONE_BUCKET" "RCLONE_PATH" "S3_BACKUP_TIME" "S3_BACKUP_WATCHDOG_INTERVAL" "S3_BACKUP_PING_HOST")
for var in "${REQUIRED_VARS[@]}"; do
  if grep -q "^${var}=" birdnet.conf-defaults; then
    pass "$var present in birdnet.conf-defaults"
  else
    fail "$var missing from birdnet.conf-defaults"
  fi
done

# Test 2: Design doc references
echo "Test 2: Design doc references..."
if grep -q "S3_BACKUP_ENABLED" docs/S3_BACKUP_DESIGN.md; then
  pass "Design doc references S3_BACKUP_ENABLED"
else
  fail "Design doc missing key references"
fi

# Test 3: Systemd templates exist
echo "Test 3: Systemd template existence..."
TEMPLATES=("backup_detections.service" "backup_detections_daily.timer" "backup_watchdog.service" "backup_watchdog.timer")
for tmpl in "${TEMPLATES[@]}"; do
  if [ -f "templates/$tmpl" ]; then
    pass "Template $tmpl exists"
  else
    fail "Template $tmpl missing"
  fi
done

# Test 4: Timer directives
echo "Test 4: Systemd timer directives..."
if grep -q "OnCalendar" templates/backup_detections_daily.timer; then
  pass "Daily timer has OnCalendar"
else
  fail "Daily timer missing OnCalendar"
fi

if grep -q "Persistent=true" templates/backup_detections_daily.timer; then
  pass "Daily timer has Persistent=true"
else
  fail "Daily timer missing Persistent=true"
fi

if grep -q "OnBootSec" templates/backup_watchdog.timer; then
  pass "Watchdog timer has OnBootSec"
else
  fail "Watchdog timer missing OnBootSec"
fi

if grep -q "OnUnitActiveSec" templates/backup_watchdog.timer; then
  pass "Watchdog timer has OnUnitActiveSec"
else
  fail "Watchdog timer missing OnUnitActiveSec"
fi

# Test 5: Services reference correct scripts
echo "Test 5: Service script references..."
if grep -q "backup_detections.sh" templates/backup_detections.service; then
  pass "Backup service references backup_detections.sh"
else
  fail "Backup service missing script reference"
fi

if grep -q "backup_watchdog.sh" templates/backup_watchdog.service; then
  pass "Watchdog service references backup_watchdog.sh"
else
  fail "Watchdog service missing script reference"
fi

# Test 6: Watchdog logic components
echo "Test 6: Watchdog script logic..."
for var in "LOCK_FILE" "ping" "OVERDUE_SECONDS"; do
  if grep -q "$var" scripts/backup_watchdog.sh; then
    pass "Watchdog has $var logic"
  else
    fail "Watchdog missing $var"
  fi
done

# Test 7: Helper script logic
echo "Test 7: Update backup timer helper..."
for pat in "sed" "daemon-reload" "backup_detections_daily.timer" "backup_watchdog.timer"; do
  if grep -q "$pat" scripts/update_backup_timer.sh; then
    pass "Helper has $pat"
  else
    fail "Helper missing $pat"
  fi
done

# Test 8: UI integration in advanced.php
echo "Test 8: UI integration..."
for pat in "s3_backup_enabled" "rclone_remote" "update_backup_timer.sh"; do
  if grep -q "$pat" scripts/advanced.php; then
    pass "advanced.php has $pat"
  else
    fail "advanced.php missing $pat"
  fi
done

# Test 9: Form elements
echo "Test 9: Form elements..."
for name in "s3_backup_enabled" "rclone_remote" "rclone_bucket" "s3_backup_time"; do
  if grep -q "name=\"${name}\"" scripts/advanced.php; then
    pass "Form element $name present"
  else
    fail "Form element $name missing"
  fi
done

# Test 10: Sudoers helper call
echo "Test 10: Sudoers helper call..."
if grep -q "sudo /usr/local/bin/update_backup_timer.sh" scripts/advanced.php; then
  pass "Sudoers helper correctly referenced in advanced.php"
else
  fail "Missing sudoers helper call in advanced.php"
fi

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed!"
  exit 1
fi

echo "All S3 Backup tests passed!"