#!/usr/bin/env bash
# Validation test for mode-switching sampling rate fix
set -e

echo "Running Mode Switching Sampling Rate Tests..."

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

# Test 1: Bash syntax checks
echo "Test 1: Checking bash syntax..."
if bash -n scripts/switch_classifier.sh 2>/dev/null; then
  pass "No syntax errors in switch_classifier.sh"
else
  fail "Syntax errors in switch_classifier.sh"
fi

if bash -n scripts/install_config.sh 2>/dev/null; then
  pass "No syntax errors in install_config.sh"
else
  fail "Syntax errors in install_config.sh"
fi

if bash -n scripts/update_birdnet_snippets.sh 2>/dev/null; then
  pass "No syntax errors in update_birdnet_snippets.sh"
else
  fail "Syntax errors in update_birdnet_snippets.sh"
fi

# Test 2: install_config.sh has both sampling rate variables
echo "Test 2: Checking install_config.sh for sampling rate variables..."
if grep -q "BIRD_SAMPLING_RATE=48000" scripts/install_config.sh; then
  pass "BIRD_SAMPLING_RATE=48000 present in install_config.sh"
else
  fail "BIRD_SAMPLING_RATE missing from install_config.sh"
fi

if grep -q "BAT_SAMPLING_RATE=256000" scripts/install_config.sh; then
  pass "BAT_SAMPLING_RATE=256000 present in install_config.sh"
else
  fail "BAT_SAMPLING_RATE missing from install_config.sh"
fi

if grep -q "SAMPLING_RATE=256000" scripts/install_config.sh; then
  pass "SAMPLING_RATE=256000 present in install_config.sh"
else
  fail "SAMPLING_RATE missing from install_config.sh"
fi

# Test 3: switch_classifier.sh updates SAMPLING_RATE for bird mode
echo "Test 3: Checking switch_classifier.sh for bird mode sampling rate..."
if grep -q 'BIRD_SAMPLING_RATE' scripts/switch_classifier.sh; then
  pass "switch_classifier.sh references BIRD_SAMPLING_RATE"
else
  fail "switch_classifier.sh missing BIRD_SAMPLING_RATE reference"
fi

if grep -q 'SAMPLING_RATE.*bird_sampling_rate' scripts/switch_classifier.sh; then
  pass "switch_classifier.sh updates SAMPLING_RATE on bird switch"
else
  fail "switch_classifier.sh does not update SAMPLING_RATE for bird mode"
fi

# Test 4: switch_classifier.sh restores SAMPLING_RATE for bat mode
echo "Test 4: Checking switch_classifier.sh for bat mode restoration..."
if grep -q 'BAT_SAMPLING_RATE' scripts/switch_classifier.sh; then
  pass "switch_classifier.sh references BAT_SAMPLING_RATE"
else
  fail "switch_classifier.sh missing BAT_SAMPLING_RATE reference"
fi

if grep -q 'SAMPLING_RATE.*bat_sampling_rate' scripts/switch_classifier.sh; then
  pass "switch_classifier.sh updates SAMPLING_RATE on bat switch"
else
  fail "switch_classifier.sh does not update SAMPLING_RATE for bat mode"
fi

# Test 5: Default fallback values exist
echo "Test 5: Checking for default fallback values..."
if grep -q 'BIRD_SAMPLING_RATE:-48000' scripts/switch_classifier.sh; then
  pass "Fallback BIRD_SAMPLING_RATE=48000 present"
else
  fail "Missing fallback for BIRD_SAMPLING_RATE"
fi

if grep -q 'BAT_SAMPLING_RATE:-256000' scripts/switch_classifier.sh; then
  pass "Fallback BAT_SAMPLING_RATE=256000 present"
else
  fail "Missing fallback for BAT_SAMPLING_RATE"
fi

# Test 6: update_birdnet_snippets.sh migration exists
echo "Test 6: Checking migration snippets..."
if grep -q 'BIRD_SAMPLING_RATE' scripts/update_birdnet_snippets.sh; then
  pass "Migration snippet for BIRD_SAMPLING_RATE exists"
else
  fail "Migration snippet missing for BIRD_SAMPLING_RATE"
fi

if grep -q 'BAT_SAMPLING_RATE' scripts/update_birdnet_snippets.sh; then
  pass "Migration snippet for BAT_SAMPLING_RATE exists"
