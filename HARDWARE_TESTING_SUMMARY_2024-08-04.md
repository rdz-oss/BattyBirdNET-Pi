# BattyBirdNET-Pi Hardware Testing Infrastructure
## Session Summary - August 4, 2024

---

## 🎯 What Was Created

**Complete remote deployment & hardware testing infrastructure** for testing BattyBirdNET-Pi on Raspberry Pi via SSH.

### Files Created (22 files in `tests/hardware/`)

**Deployment Tool:**
- `deploy_to_pi.py` - Main deployment script (SSH/SCP/rsync)
- `../deploy` - Wrapper script for easy access

**Hardware Tests (100+ tests):**
- `test_system.py` - System health (CPU, memory, disk, network, temp)
- `test_services.py` - systemd services, logs, configuration
- `test_audio.py` - Audio devices, recording, 256kHz/384kHz
- `test_gpio.py` - GPIO pins, LEDs, buttons (optional)
- `test_integration.py` - End-to-end workflow, full stack health

**Configuration:**
- `pi_config.json` - SSH connection settings (EDIT THIS!)
- `conftest.py` - Pytest fixtures (SSH, SCP, temp dirs)
- `pytest.ini` - Test configuration
- `requirements.txt` - Python dependencies

**Documentation:**
- `OVERVIEW.md` - Complete summary
- `QUICK_START.md` - Setup checklist
- `DEPLOYMENT_GUIDE.md` - Deploy/update/uninstall guide
- `DEPLOYMENT_MODES.md` - 3 deployment modes explained
- `CHEAT_SHEET.md` - Quick reference
- `TOMORROW_PLAN.md` - Complete test plan for Pi
- `TEST_REFACTORED_BRANCH.md` - Testing your branch
- `SERVICES_SETUP.md` - Service installation details
- `CLEAN_INSTALL.md` - Clean install options
- `WHICH_VERSION.md` - What gets deployed

**Utilities:**
- `setup_pi.py` - Automated Pi preparation
- `run_all_tests.sh` - One-command test runner

---

## 🚀 Tomorrow: Deploy & Test Your Refactored Branch

### **Step 1: Connect Pi to Network**
- Plug in Ethernet or configure WiFi
- Power on Pi
- Note IP address (check router or `nmap -sn 192.168.1.0/24`)

### **Step 2: Configure Connection**
```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi
nano tests/hardware/pi_config.json
```

Change to your Pi's IP:
```json
{
  "hostname": "192.168.1.XXX",
  "username": "pi",
  "key_file": "~/.ssh/id_rsa",
  "port": 22
}
```

### **Step 3: Deploy Your Refactored Branch**
```bash
# Make sure you're on your branch
git checkout feature/test-infrastructure

# Deploy LOCAL code to Pi (includes all refactored modules)
./deploy --local
```

**What gets deployed:**
- ✅ Your local refactored code (server/, config/, php/config/)
- ✅ All services installed/reinstalled
- ✅ Dependencies installed
- ✅ Database created (if missing)
- ✅ Config setup (if missing)

### **Step 4: Verify Deployment**
```bash
# Check status
./deploy --status

# Verify refactored modules exist
ssh pi@birdnetpi.local "ls ~/BattyBirdNET-Pi/scripts/server/"
ssh pi@birdnetpi.local "ls ~/BattyBirdNET-Pi/scripts/config/"

# Test imports
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && python3 -c 'from scripts.server.socket_server import create_server_socket; print(\"OK\")'"
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && python3 -c 'from scripts.config.config_manager import ConfigManager; print(\"OK\")'"
```

### **Step 5: Run Hardware Tests**
```bash
# All tests (100+)
pytest tests/hardware/ -v

# Or specific categories
pytest tests/hardware/test_system.py -v
pytest tests/hardware/test_services.py -v
pytest tests/hardware/test_audio.py -v
pytest tests/hardware/test_integration.py -v

# Skip GPIO if no hardware
pytest tests/hardware/ -v -m "not requires_gpio"
```

---

## 🎯 What Gets Tested

### System Tests (20+ tests)
- CPU, memory, disk usage
- Temperature monitoring
- Network connectivity
- USB/audio devices detected

### Service Tests (25+ tests)
- All birdnet services running
- Start/stop/restart works
- Logs accessible via journalctl
- Configuration valid

### Audio Tests (15+ tests)
- USB audio device detected
- Recording works
- 256kHz & 384kHz support
- WAV format support

### Integration Tests (20+ tests)
- Installation complete
- Database accessible
- Web interface responding
- Full stack health check
- **Your refactored code loads without errors**

---

## 🔧 Key Commands

```bash
# Deploy local code
./deploy --local

# Fresh install from local
./deploy --install --local

# Reinstall (clean)
./deploy --reinstall --local

# Deploy from GitHub branch
./deploy --install --branch feature/test-infrastructure

# Check status
./deploy --status

# Run all tests
pytest tests/hardware/ -v

# Quick test runner
tests/hardware/run_all_tests.sh
```

---

## ✅ Success Criteria

Your refactored branch works on Pi if:
- ✅ All hardware tests pass (90+ tests)
- ✅ Services start and stay running
- ✅ No import errors in logs
- ✅ Modular code structure present:
  - `scripts/server/` (6 modules)
  - `scripts/config/` (4 modules)
  - `scripts/php/config/` (6 modules)
- ✅ Web interface accessible
- ✅ Database operations work
- ✅ Audio recording works

---

## 🐛 Common Issues

### "Cannot connect to Pi"
```bash
ping 192.168.1.XXX
ssh pi@192.168.1.XXX
# Update pi_config.json
```

### "Module not found"
```bash
# Test locally first
python3 -c 'from scripts.server.socket_server import create_server_socket'

# Then redeploy
./deploy --reinstall --local
```

### Services won't start
```bash
# Check logs
ssh pi@birdnetpi.local "journalctl -u birdnet_server -n 100"
```

---

## 📁 File Locations

```
tests/hardware/
├── deploy_to_pi.py          # Main deployment tool
├── conftest.py              # Pytest fixtures
├── pi_config.json           # EDIT THIS with Pi's IP
├── test_*.py                # 5 test suites
├── QUICK_START.md           # Setup checklist
├── TOMORROW_PLAN.md         # Complete test plan
└── TEST_REFACTORED_BRANCH.md # Your branch testing guide

../
└── deploy                   # Wrapper script
```

---

## 🎯 Quick Start Tomorrow

```bash
# 1. Configure Pi IP
nano tests/hardware/pi_config.json

# 2. Deploy your refactored branch
git checkout feature/test-infrastructure
./deploy --local

# 3. Run tests
pytest tests/hardware/ -v

# 4. Check status
./deploy --status
```

**Expected:** 90+ tests pass, all services running, refactored modules working ✅

---

**Previous Context:** See `SESSION_SUMMARY_2024-08-04.md` for Phase 1 & 2 refactoring work (server modularization, config package, PHP modules, logging, type hints).

**Today:** Hardware testing infrastructure ready for deployment to real Pi.

**Status:** Ready to deploy and test refactored branch on physical hardware.