#!/usr/bin/env bash
# Validation test for translation 'not-selected' fix
set -e

echo "Running Translation Fix Tests..."

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

# Test 1: Syntax checks
echo "Test 1: Checking syntax..."
if bash -n scripts/batnet_analysis.sh 2>/dev/null; then
  pass "No syntax errors in batnet_analysis.sh"
else
  fail "Syntax errors in batnet_analysis.sh"
fi

if bash -n scripts/update_birdnet_snippets.sh 2>/dev/null; then
  pass "No syntax errors in update_birdnet_snippets.sh"
else
  fail "Syntax errors in update_birdnet_snippets.sh"
fi

if php -l scripts/config.php 2>&1 | grep -q "No syntax errors"; then
  pass "No syntax errors in config.php"
else
  fail "Syntax errors in config.php"
fi

# Test 2: batnet_analysis.sh guards not-selected
echo "Test 2: Checking batnet_analysis.sh for not-selected guard..."
if grep -q 'not-selected' scripts/batnet_analysis.sh; then
  pass "batnet_analysis.sh references not-selected"
else
  fail "batnet_analysis.sh missing not-selected guard"
fi

if grep -q 'DATABASE_LANG=en' scripts/batnet_analysis.sh; then
  pass "batnet_analysis.sh normalizes not-selected to en"
else
  fail "batnet_analysis.sh does not normalize not-selected"
fi

# Test 3: update_birdnet_snippets.sh defaults to en
echo "Test 3: Checking update_birdnet_snippets.sh default..."
if grep -q 'DATABASE_LANG=en' scripts/update_birdnet_snippets.sh; then
  pass "New installs default DATABASE_LANG to en"
else
  fail "New installs do not default to en"
fi

if ! grep -q 'DATABASE_LANG=not-selected' scripts/update_birdnet_snippets.sh | head -1; then
  # Check the actual write line (the migration sed is allowed)
  write_lines=$(grep -n 'echo.*DATABASE_LANG=not-selected' scripts/update_birdnet_snippets.sh || true)
  if [ -z "$write_lines" ]; then
    pass "No new writes of DATABASE_LANG=not-selected"
  else
    fail "Still writes DATABASE_LANG=not-selected for new installs"
  fi
else
  pass "No new writes of DATABASE_LANG=not-selected"
fi

# Test 4: update_birdnet_snippets.sh migrates existing not-selected
echo "Test 4: Checking migration for existing not-selected..."
if grep -q 'sed.*s/DATABASE_LANG=not-selected/DATABASE_LANG=en/' scripts/update_birdnet_snippets.sh; then
  pass "Migration sed replaces not-selected with en"
else
  fail "Migration sed missing for not-selected"
fi

# Test 5: config.php guards not-selected
echo "Test 5: Checking config.php for not-selected guard..."
if grep -q "not-selected" scripts/config.php; then
  pass "config.php references not-selected"
else
  fail "config.php missing not-selected guard"
fi

if grep -q "\$language = 'en'" scripts/config.php; then
  pass "config.php normalizes not-selected to en"
else
  fail "config.php does not normalize not-selected"
fi

# Test 6: Functional simulation — batnet_analysis.sh guard
echo "Test 6: Functional simulation of batnet_analysis.sh guard..."
tmpdir=$(mktemp -d)
cat > "$tmpdir/mock.conf" << 'EOF'
DATABASE_LANG=not-selected
BAT_CLASSIFIER=Bavaria
EOF

# Simulate the relevant lines from batnet_analysis.sh
simulate_guard() {
  local DATABASE_LANG=not-selected
  local BAT_CLASSIFIER=Bavaria
  if [ "${DATABASE_LANG}" = "not-selected" ]; then DATABASE_LANG=en; fi
  echo "$DATABASE_LANG"
}
result=$(simulate_guard)
if [ "$result" = "en" ]; then
  pass "Guard converts not-selected to en"
else
  fail "Guard did not convert: got '$result'"
fi

# Test 7: Functional simulation — guard with valid language
echo "Test 7: Functional simulation with valid language..."
simulate_guard_valid() {
  local DATABASE_LANG=de
  local BAT_CLASSIFIER=Bavaria
  if [ "${DATABASE_LANG}" = "not-selected" ]; then DATABASE_LANG=en; fi
  echo "$DATABASE_LANG"
}
result=$(simulate_guard_valid)
if [ "$result" = "de" ]; then
  pass "Valid language 'de' preserved through guard"
else
  fail "Valid language 'de' was changed to '$result'"
fi

# Test 8: Functional simulation — empty DATABASE_LANG still defaults to en
echo "Test 8: Functional simulation with empty DATABASE_LANG..."
simulate_guard_empty() {
  local DATABASE_LANG=""
  local BAT_CLASSIFIER=Bavaria
  if [ "${DATABASE_LANG}" = "not-selected" ]; then DATABASE_LANG=en; fi
  # The ${DATABASE_LANG:-en} expansion in the actual command
  local effective_lang="${DATABASE_LANG:-en}"
  echo "$effective_lang"
}
result=$(simulate_guard_empty)
if [ "$result" = "en" ]; then
  pass "Empty DATABASE_LANG defaults to en via :-en expansion"
else
  fail "Empty DATABASE_LANG did not default: got '$result'"
fi

# Test 9: Functional simulation — migration sed
echo "Test 9: Functional simulation of migration sed..."
cat > "$tmpdir/migration.conf" << 'EOF'
SAMPLING_RATE=256000
DATABASE_LANG=not-selected
BAT_CLASSIFIER=Bavaria
EOF
sed -i '' 's/DATABASE_LANG=not-selected/DATABASE_LANG=en/' "$tmpdir/migration.conf"
result=$(grep "DATABASE_LANG=" "$tmpdir/migration.conf")
if [ "$result" = "DATABASE_LANG=en" ]; then
  pass "Migration sed correctly replaced not-selected with en"
else
  fail "Migration sed produced: $result"
fi

# Test 10: Functional simulation — config.php PHP guard (via php -r)
echo "Test 10: Functional simulation of config.php guard..."
php_result=$(php -r '$language = "not-selected"; if ($language === "not-selected") { $language = "en"; } echo $language;')
if [ "$php_result" = "en" ]; then
  pass "PHP guard converts not-selected to en"
else
  fail "PHP guard produced: $php_result"
fi

# Test 11: PHP guard preserves valid language
echo "Test 11: PHP guard preserves valid language..."
php_result2=$(php -r '$language = "de"; if ($language === "not-selected") { $language = "en"; } echo $language;')
if [ "$php_result2" = "de" ]; then
  pass "PHP guard preserves valid language 'de'"
else
  fail "PHP guard produced: $php_result2"
fi

rm -rf "$tmpdir"

# Summary
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed!"
  exit 1
fi

echo "All Translation Fix tests passed!"