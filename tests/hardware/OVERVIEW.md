# BattyBirdNET-Pi Remote Development & Testing Infrastructure

Complete infrastructure for remote development, deployment, and hardware-in-the-loop testing on Raspberry Pi.

---

## 📁 What Was Created

### Deployment Tool
- **`deploy_to_pi.py`** - Main deployment script
- **`deploy`** - Wrapper script for easy access

### Hardware Tests (5 suites, 100+ tests)
- **`test_system.py`** - System health (CPU, memory, disk, network)
- **`test_services.py`** - systemd services, logs, configuration
- **`test_audio.py`** - Audio hardware, recording, formats
- **`test_gpio.py`** - GPIO pins, LED control, Pi hardware info
- **`test_integration.py`** - End-to-end workflow tests

### Configuration
- **`pi_config.json`** - SSH connection settings
- **`conftest.py`** - Pytest fixtures (SSH, SCP, temp dirs)
- **`pytest.ini`** - Test configuration
- **`requirements.txt`** - Python dependencies

### Documentation
- **`README.md`** - Comprehensive documentation
- **`QUICK_START.md`** - Tomorrow's setup checklist
- **`DEPLOYMENT_GUIDE.md`** - Deploy/update/uninstall guide
- **`setup_pi.py`** - Automated Pi setup script

---

## 🚀 Quick Commands

### Deploy Code to Pi
```bash
# Update Pi with latest from dev branch
./deploy

# Deploy specific branch
./deploy --branch feature/my-branch

# Deploy local changes (rsync)
./deploy --deploy

# Check status
./deploy --status
```

### Run Hardware Tests
```bash
# All hardware tests
pytest tests/hardware/ -v

# Specific test suite
pytest tests/hardware/test_system.py -v
pytest tests/hardware/test_services.py -v
pytest tests/hardware/test_audio.py -v
pytest tests/hardware/test_integration.py -v

# Skip GPIO tests (no hardware connected)
pytest tests/hardware/ -m "not requires_gpio"
```

### Install/Uninstall
```bash
# Fresh install
./deploy --install

# Complete reinstall
./deploy --reinstall

# Uninstall
./deploy --uninstall
```

---

## 📋 Tomorrow's Setup Checklist

### Step 1: Connect Pi to Network
- [ ] Plug in Ethernet or configure WiFi
- [ ] Power on Pi
- [ ] Note IP address (check router or use `nmap -sn 192.168.1.0/24`)

### Step 2: Configure Connection
- [ ] Edit `tests/hardware/pi_config.json`:
```json
{
  "hostname": "192.168.1.XXX",
  "username": "pi",
  "key_file": "~/.ssh/id_rsa",
  "port": 22
}
```

### Step 3: Test Connection
```bash
# Test SSH
ssh pi@192.168.1.XXX

# Test deployment tool
./deploy --status
```

### Step 4: Install Dependencies (on Mac)
```bash
pip install -r tests/hardware/requirements.txt
```

### Step 5: Deploy & Test
```bash
# Deploy current dev branch
./deploy

# Run hardware tests
pytest tests/hardware/ -v
```

---

## 🎯 Capabilities

### Remote Deployment
✅ Install from GitHub branch
✅ Update via git pull
✅ Deploy from local development directory
✅ Uninstall completely
✅ Automatic backups before changes
✅ Service management (start/stop/restart)

### Hardware Testing
✅ System monitoring (CPU, memory, disk, temp)
✅ Service health checks
✅ Audio device detection & recording
✅ Network connectivity
✅ Database operations
✅ Log access
✅ GPIO control (optional, requires hardware)

### Development Workflow
```
Edit code locally → Deploy to Pi → Run tests → Verify → Repeat
```

---

## 📊 Test Coverage

### System Tests (20+ tests)
- Hostname, OS version, architecture
- CPU info, load, temperature
- Memory usage
- Disk space and usage
- Network interfaces, DNS, internet
- USB devices, audio devices

### Service Tests (25+ tests)
- Service status (active/inactive)
- Start/stop/restart operations
- Log access via journalctl
- Service configuration
- Dependencies check
- Process monitoring

### Audio Tests (15+ tests)
- Audio device detection
- Recording functionality
- Format support (WAV, 256kHz, 384kHz)
- Audio quality parameters
- Device permissions

### GPIO Tests (15+ tests) ⚠️ Requires hardware
- GPIO library availability
- Pin mode setting
- LED control
- Button input
- Pi hardware info (model, serial, revision)

### Integration Tests (20+ tests)
- Installation verification
- Configuration validation
- Database operations
- Service health
- Web server accessibility
- Full stack health checks

---

## 🔧 Configuration

### pi_config.json
```json
{
  "hostname": "birdnetpi.local",
  "username": "pi",
  "password": null,
  "key_file": "~/.ssh/id_rsa",
  "port": 22,
  "timeout": 30,
  "install_path": "/home/pi/BattyBirdNET-Pi",
  "config_path": "/etc/birdnet/birdnet.conf"
}
```

