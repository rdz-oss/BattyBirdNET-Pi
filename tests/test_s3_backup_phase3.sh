#!/usr/bin/env bash
# Validation test for Phase 3 S3 Backup artifacts (Systemd Units)
set -e

echo "🧪 Running Phase 3 S3 Backup Tests..."

# Test 1: Template Existence
echo "✅ Test 1: Checking template existence..."
TEMPLATES=("backup_detections.service" "backup_detections_daily.timer" "backup_watchdog.service" "backup_watchdog.timer")
for tmpl in "${TEMPLATES[@]}"; do
  if [ ! -f "templates/$tmpl" ]; then
    echo "   FAIL: Missing template $tmpl"
    exit 1
  fi
done
echo "   PASS: All systemd templates present"

# Test 2: Template Content Validation
echo "✅ Test 2: Verifying template content..."

# Daily Timer
if ! grep -q "OnCalendar" templates/backup_detections_daily.timer; then
  echo "   FAIL: Daily timer missing OnCalendar"
  exit 1
fi
if ! grep -q "Persistent=true" templates/backup_detections_daily.timer; then
  echo "   FAIL: Daily timer missing Persistent=true"
  exit 1
fi

# Watchdog Timer
if ! grep -q "OnBootSec" templates/backup_watchdog.timer; then
  echo "   FAIL: Watchdog timer missing OnBootSec"
  exit 1
fi
if ! grep -q "OnUnitActiveSec" templates/backup_watchdog.timer; then
  echo "   FAIL: Watchdog timer missing OnUnitActiveSec"
  exit 1
fi

# Services reference correct scripts
if ! grep -q "backup_detections.sh" templates/backup_detections.service; then
  echo "   FAIL: Backup service missing script reference"
  exit 1
fi
if ! grep -q "backup_watchdog.sh" templates/backup_watchdog.service; then
  echo "   FAIL: Watchdog service missing script reference"
  exit 1
fi

echo "   PASS: Systemd templates contain correct directives"

echo ""
echo "🎉 All Phase 3 tests passed!"