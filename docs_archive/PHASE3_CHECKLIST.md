# Phase 3: Hardware Testing Checklist
## Raspberry Pi Deployment & Testing

**Date:** 2026-08-05  
**Branch:** `feature/test-infrastructure`  
**Status:** Ready to Execute

---

## ✅ Pre-Deployment Checklist

### 1. Pi Setup
- [ ] Pi connected to network (Ethernet or WiFi)
- [ ] Pi powered on and booted (wait 2 minutes)
- [ ] Pi IP address identified (check router or use `nmap`)
- [ ] SSH key generated (`~/.ssh/id_rsa`)
- [ ] SSH key copied to Pi (`ssh-copy-id`)
- [ ] SSH connection tested (`ssh pi@IP`)

### 2. Configuration
- [ ] `tests/hardware/pi_config.json` edited with Pi's IP
- [ ] Connection tested: `./deploy --status`

### 3. Local Verification
- [ ] On correct branch: `git checkout feature/test-infrastructure`
- [ ] Local tests passing: `pytest tests/ -v`
- [ ] Refactored modules exist:
  - [ ] `scripts/server/` (6 modules)
  - [ ] `scripts/config/` (4 modules)
  - [ ] `scripts/php/config/` (6 modules)

---

## 🚀 Deployment

### Choose Deployment Method:

**Option A: Fresh Install (Recommended First Time)**
```bash
./deploy --install --local
```

**Option B: Update Existing**
```bash
./deploy --local
```

**Option C: Deploy from GitHub Branch**
```bash
git push -u origin feature/test-infrastructure
./deploy --install --branch feature/test-infrastructure
```

### Wait for:
- [ ] "✓ Installation complete" or "✓ Deployment complete"
- [ ] No errors in output

---

## ✅ Post-Deployment Verification

### 1. Check Deployment
- [ ] Branch correct: `ssh pi@IP "cd ~/BattyBirdNET-Pi && git branch"`
- [ ] Recent commits: `ssh pi@IP "cd ~/BattyBirdNET-Pi && git log --oneline -5"`
- [ ] Server module exists: `ssh pi@IP "ls ~/BattyBirdNET-Pi/scripts/server/"`
- [ ] Config package exists: `ssh pi@IP "ls ~/BattyBirdNET-Pi/scripts/config/"`
- [ ] PHP modules exist: `ssh pi@IP "ls ~/BattyBirdNET-Pi/scripts/php/config/"`

### 2. Test Imports
- [ ] Server module: `ssh pi@IP "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && python3 -c 'from scripts.server.socket_server import create_server_socket; print(\"OK\")'"`
- [ ] Config package: `ssh pi@IP "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && python3 -c 'from scripts.config.config_manager import ConfigManager; print(\"OK\")'"`
- [ ] Logging: `ssh pi@IP "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && python3 -c 'from scripts.utils.logging_config import setup_logging; print(\"OK\")'"`

### 3. Check Services
- [ ] Run: `./deploy --status`
- [ ] birdnet_server: active (running)
- [ ] birdnet_analysis: active (running)
- [ ] batnet_server: active (running)

### 4. Check Web Interface
- [ ] Open browser: `http://192.168.1.XXX:8080`
- [ ] Web interface loads
- [ ] Settings page accessible
- [ ] Database queries work

### 5. Check Audio
- [ ] USB devices: `ssh pi@IP "lsusb"`
- [ ] Audio devices: `ssh pi@IP "arecord -l"`
- [ ] Test recording: `ssh pi@IP "arecord -D hw:1,0 -r 256000 -c 1 -f S16_LE -d 2 /tmp/test.wav"`
- [ ] Verify file: `ssh pi@IP "file /tmp/test.wav"`

---

## 🧪 Hardware Tests

### Run All Tests
```bash
pytest tests/hardware/ -v
```

**Expected:** 95+ passed, 5 skipped (GPIO)

### Run by Category
- [ ] System: `pytest tests/hardware/test_system.py -v`
- [ ] Services: `pytest tests/hardware/test_services.py -v`
- [ ] Audio: `pytest tests/hardware/test_audio.py -v`
- [ ] Integration: `pytest tests/hardware/test_integration.py -v`
- [ ] Skip GPIO: `pytest tests/hardware/ -v -m "not requires_gpio"`

### Test Results
- [ ] 90+ tests pass
- [ ] System tests: CPU, memory, disk OK
- [ ] Service tests: All services running
- [ ] Audio tests: Recording works, 256kHz/384kHz supported
- [ ] Integration tests: Full stack healthy
- [ ] GPIO tests: Skipped (unless hardware connected)

---

## 📊 Success Criteria

### All Must Be True:
- [ ] Deploy completed without errors
- [ ] All imports work (no ModuleNotFoundError)
- [ ] All services running
- [ ] Web interface accessible
- [ ] Audio recording works
- [ ] 90+ hardware tests pass
- [ ] No errors in logs

### Logs Clean:
```bash
ssh pi@IP "journalctl -u birdnet_server -n 50"
```
- [ ] No import errors
- [ ] No tracebacks
- [ ] Services started successfully

---

## 🐛 If Issues Occur

### Cannot Connect to Pi
- [ ] Ping Pi: `ping 192.168.1.XXX`
- [ ] Check SSH: `ssh pi@192.168.1.XXX`
- [ ] Update `pi_config.json`

### Module Not Found
- [ ] Test locally first
- [ ] Redeploy: `./deploy --reinstall --local`
- [ ] Check files on Pi

### Services Won't Start
- [ ] Check logs: `journalctl -u birdnet_server -n 100`
- [ ] Check imports on Pi
- [ ] Restart: `sudo systemctl restart birdnet_server`

### Audio Device Not Found
- [ ] Check USB: `lsusb`
- [ ] Check audio: `arecord -l`
- [ ] Check permissions: `groups pi`
- [ ] Add to audio group: `sudo usermod -aG audio pi`

---

## 📝 Document Results

### In SESSION_LOG_PI_2026-08-05.md:
- [ ] Date/time
- [ ] Pi IP address
- [ ] Deployment command used
- [ ] Test results (paste summary)
- [ ] Service status
- [ ] Issues encountered (if any)
- [ ] Resolutions (if any)
- [ ] Notes/observations

---

## ✅ Phase 3 Complete When:

- [ ] All checklist items checked
- [ ] 90+ hardware tests pass
- [ ] All services running
- [ ] Refactored code verified on Pi
- [ ] Session log updated
- [ ] Ready for Phase 4

---

**Next:** Phase 4 - Continue Refactoring (audio processing, type hints, integration tests)

**See Also:**
- `HOWTO_REFACTORING_TESTING.md` - Complete howto guide
- `SESSION_LOG_PI_2026-08-05.md` - Session log
- `QUICK_START.md` - Quick setup
- `DEPLOYMENT_GUIDE.md` - Deployment details
