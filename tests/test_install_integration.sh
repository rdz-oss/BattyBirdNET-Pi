#!/usr/bin/env bash
# Validation test for Installer Integration (Task 7)
set -e

echo "🧪 Running Installer Integration Tests..."

# Test 1: Bash Syntax Check
echo "✅ Test 1: Checking install_services.sh syntax..."
bash -n scripts/install_services.sh
echo "   PASS: No syntax errors in install_services.sh"

# Test 2: Function Presence
echo "✅ Test 2: Verifying new installer functions..."
if ! grep -q "install_s3_backup_services" scripts/install_services.sh; then
  echo "   FAIL: Missing install_s3_backup_services function"
  exit 1
fi
if ! grep -q "rclone" scripts/install_services.sh; then
  echo "   FAIL: Missing rclone install in install_depends"
  exit 1
fi
echo "   PASS: Installer functions present"

# Test 3: Sudoers Helper Installation
echo "✅ Test 3: Verifying sudoers helper installation..."
if ! grep -q "update_backup_timer.sh" scripts/install_services.sh; then
  echo "   FAIL: Missing update_backup_timer.sh installation"
  exit 1
fi
if ! grep -q "www-data-update-backup-timer" scripts/install_services.sh; then
  echo "   FAIL: Missing sudoers rule installation"
  exit 1
fi
echo "   PASS: Sudoers helper installation present"

echo ""
echo "🎉 All Installer Integration Tests passed!"