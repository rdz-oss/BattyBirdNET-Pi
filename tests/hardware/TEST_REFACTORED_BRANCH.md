# Testing Your Refactored Branch

## 🎯 Quick Start

### Step 1: Configure Pi Connection
```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi

# Edit with your Pi's IP
nano tests/hardware/pi_config.json
```

### Step 2: Deploy Your Branch
```bash
# Replace 'your-branch-name' with actual branch name
./deploy --install --branch your-branch-name
```

### Step 3: Run Tests
```bash
# All hardware tests
pytest tests/hardware/ -v

# Or specific categories
pytest tests/hardware/test_system.py -v
pytest tests/hardware/test_services.py -v
pytest tests/hardware/test_integration.py -v
```

---

## 🔧 Deployment Options

### Deploy from GitHub Branch
```bash
# Install from your refactored branch
./deploy --install --branch feature/test-infrastructure

# Or update existing install
./deploy --update --branch feature/test-infrastructure
```

### Deploy from Local + Branch
If you want to test local changes AND a specific branch:
```bash
# Deploy local code (your current work)
./deploy --local

# Or deploy from branch
./deploy --install --branch feature/test-infrastructure
```

---

## 🧪 What to Test

### **1. Verify Refactored Code is Running**
```bash
# Check which branch is deployed
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && git branch"

# Check recent commits
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && git log --oneline -5"
```

### **2. Run Hardware Tests**
```bash
# Full suite
pytest tests/hardware/ -v

# Focus on integration (tests refactored components)
pytest tests/hardware/test_integration.py -v
```

### **3. Verify Services Work**
```bash
# Check status
./deploy --status

# Expected output:
# ✓ birdnet_server: active
# ✓ birdnet_analysis: active
# ✓ batnet_server: active
```

### **4. Check Logs**
```bash
# View recent logs
ssh pi@birdnetpi.local "journalctl -u birdnet_server -n 50"

# Follow logs in real-time
ssh pi@birdnetpi.local "journalctl -f -u birdnet_server"
```

---

## 📋 Test Checklist

### Code Deployment
- [ ] Branch name matches expected
- [ ] Recent commits present
- [ ] All files synced

### System Tests
- [ ] `test_system.py` - All pass
- [ ] CPU, memory, disk OK
- [ ] Network connectivity OK

### Service Tests
- [ ] `test_services.py` - All pass
- [ ] Services start/stop/restart
- [ ] Logs accessible

### Integration Tests
- [ ] `test_integration.py` - All pass
- [ ] Database accessible
- [ ] Web interface responding
- [ ] Config valid

### Refactored Components
- [ ] Server module loads
- [ ] Config package works
- [ ] Logging works
- [ ] Type hints don't break anything

---

## 🔍 Verify Refactored Code

### Check Modular Server Code
```bash
# SSH into Pi
ssh pi@birdnetpi.local

# Check server module structure
ls -la ~/BattyBirdNET-Pi/scripts/server/

# Expected files:
# __init__.py
# socket_server.py
# client_handler.py
# analysis_client.py
# results_writer.py
# species_filter.py
# database_ops.py
```

### Check Config Package
```bash
# Check config module structure
ls -la ~/BattyBirdNET-Pi/scripts/config/

# Expected files:
# __init__.py
# config_loader.py
# config_validator.py
# config_defaults.py
# config_manager.py
```

### Check PHP Modules
```bash
# Check PHP config modules
ls -la ~/BattyBirdNET-Pi/scripts/php/config/

# Expected files:
# ConfigHandler.php
# SettingsProcessor.php
# etc.
```

### Verify Type Hints
```bash
# Check if server module has type hints
ssh pi@birdnetpi.local "head -50 ~/BattyBirdNET-Pi/scripts/server/socket_server.py"

# Look for: def function(param: type) -> return_type:
```

---

## 🐛 Troubleshooting

### Branch Not Deployed
```bash
# Force reinstall from branch
./deploy --reinstall --branch feature/test-infrastructure
```

### Services Won't Start
```bash
# Check logs
ssh pi@birdnetpi.local "journalctl -u birdnet_server -n 100"

# Check for import errors
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && python3 -c 'from scripts.server import socket_server'"
```

### Tests Fail
```bash
# Run with more detail
pytest tests/hardware/test_integration.py -v --tb=long

# Check what's actually on Pi
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && git status"
```

---

## 📊 Expected Test Results

### Healthy Refactored Installation
```
tests/hardware/test_system.py ................... [ 20%]
tests/hardware/test_services.py ..................... [ 45%]
tests/hardware/test_audio.py ............... [ 65%]
tests/hardware/test_integration.py .................. [ 90%]
tests/hardware/test_gpio.py sssss [100%]

=========== 90+ passed, 5 skipped in 45 seconds ===========
```

### If Refactored Code Has Issues
- Import errors in logs
- Services fail to start
- Tests fail with `ModuleNotFoundError`
- Type hint errors

---

## 🎯 Quick Commands

```bash
# Deploy refactored branch
./deploy --install --branch feature/test-infrastructure

# Verify branch
ssh pi@birdnetpi.local "cd ~/BattyBirdNET-Pi && git branch"

# Run all tests
pytest tests/hardware/ -v

# Check services
./deploy --status

# View logs
ssh pi@birdnetpi.local "journalctl -f -u birdnet_server"
```

---

## ✅ Success Criteria

Your refactored branch is working if:

- ✅ All hardware tests pass (90+ tests)
- ✅ Services start and stay running
- ✅ No import errors in logs
- ✅ Modular code structure present on Pi
- ✅ Web interface accessible
- ✅ Database operations work
- ✅ Audio recording works

---

**See Also:**
- `TOMORROW_PLAN.md` - Complete test plan
- `DEPLOYMENT_GUIDE.md` - Deployment details
- `CHEAT_SHEET.md` - Quick reference
