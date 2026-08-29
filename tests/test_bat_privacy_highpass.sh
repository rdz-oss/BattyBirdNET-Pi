#!/usr/bin/env bash
# Validation test for Bat Privacy Highpass feature
set -e

echo "Running Bat Privacy Highpass Tests..."

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
if bash -n scripts/extract_new_birdsounds.sh 2>/dev/null; then
  pass "No syntax errors in extract_new_birdsounds.sh"
else
  fail "Syntax errors in extract_new_birdsounds.sh"
fi

if bash -n scripts/birdnet_analysis.sh 2>/dev/null; then
  pass "No syntax errors in birdnet_analysis.sh"
else
  fail "Syntax errors in birdnet_analysis.sh"
fi

if bash -n scripts/install_config.sh 2>/dev/null; then
  pass "No syntax errors in install_config.sh"
else
  fail "Syntax errors in install_config.sh"
fi

# Test 2: install_config.sh contains BAT_HIGHPASS_FREQ default
echo "Test 2: Checking install_config.sh for BAT_HIGHPASS_FREQ..."
if grep -q "BAT_HIGHPASS_FREQ=10000" scripts/install_config.sh; then
  pass "BAT_HIGHPASS_FREQ=10000 present in install_config.sh"
else
  fail "BAT_HIGHPASS_FREQ missing from install_config.sh"
fi

# Test 3: extract_new_birdsounds.sh applies highpass in bat mode
echo "Test 3: Checking extraction script for highpass logic..."
if grep -q "BAT_HIGHPASS_FREQ" scripts/extract_new_birdsounds.sh; then
  pass "BAT_HIGHPASS_FREQ referenced in extraction script"
else
  fail "BAT_HIGHPASS_FREQ not referenced in extraction script"
fi

if grep -q "SAMPLING_RATE.*100000" scripts/extract_new_birdsounds.sh; then
  pass "Bat mode check (SAMPLING_RATE > 100000) present"
else
  fail "Bat mode check missing from extraction script"
fi

# Test 4: Highpass uses 2nd order filter
echo "Test 4: Checking for 2nd order highpass filter..."
if grep -q "highpass -2" scripts/extract_new_birdsounds.sh; then
  pass "2nd order highpass (highpass -2) used in extraction"
else
  fail "Missing 2nd order highpass in extraction"
fi

# Test 5: Live spectrogram applies highpass in bat mode
echo "Test 5: Checking live spectrogram for highpass logic..."
if grep -q "SPECTROGRAM_FILTER" scripts/birdnet_analysis.sh; then
  pass "SPECTROGRAM_FILTER variable present in analysis script"
else
  fail "SPECTROGRAM_FILTER missing from analysis script"
fi

if grep -q "highpass -2" scripts/birdnet_analysis.sh; then
  pass "2nd order highpass used in live spectrogram"
else
  fail "Missing 2nd order highpass in live spectrogram"
fi

# Test 6: birdnet.conf-defaults contains BAT_HIGHPASS_FREQ
echo "Test 6: Checking birdnet.conf-defaults..."
if grep -q "BAT_HIGHPASS_FREQ=10000" birdnet.conf-defaults; then
  pass "BAT_HIGHPASS_FREQ=10000 in birdnet.conf-defaults"
else
  fail "BAT_HIGHPASS_FREQ missing from birdnet.conf-defaults"
fi

# Test 7: update_birdnet_snippets.sh migration exists
echo "Test 7: Checking migration snippet..."
if grep -q "BAT_HIGHPASS_FREQ" scripts/update_birdnet_snippets.sh; then
  pass "Migration snippet for BAT_HIGHPASS_FREQ exists"
else
  fail "Migration snippet missing for BAT_HIGHPASS_FREQ"
fi

# Test 8: UI save handler appends if key missing
echo "Test 8: Checking advanced.php for defensive append..."
if grep -q 'strpos.*BAT_HIGHPASS_FREQ' scripts/advanced.php; then
  pass "UI handler checks for existing key before replace"
else
  fail "UI handler may fail silently if key is missing"
fi

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed!"
  exit 1
fi

echo "All Bat Privacy Highpass tests passed!"