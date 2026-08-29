#!/usr/bin/env bash
# Integration test for update_backup_timer.sh
# Validates that config values are correctly applied to systemd units
set -e

echo "🧪 Running Sudoers Helper Integration Tests..."

TEST_DIR=$(mktemp -d)
ORIG_HOME="$HOME"
export HOME="$TEST_DIR"

# Create dummy templates
mkdir -p templates
cat > templates/backup_detections_daily.timer << 'EOF'
[Timer]
OnCalendar=*-*-* ${S3_BACKUP_TIME}
Persistent=true
EOF

cat > templates/backup_watchdog.timer << 'EOF'
[Timer]
OnBootSec=5min
OnUnitActiveSec=${S3_BACKUP_WATCHDOG_INTERVAL}
EOF

# Create dummy config
cat > "$TEST_DIR/birdnet.conf" << 'EOF'
S3_BACKUP_TIME="03:30"
S3_BACKUP_WATCHDOG_INTERVAL="45min"
EOF

# Create dummy systemd dir
mkdir -p "$TEST_DIR/systemd"

# Copy helper script and modify it to use our temp dirs
cp scripts/update_backup_timer.sh "$TEST_DIR/helper_test.sh"
perl -pi -e "s|/etc/birdnet/birdnet.conf|$TEST_DIR/birdnet.conf|g" "$TEST_DIR/helper_test.sh"
perl -pi -e "s|/etc/systemd/system|$TEST_DIR/systemd|g" "$TEST_DIR/helper_test.sh"

# Mock systemctl (does nothing)
mock_systemctl() {
  if [ "$1" == "daemon-reload" ] || [ "$1" == "restart" ]; then
    return 0
  fi
  return 1
}
# We can't alias in non-interactive bash easily, so we'll just comment out systemctl calls in the test script
perl -pi -e "s|systemctl|# systemctl|g" "$TEST_DIR/helper_test.sh"

# Run helper
echo "✅ Test 1: Helper updates timer files..."
bash "$TEST_DIR/helper_test.sh"

# Verify Daily Timer
if ! grep -q "03:30" "$TEST_DIR/systemd/backup_detections_daily.timer"; then
  echo "   FAIL: Daily timer not updated with correct time"
  cat "$TEST_DIR/systemd/backup_detections_daily.timer"
  exit 1
fi

# Verify Watchdog Timer
if ! grep -q "45min" "$TEST_DIR/systemd/backup_watchdog.timer"; then
  echo "   FAIL: Watchdog timer not updated with correct interval"
  cat "$TEST_DIR/systemd/backup_watchdog.timer"
  exit 1
fi

echo "   PASS: Timer files correctly updated"

# Cleanup
rm -rf "$TEST_DIR"
export HOME="$ORIG_HOME"

echo ""
echo "🎉 Sudoers Helper Integration Tests passed!"