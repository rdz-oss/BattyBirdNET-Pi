#!/bin/bash
# Run all hardware tests with sensible defaults

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../"

echo "========================================"
echo "BattyBirdNET-Pi Hardware Tests"
echo "========================================"
echo ""

# Check if config exists
if [ ! -f "tests/hardware/pi_config.json" ]; then
    echo "❌ pi_config.json not found!"
    echo "   Please configure tests/hardware/pi_config.json first"
    exit 1
fi

# Test connection first
echo "Testing connection to Pi..."
python3 tests/hardware/deploy_to_pi.py --status || {
    echo ""
    echo "❌ Cannot connect to Pi!"
    echo "   Check pi_config.json and network connection"
    exit 1
}

echo ""
echo "Running hardware tests..."
echo "========================================"
echo ""

# Run tests
pytest tests/hardware/ -v --tb=short "$@"

# Show summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
pytest tests/hardware/ -q --tb=no "$@"
