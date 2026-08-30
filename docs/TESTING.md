# Testing

## Quick Start

```bash
# Full test suite (syntax + lint + functional)
bash tests/run_all.sh

# Fast mode only (syntax + lint, skips functional tests)
bash tests/run_all.sh --fast
```

## What Gets Tested

The runner (`tests/run_all.sh`) executes tests in three stages:

### 1. Syntax & Lint Gate

- **Bash syntax**: `bash -n` on every `.sh` file in `scripts/` and `tests/`
- **PHP lint**: `php -l` on every `.php` file in `scripts/`

This catches typos, broken brackets, and missing closures before any test runs. It is the fastest check and should pass on any platform (macOS, Pi, CI).

### 2. Shell Functional Tests

Executes each `test_*.sh` script and checks its exit code. Tests fall into two categories:

| Type | Runs on | Examples |
|------|---------|----------|
| **Portable** | Any Linux/macOS | `test_mode_switching_sampling_rate`, `test_translation_fix`, `test_bat_privacy_highpass`, S3 phase tests |
| **Pi-only** | Raspberry Pi (needs systemd) | `test_backup_functional`, `test_helper_integration`, `test_watchdog_logic` |

Pi-only tests are automatically skipped on macOS.

### 3. Python Tests

Runs `pytest` on `test_*.py` files. Uses the birdnet venv (`birdnet/bin/python3`) if available, otherwise falls back to system `python3`.

| Test | Requires | Notes |
|------|----------|-------|
| `test_settings_parse.py` | Any Python 3 | Standalone, no deps |
| `test_apprise_notifications.py` | birdnet venv + `pytest-mock` | Skipped if venv unavailable |

## Writing a New Test

### Shell Tests

1. Create `tests/test_<feature>.sh`
2. Use the standard `pass()`/`fail()` pattern:

```bash
#!/usr/bin/env bash
set -e
PASS=0; FAIL=0
pass() { echo "   PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "   FAIL: $1"; FAIL=$((FAIL + 1)); }

# Test here
if [ "$some_check" = "expected" ]; then
  pass "Description"
else
  fail "Description"
fi

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -gt 0 ] && exit 1
```

3. Add it to `tests/run_all.sh` in the `test_scripts` array.
4. If it requires systemd, add the basename to `pi_only_tests`.

### Python Tests

1. Create `tests/test_<feature>.py`
2. Use `pytest` with `tmp_path` or `monkeypatch` for isolation.
3. Avoid `pytest-mock` unless running inside the birdnet venv.

## Best Practices

- **Prefer functional over grep-only**: Running the actual script with mock inputs catches more bugs than grepping for strings.
- **Use `local` in functions**: Avoids polluting global state with `set -e`.
- **Use `if/then/fi` instead of `&&` chains**: `[ x = y ] && z` fails with `set -e` when the condition is false.
- **Portability**: Use `awk` instead of `grep -oP` (PCRE) for config parsing in tests. macOS grep lacks `-P`.
- **Temp files**: Use `mktemp -d` and clean up with `rm -rf`.

## Coverage Status

| Area | Coverage | Notes |
|------|----------|-------|
| Mode switching (SAMPLING_RATE) | Tested | 19 assertions |
| Translations (not-selected guard) | Tested | 16 assertions |
| S3 backup (consolidated) | Tested | 33 assertions |
| Disk check | Tested | 11 assertions |
| Bat high-pass filter | Tested | 13 assertions (grep-based) |
| Config parsing | Tested | 3 assertions |
| Analyze.py (ML pipeline) | **Not tested** | External repo (BattyBirdNET-Analyzer) |
| Recording scripts | **Not tested** | Gap |
| PHP logic (beyond lint) | **Not tested** | Gap |