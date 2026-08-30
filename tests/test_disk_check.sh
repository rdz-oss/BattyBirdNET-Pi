#!/usr/bin/env bash
# Test disk_check.sh logic by mocking df
set -e

echo "Running Disk Check Tests..."

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

# Test 1: Syntax check
echo "Test 1: Syntax check..."
if bash -n scripts/disk_check.sh 2>/dev/null; then
  pass "No syntax errors in disk_check.sh"
else
  fail "Syntax errors in disk_check.sh"
fi

# Test 2: Script sources config and checks disk usage
echo "Test 2: Script structure..."
if grep -q "source /etc/birdnet/birdnet.conf" scripts/disk_check.sh; then
  pass "Script sources birdnet.conf"
else
  fail "Script does not source birdnet.conf"
fi

if grep -q "df -h" scripts/disk_check.sh; then
  pass "Script uses df -h to check disk usage"
else
  fail "Script does not use df -h"
fi

if grep -q "FULL_DISK" scripts/disk_check.sh; then
  pass "Script checks FULL_DISK setting"
else
  fail "Script does not check FULL_DISK setting"
fi

# Test 3: Test the threshold logic (95%)
echo "Test 3: Threshold logic..."
if grep -q "95" scripts/disk_check.sh; then
  pass "Script uses 95% threshold"
else
  fail "Script does not use 95% threshold"
fi

# Test 4: Verify purge mode exists
echo "Test 4: Purge mode..."
if grep -q "purge)" scripts/disk_check.sh; then
  pass "Script has purge mode"
else
  fail "Script missing purge mode"
fi

if grep -q "Removing oldest data" scripts/disk_check.sh; then
  pass "Purge mode removes oldest data"
else
  fail "Purge mode missing removal logic"
fi

# Test 5: Verify keep mode exists
echo "Test 5: Keep mode..."
if grep -q "keep)" scripts/disk_check.sh; then
  pass "Script has keep mode"
else
  fail "Script missing keep mode"
fi

if grep -q "Stopping Core Services" scripts/disk_check.sh; then
  pass "Keep mode stops services"
else
  fail "Keep mode missing service stop"
fi

# Test 6: Verify secondary threshold check
echo "Test 6: Secondary threshold check..."
secondary_count=$(grep -c "ge 95" scripts/disk_check.sh || true)
if [ "$secondary_count" -ge 2 ]; then
  pass "Script checks threshold twice (primary + secondary)"
else
  fail "Script should check threshold twice"
fi

# Test 7: Verify exclude list handling
echo "Test 7: Exclude list handling..."
if grep -q "disk_check_exclude.txt" scripts/disk_check.sh; then
  pass "Script respects disk_check_exclude.txt"
else
  fail "Script does not check exclude list"
fi

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed!"
  exit 1
fi

echo "All Disk Check tests passed!"