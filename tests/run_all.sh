#!/usr/bin/env bash
# Run all validation tests and lint checks
# Usage: bash tests/run_all.sh [--fast]
#   --fast  : only run syntax/lint checks, skip functional tests
set -euo pipefail

cd "$(dirname "$0")/.."

PASS=0
FAIL=0
SKIP=0

FAST="${1:-}"

divider() { printf '=%.0s' {1..72}; echo; }
section() { divider; echo " $1"; divider; }

# ─── 1. Bash syntax checks ────────────────────────────────────────────────────
section "Bash syntax checks"

for f in scripts/*.sh; do
  [ -f "$f" ] || continue
  if bash -n "$f" 2>/dev/null; then
    echo "  OK   $f"
    PASS=$((PASS + 1))
  else
    echo "  FAIL $f"
    FAIL=$((FAIL + 1))
  fi
done

# Also check tests/*.sh
for f in tests/*.sh; do
  [ -f "$f" ] || continue
  [ "$f" = "tests/run_all.sh" ] && continue
  if bash -n "$f" 2>/dev/null; then
    echo "  OK   $f"
    PASS=$((PASS + 1))
  else
    echo "  FAIL $f"
    FAIL=$((FAIL + 1))
  fi
done

# ─── 2. PHP lint checks ──────────────────────────────────────────────────────
section "PHP lint checks"

php_cmd=""
if command -v php &>/dev/null; then
  php_cmd="php"
elif command -v php8.2 &>/dev/null; then
  php_cmd="php8.2"
fi

if [ -n "$php_cmd" ]; then
  for f in scripts/*.php; do
    [ -f "$f" ] || continue
    if $php_cmd -l "$f" 2>&1 | grep -q "No syntax errors"; then
      echo "  OK   $f"
      PASS=$((PASS + 1))
    else
      echo "  FAIL $f"
      FAIL=$((FAIL + 1))
    fi
  done
else
  echo "  SKIP php not found, skipping PHP lint"
  SKIP=$((SKIP + 18))  # 18 PHP files
fi

# ─── 3. Functional test suites ────────────────────────────────────────────────
if [ "$FAST" = "--fast" ]; then
  echo ""
  echo "Fast mode: skipping functional tests."
else
  # ── Shell tests ──
  section "Shell tests"

  # Some tests require systemd (Pi-only). On macOS, skip them gracefully.
  ON_MAC=false
  if [[ "$(uname -s)" == "Darwin" ]]; then
    ON_MAC=true
  fi

  test_scripts=(
    tests/test_bat_privacy_highpass.sh
    tests/test_disk_check.sh
    tests/test_backup_functional.sh
    tests/test_helper_integration.sh
    tests/test_install_integration.sh
    tests/test_mode_switching_sampling_rate.sh
    tests/test_translation_fix.sh
    tests/test_watchdog_logic.sh
    tests/test_s3_backup.sh
  )

  pi_only_tests="test_backup_functional test_helper_integration test_watchdog_logic"

  for t in "${test_scripts[@]}"; do
    [ -f "$t" ] || continue
    tname=$(basename "$t" .sh)

    # Skip Pi-only tests on macOS
    if $ON_MAC && echo "$pi_only_tests" | grep -qw "$tname"; then
      echo "  SKIP $tname (requires systemd/Pi)"
      SKIP=$((SKIP + 1))
      continue
    fi

    if bash "$t" > "/tmp/test_${tname}.out" 2>&1; then
      echo "  PASS $tname"
      PASS=$((PASS + 1))
    else
      echo "  FAIL $tname — see /tmp/${tname}.out"
      FAIL=$((FAIL + 1))
    fi
  done

  # ── Python tests ──
  section "Python tests"

  python_cmd=""
  if [ -f birdnet/bin/python3 ]; then
    python_cmd="birdnet/bin/python3"
  elif command -v python3 &>/dev/null; then
    python_cmd="python3"
  fi

  if [ -n "$python_cmd" ]; then
    for t in tests/test_*.py; do
      [ -f "$t" ] || continue
      tname=$(basename "$t" .py)

      # test_apprise_notifications.py requires pytest-mock from the birdnet venv
      if [ "$tname" = "test_apprise_notifications" ] && [ "$python_cmd" != "birdnet/bin/python3" ]; then
        echo "  SKIP $tname (requires birdnet venv with pytest-mock)"
        SKIP=$((SKIP + 1))
        continue
      fi

      set +e
      $python_cmd -m pytest "$t" -q 2>&1 | tee "/tmp/test_${tname}.out"
      rc=$?
      set -e

      if [ $rc -eq 0 ]; then
        echo "  PASS $tname"
        PASS=$((PASS + 1))
      elif [ $rc -eq 5 ]; then
        echo "  SKIP $tname (no tests collected)"
        SKIP=$((SKIP + 1))
      else
        echo "  FAIL $tname — see /tmp/${tname}.out"
        FAIL=$((FAIL + 1))
      fi
    done
  else
    echo "  SKIP python3 not found, skipping Python tests"
    for t in tests/test_*.py; do
      [ -f "$t" ] || continue
      SKIP=$((SKIP + 1))
    done
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
section "Summary"

total=$((PASS + FAIL + SKIP))
echo "  Passed:   $PASS"
echo "  Failed:   $FAIL"
echo "  Skipped:  $SKIP"
echo "  Total:    $total"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "  RESULT: FAIL"
  exit 1
else
  echo "  RESULT: PASS"
  exit 0
fi