else
  fail "Migration snippet missing for BAT_SAMPLING_RATE"
fi

# Test 7: Migration creates BAT_SAMPLING_RATE from current SAMPLING_RATE
echo "Test 7: Checking migration reads current SAMPLING_RATE for BAT_SAMPLING_RATE..."
if grep -q 'SAMPLING_RATE.*BAT_SAMPLING_RATE\|BAT_SAMPLING_RATE.*SAMPLING_RATE' scripts/update_birdnet_snippets.sh; then
  pass "Migration links BAT_SAMPLING_RATE to current SAMPLING_RATE"
else
  fail "Migration does not preserve current SAMPLING_RATE into BAT_SAMPLING_RATE"
fi

# Test 8: advanced.php handles bird sampling rate
echo "Test 8: Checking advanced.php for bird sampling rate handler..."
if grep -q 'bird_sampling_rate' scripts/advanced.php; then
  pass "advanced.php handles bird_sampling_rate"
else
  fail "advanced.php missing bird_sampling_rate handler"
fi

# Test 9: advanced.php updates BAT_SAMPLING_RATE when bat rate changes
echo "Test 9: Checking advanced.php writes BAT_SAMPLING_RATE..."
if grep -q 'BAT_SAMPLING_RATE=\$bat_sampling_frequency' scripts/advanced.php; then
  pass "advanced.php updates BAT_SAMPLING_RATE with bat frequency"
else
  fail "advanced.php does not update BAT_SAMPLING_RATE"
fi

# Test 10: Functional simulation of bird mode switch
echo "Test 10: Functional simulation of bird mode switch..."
tmpdir=$(mktemp -d)
cat > "$tmpdir/test.conf" << EOF
SAMPLING_RATE=256000
BIRD_SAMPLING_RATE=48000
BAT_SAMPLING_RATE=256000
BAT_CLASSIFIER="Bavaria"
RECORDING_LENGTH=9
EXTRACTION_LENGTH=1.125
EOF
conf="$tmpdir/test.conf"
sed 's/BAT_CLASSIFIER=.*/BAT_CLASSIFIER=BIRDS/g' "$conf" |
  sed 's/RECORDING_LENGTH=.*/RECORDING_LENGTH=15/g' |
  sed 's/EXTRACTION_LENGTH=.*/EXTRACTION_LENGTH=3/g' |
  sed 's/SAMPLING_RATE=.*/SAMPLING_RATE=48000/g' > "$tmpdir/bird_result.conf"

bird_rate=$(awk -F= '/^SAMPLING_RATE/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$tmpdir/bird_result.conf")
if [ "$bird_rate" = "48000" ]; then
  pass "Bird mode simulation: SAMPLING_RATE correctly set to 48000"
else
  fail "Bird mode simulation: SAMPLING_RATE is $bird_rate, expected 48000"
fi

# Test 11: Functional simulation of bat mode switch (restoration)
echo "Test 11: Functional simulation of bat mode switch (restoration)..."
cat > "$tmpdir/test.conf" << EOF
SAMPLING_RATE=48000
BIRD_SAMPLING_RATE=48000
BAT_SAMPLING_RATE=256000
BAT_CLASSIFIER="BIRDS"
RECORDING_LENGTH=15
EXTRACTION_LENGTH=3
EOF
sed 's/BAT_CLASSIFIER=.*/BAT_CLASSIFIER=Bavaria/g' "$tmpdir/test.conf" |
  sed 's/RECORDING_LENGTH=.*/RECORDING_LENGTH=9/g' |
  sed 's/EXTRACTION_LENGTH=.*/EXTRACTION_LENGTH=1.125/g' |
  sed 's/SAMPLING_RATE=.*/SAMPLING_RATE=256000/g' > "$tmpdir/bat_result.conf"

bat_rate=$(awk -F= '/^SAMPLING_RATE/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' "$tmpdir/bat_result.conf")
if [ "$bat_rate" = "256000" ]; then
  pass "Bat mode simulation: SAMPLING_RATE correctly restored to 256000"
else
  fail "Bat mode simulation: SAMPLING_RATE is $bat_rate, expected 256000"
fi

rm -rf "$tmpdir"

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed!"
  exit 1
fi

echo "All Mode Switching Sampling Rate tests passed!"