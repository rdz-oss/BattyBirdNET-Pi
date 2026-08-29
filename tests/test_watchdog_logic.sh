#!/usr/bin/env bash
# Logic simulation for backup_watchdog.sh
# Validates overdue detection and lock file behavior
set -e

echo "🧪 Running Watchdog Logic Simulation..."

TEST_DIR=$(mktemp -d)
ORIG_HOME="$HOME"
export HOME="$TEST_DIR"

# Mock config
mkdir -p /tmp/etc_birdnet_test
cat > /tmp/etc_birdnet_test/birdnet.conf << EOF
S3_BACKUP_ENABLED=true
S3_BACKUP_PING_HOST=127.0.0.1
S3_BACKUP_WATCHDOG_INTERVAL=30min
EOF

# Mock backup script (does nothing but succeed)
mkdir -p scripts
cat > scripts/backup_detections.sh << 'EOF'
#!/usr/bin/env bash
source /tmp/etc_birdnet_test/birdnet.conf
echo "Backup triggered"
exit 0
EOF
chmod +x scripts/backup_detections.sh

# Temporarily modify watchdog to use mock config
cp scripts/backup_watchdog.sh "$TEST_DIR/watchdog_test.sh"
perl -pi -e "s|source /etc/birdnet/birdnet.conf|source /tmp/etc_birdnet_test/birdnet.conf|g" "$TEST_DIR/watchdog_test.sh"

# Test 1: Watchdog skips if not overdue
echo "✅ Test 1: Watchdog skips if not overdue..."
echo $(date +%s) > ~/.birdnet_backup_last_run # Set last run to now
bash "$TEST_DIR/watchdog_test.sh" --dry-run 2>&1 | grep -q "not overdue"
if [ $? -ne 0 ]; then
  echo "   FAIL: Watchdog did not skip when not overdue"
  exit 1
fi
echo "   PASS: Watchdog correctly skipped"

# Test 2: Watchdog triggers if overdue and connected
echo "✅ Test 2: Watchdog triggers if overdue..."
echo $(($(date +%s) - 90000)) > ~/.birdnet_backup_last_run # Set last run to 25h ago
OUTPUT=$(bash "$TEST_DIR/watchdog_test.sh" --dry-run 2>&1)
if ! echo "$OUTPUT" | grep -q "Triggering backup"; then
  echo "   FAIL: Watchdog did not trigger when overdue"
  echo "   Output: $OUTPUT"
  exit 1
fi
echo "   PASS: Watchdog correctly triggered"

# Test 3: Lock file prevents overlap
echo "✅ Test 3: Lock file prevents overlap..."
touch ~/.birdnet_backup_lock
OUTPUT=$(bash "$TEST_DIR/watchdog_test.sh" --dry-run 2>&1)
if ! echo "$OUTPUT" | grep -q "lock file exists"; then
  echo "   FAIL: Watchdog did not respect lock file"
  exit 1
fi
echo "   PASS: Lock file respected"

# Cleanup
rm -rf "$TEST_DIR"
rm -rf /tmp/etc_birdnet_test
export HOME="$ORIG_HOME"

echo ""
echo "🎉 Watchdog Logic Simulation passed!"