### Environment Variables (override config)
```bash
export BATTY_PI_HOST=192.168.1.100
export BATTY_PI_USER=pi
export BATTY_PI_KEY_FILE=~/.ssh/id_rsa
```

### Command Line Options
```bash
./deploy --help

# Common options:
--branch BRANCH      # Git branch to deploy
--install            # Fresh install
--update             # Git pull update
--uninstall          # Remove everything
--reinstall          # Uninstall + install
--deploy             # Deploy local changes
--status             # Show status
--no-backup          # Skip backup
--no-restart         # Don't restart services
-v, --verbose        # Verbose output
```

---

## 🎓 Usage Examples

### Daily Development
```bash
# Make changes locally
git checkout feature/my-feature
# Edit files...

# Deploy to Pi for testing
./deploy --deploy

# Run tests
pytest tests/hardware/test_services.py -v

# Check status
./deploy --status
```

### Update to Latest Dev
```bash
# Update Pi to latest dev branch
./deploy --update --branch dev

# Verify
./deploy --status
```

### Test Different Branches
```bash
# Test feature branch
./deploy --install --branch feature/audio-improvements

# Run audio tests
pytest tests/hardware/test_audio.py -v

# Switch back to dev
./deploy --update --branch dev
```

### Troubleshooting
```bash
# Check what's wrong
./deploy --status

# SSH in for manual debugging
ssh pi@birdnetpi.local

# Reinstall if needed
./deploy --reinstall

# Check logs
ssh pi@birdnetpi.local "journalctl -u birdnet_server -n 50"
```

---

## 📁 File Structure

```
tests/hardware/
├── README.md              # Comprehensive docs
├── QUICK_START.md         # Quick reference
├── DEPLOYMENT_GUIDE.md    # Deployment documentation
├── pi_config.json         # Connection config
├── conftest.py            # Pytest fixtures
├── pytest.ini            # Test configuration
├── requirements.txt       # Dependencies
├── setup_pi.py            # Pi setup automation
├── deploy_to_pi.py        # Main deployment tool
├── __init__.py            # Package marker
├── test_system.py         # System tests
├── test_services.py       # Service tests
├── test_audio.py          # Audio tests
├── test_gpio.py           # GPIO tests
└── test_integration.py    # Integration tests

../
└── deploy                 # Wrapper script
```

---

## 🔒 Security

### SSH Key Authentication (Recommended)
```bash
# Generate key
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""

# Copy to Pi
ssh-copy-id pi@birdnetpi.local
```

### Password Authentication
Configure in `pi_config.json`:
```json
{
  "hostname": "birdnetpi.local",
  "username": "pi",
  "password": "your-password"
}
```

---

## ⚠️ Important Notes

### Non-Destructive
- ✅ All operations create backups automatically
- ✅ Tests skip gracefully if hardware unavailable
- ✅ Config files preserved by default
- ✅ Database backed up before changes

### Requirements
- **Mac/Linux:** Python 3.8+, SSH client
- **Pi:** Raspberry Pi OS, SSH enabled, Python 3
- **Network:** Pi accessible from development machine

### What Gets Backed Up
- `/etc/birdnet/birdnet.conf` (configuration)
- `birds.db` (database)
- `Include.txt`, `Exclude.txt` (user lists)

Backups stored in `/tmp/battyird_backup_TIMESTAMP/`

---

## 🐛 Troubleshooting

### "Cannot connect to Pi"
```bash
# Check Pi is on network
ping birdnetpi.local

# Find Pi's IP
nmap -sn 192.168.1.0/24

# Update pi_config.json
```

### "Permission denied"
```bash
# Copy SSH key
ssh-copy-id pi@birdnetpi.local

# Or use password in pi_config.json
```

### "Tests skipped"
- Normal behavior when hardware not available
- Check test output for skip reasons
- GPIO tests require physical hardware

### "Service failed to start"
```bash
# Check logs
ssh pi@birdnetpi.local "journalctl -u birdnet_server -n 50"

# Manual restart
ssh pi@birdnetpi.local "sudo systemctl restart birdnet_server"
```

---

## 🎯 Next Steps

1. **Set up Pi tomorrow**
   - Connect to network
   - Configure `pi_config.json`
   - Test connection

2. **Deploy and test**
   ```bash
   ./deploy
   pytest tests/hardware/ -v
   ```

3. **Integrate into workflow**
   - Deploy before testing
   - Run tests after each change
   - Monitor status regularly

4. **Advanced usage**
   - Test multiple branches
   - Deploy local changes
   - Automate with CI/CD

---

## 📞 Resources

- **Hardware Tests:** `tests/hardware/README.md`
- **Quick Start:** `tests/hardware/QUICK_START.md`
- **Deployment:** `tests/hardware/DEPLOYMENT_GUIDE.md`
- **Test Plan:** `TEST_PLAN.md`
- **Session Summary:** `SESSION_SUMMARY_2024-08-04.md`

---

**Created:** August 4, 2024  
**Status:** Ready for deployment  
**Tests:** 100+ hardware tests  
**Deployment:** Full install/update/uninstall support