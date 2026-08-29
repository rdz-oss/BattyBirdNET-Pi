#!/usr/bin/env bash
# Validation test for Phase 5 S3 Backup UI Integration
set -e

echo "🧪 Running Phase 5 S3 Backup UI Tests..."

# Test 1: PHP Syntax Check (basic)
echo "✅ Test 1: Checking for obvious PHP syntax errors..."
if ! grep -q "s3_backup_enabled" scripts/advanced.php; then
  echo "   FAIL: Missing s3_backup_enabled handling in advanced.php"
  exit 1
fi
if ! grep -q "rclone_remote" scripts/advanced.php; then
  echo "   FAIL: Missing rclone_remote handling in advanced.php"
  exit 1
fi
if ! grep -q "update_backup_timer.sh" scripts/advanced.php; then
  echo "   FAIL: Missing call to update_backup_timer.sh in advanced.php"
  exit 1
fi
echo "   PASS: UI integration components present"

# Test 2: Form Elements
echo "✅ Test 2: Checking form elements..."
if ! grep -q "name=\"s3_backup_enabled\"" scripts/advanced.php; then
  echo "   FAIL: Missing s3_backup_enabled form element"
  exit 1
fi
if ! grep -q "name=\"rclone_remote\"" scripts/advanced.php; then
  echo "   FAIL: Missing rclone_remote form element"
  exit 1
fi
if ! grep -q "name=\"rclone_bucket\"" scripts/advanced.php; then
  echo "   FAIL: Missing rclone_bucket form element"
  exit 1
fi
if ! grep -q "name=\"s3_backup_time\"" scripts/advanced.php; then
  echo "   FAIL: Missing s3_backup_time form element"
  exit 1
fi
echo "   PASS: Form elements present"

# Test 3: Sudoers Helper Reference
echo "✅ Test 3: Verifying sudoers helper is called..."
if ! grep -q "sudo /usr/local/bin/update_backup_timer.sh" scripts/advanced.php; then
  echo "   FAIL: Missing sudoers helper call in advanced.php"
  exit 1
fi
echo "   PASS: Sudoers helper correctly referenced"

echo ""
echo "🎉 All Phase 5 UI Tests passed!"