# Hardware-in-the-Loop Tests - Raspberry Pi

This directory contains tests that run on a physical Raspberry Pi via SSH.

## Quick Setup

### 1. Configure Pi Connection

Edit `tests/hardware/pi_config.json`:

```json
{
  "hostname": "birdnetpi.local",
  "username": "pi",
  "password": null,
  "key_file": "~/.ssh/id_rsa",
  "port": 22
}
```

**Recommended:** Use SSH key authentication (more secure than password).

### 2. Generate SSH Key (if you don't have one)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""
```

### 3. Copy Key to Pi

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub pi@birdnetpi.local
```

Or manually:
```bash
# On your Mac
cat ~/.ssh/id_rsa.pub | ssh pi@birdnetpi.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 4. Test Connection

```bash
ssh pi@birdnetpi.local
```

## Running Tests

### Run All Hardware Tests
```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi
pytest tests/hardware/ -v
```

### Run Specific Test Category
```bash
# System tests
pytest tests/hardware/test_system.py -v

# Service tests
pytest tests/hardware/test_services.py -v

# Audio hardware tests
pytest tests/hardware/test_audio.py -v

# GPIO tests (if connected)
pytest tests/hardware/test_gpio.py -v
```

### Run with Custom Config
```bash
pytest tests/hardware/ -v --pi-host=192.168.1.100 --pi-user=pi
```

## Test Categories

### System Tests (`test_system.py`)
- CPU, memory, disk usage
- Temperature monitoring
- Network connectivity
- OS version detection

### Service Tests (`test_services.py`)
- systemd service status
- Service start/stop/restart
- Log file access
- Process monitoring

### Audio Tests (`test_audio.py`)
- Audio device detection
- Recording test
- Playback test
- Audio format support

### GPIO Tests (`test_gpio.py`)
- GPIO pin access
- LED control (if connected)
- Button input (if connected)

### Integration Tests (`test_integration.py`)
- Full detection workflow
- End-to-end recording
- Database operations on Pi

## Configuration

### Environment Variables
Override `pi_config.json` with environment variables:
```bash
export BATTY_PI_HOST=192.168.1.100
export BATTY_PI_USER=pi
export BATTY_PI_KEY_FILE=~/.ssh/id_rsa
```

### Command Line Arguments
```bash
pytest tests/hardware/ --pi-host=192.168.1.100 --pi-port=2222
```

## Troubleshooting

### Connection Refused
- Check Pi is on network: `ping birdnetpi.local`
- Verify SSH is running: `ssh pi@birdnetpi.local`
- Check firewall settings on Pi

### Permission Denied
- Verify SSH key is copied: `ssh-copy-id pi@birdnetpi.local`
- Check key file permissions: `chmod 600 ~/.ssh/id_rsa`

### Tests Timeout
- Increase timeout in `conftest.py`
- Check network latency
- Verify Pi isn't overloaded

## Skipping Hardware Tests

If Pi is not available, skip hardware tests:
```bash
pytest tests/ -v -k "not hardware"
```

Or mark tests as hardware-only in `conftest.py`.