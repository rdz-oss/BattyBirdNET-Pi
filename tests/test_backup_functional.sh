#!/usr/bin/env bash
# Functional test for backup_detections.sh
# Uses a dummy database to verify CSV generation and cleanup
set -e

echo "🧪 Running Functional Backup Tests..."

# Setup
TEST_DIR=$(mktemp -d)
ORIG_HOME="$HOME"

# Create directory structure
mkdir -p "$TEST_DIR/BirdNET-Pi/scripts"
DUMMY_DB="$TEST_DIR/BirdNET-Pi/scripts/birds.db"
CSV_PREFIX="$TEST_DIR/BirdNET-Pi-detections"

# Create dummy database
sqlite3 "$DUMMY_DB" "CREATE TABLE detections (Date TEXT, Time TEXT, Sci_Name TEXT, Com_Name TEXT, Confidence REAL, Lat REAL, Lon REAL, Cutoff REAL, Week INT, Sens REAL, Overlap REAL);"
sqlite3 "$DUMMY_DB" "INSERT INTO detections VALUES ('2026-08-29', '12:00:00', 'Myotis myotis', 'Mouse-eared bat', 0.95, 48.1, 11.5, 0.8, 35, 1.0, 0.0);"

# Mock environment
export HOME="$TEST_DIR"

# Create mock config file
mkdir -p /tmp/etc_birdnet_test
cat > /tmp/etc_birdnet_test/birdnet.conf << EOF
S3_BACKUP_ENABLED=true
RCLONE_REMOTE=TestRemote
RCLONE_BUCKET=TestBucket
RCLONE_PATH=db/
EOF

# Test 1: Dry Run creates and cleans up CSV
echo "✅ Test 1: Dry run creates and cleans up CSV..."
cp scripts/backup_detections.sh "$TEST_DIR/backup_test.sh"
# Override the source line to use our mock config
perl -pi -e "s|source /etc/birdnet/birdnet.conf|source /tmp/etc_birdnet_test/birdnet.conf|g" "$TEST_DIR/backup_test.sh"
# Override the CSV path prefix
perl -pi -e "s|/tmp/BirdNET-Pi-detections-|$CSV_PREFIX-|g" "$TEST_DIR/backup_test.sh"

bash "$TEST_DIR/backup_test.sh" --dry-run 2>&1 | tee "$TEST_DIR/output.log"

# Verify the script reported success
if ! grep -q "CSV created at" "$TEST_DIR/output.log"; then
  echo "   FAIL: Script did not report CSV creation"
  cat "$TEST_DIR/output.log"
  exit 1
fi

# Verify the CSV file is cleaned up afterwards (it should be gone)
CSV_FILES=$(ls ${CSV_PREFIX}-*.csv 2>/dev/null)
if [ -n "$CSV_FILES" ]; then
  echo "   FAIL: CSV not cleaned up after dry run"
  exit 1
fi

echo "   PASS: Dry run created, validated, and cleaned up CSV"

# Cleanup
rm -rf "$TEST_DIR"
rm -rf /tmp/etc_birdnet_test
export HOME="$ORIG_HOME"

echo ""
echo "🎉 Functional Backup Tests passed!"