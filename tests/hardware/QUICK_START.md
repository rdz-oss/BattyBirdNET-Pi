# Quick Start: Hardware Testing Setup

## Tomorrow's Setup Checklist

### On Your Mac (Development Machine)

1. **Install test dependencies:**
   ```bash
   cd /Users/batfish/dev/bat/BattyBirdNET-Pi
   pip install paramiko scp pytest
   ```

2. **Configure Pi connection:**
   - Edit `tests/hardware/pi_config.json`
   - Set your Pi's hostname/IP address
   - Example:
   ```json
   {
     "hostname": "192.168.1.100",
     "username": "pi",
     "key_file": "~/.ssh/id_rsa",
     "port": 22
   }
   ```

3. **Test SSH connection:**
   ```bash
   ssh pi@birdnetpi.local
   # or
   ssh pi@192.168.1.100
   ```

### On Your Raspberry Pi

1. **Connect Pi to network:**
   - Ethernet: Plug into router
   - WiFi: Configure via `raspi-config`

2. **Find Pi's IP address:**
   ```bash
   hostname -I
   # or check your router's DHCP client list
   ```

3. **Enable SSH (if not already):**
   ```bash
   sudo raspi-config
   # Interface Options → SSH → Enable
   ```

4. **Optional: Install GPIO libraries (for GPIO tests):**
   ```bash
   sudo apt update
   sudo apt install python3-rpi.gpio python3-gpiozero
   ```

### Run Tests

**From your Mac:**
```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi

# Run all hardware tests
pytest tests/hardware/ -v

# Run specific test category
pytest tests/hardware/test_system.py -v
pytest tests/hardware/test_services.py -v
pytest tests/hardware/test_audio.py -v
pytest tests/hardware/test_integration.py -v

# Skip GPIO tests (if GPIO not connected)
pytest tests/hardware/ -v -m "not requires_gpio"

# Use custom Pi address
pytest tests/hardware/ --pi-host=192.168.1.100 -v
```

## Test Coverage

### System Tests (`test_system.py`)
- ✅ Hostname and OS version
- ✅ CPU, memory, disk usage
- ✅ Temperature monitoring
- ✅ Network connectivity
- ✅ USB device detection

### Service Tests (`test_services.py`)
- ✅ systemd service status
- ✅ Service start/stop/restart
- ✅ Log access via journalctl
- ✅ Service configuration
- ✅ Dependencies check

### Audio Tests (`test_audio.py`)
- ✅ Audio device detection
- ✅ Recording test
- ✅ Format support (WAV, 256kHz, 384kHz)
- ✅ Audio quality parameters

### GPIO Tests (`test_gpio.py`) ⚠️ Requires hardware
- ⚠️ GPIO pin access
- ⚠️ LED control
- ⚠️ Button input
- ✅ Pi hardware info (model, serial, etc.)

### Integration Tests (`test_integration.py`)
- ✅ Installation verification
- ✅ Configuration validation
- ✅ Database operations
- ✅ Service health
- ✅ Web server accessibility

## Troubleshooting

### "Cannot connect to Pi"
```bash
# Check Pi is on network
ping birdnetpi.local

# Check SSH is running
ssh pi@birdnetpi.local

# Verify IP address
nmap -sn 192.168.1.0/24  # Find all devices on network
```

### "Permission denied"
```bash
# Copy SSH key to Pi
ssh-copy-id pi@birdnetpi.local

# Or use password
pytest tests/hardware/ --pi-host=192.168.1.100
# (will prompt for password if no key configured)
```

### "Test skipped"
- Tests are marked with `@pytest.skip()` when hardware isn't available
- This is normal and expected
- Check test output for skip reasons

### GPIO tests fail
- GPIO tests require physical hardware connections
- Install GPIO libraries: `sudo apt install python3-rpi.gpio python3-gpiozero`
- Or skip GPIO tests: `pytest tests/hardware/ -m "not requires_gpio"`

## Files Created

```
tests/hardware/
├── README.md              # Comprehensive documentation
├── QUICK_START.md         # This file
├── pi_config.json         # Connection configuration
├── conftest.py            # Pytest fixtures (SSH, SCP, etc.)
├── requirements.txt       # Python dependencies
├── setup_pi.py            # Automated Pi setup script
├── pytest.ini            # Pytest configuration
├── __init__.py           # Package marker
├── test_system.py        # System tests
├── test_services.py      # Service tests
├── test_audio.py         # Audio tests
├── test_gpio.py          # GPIO tests
└── test_integration.py   # Integration tests
```

## Next Steps

1. Set up Pi on network tomorrow
2. Configure `pi_config.json`
3. Run `pytest tests/hardware/ -v`
4. Review results and fix any issues
5. Integrate with your development workflow

## Advanced Usage

### Run tests from CI/CD
```yaml
# .github/workflows/hardware-tests.yml
- name: Run hardware tests
  run: pytest tests/hardware/ -v
  env:
    BATTY_PI_HOST: ${{ secrets.PI_HOST }}
    BATTY_PI_USER: ${{ secrets.PI_USER }}
```

### Generate HTML report
```bash
pytest tests/hardware/ -v --html=reports/hardware_test_report.html
```

### Run with coverage
```bash
pytest tests/hardware/ -v --cov=scripts
```

## Questions?

Check `README.md` for detailed documentation or run:
```bash
pytest tests/hardware/ --help
```