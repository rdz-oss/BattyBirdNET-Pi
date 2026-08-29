# Tomorrow's Test Plan on Real Pi

## 📋 What You'll Do (Step by Step)

### **Morning Setup (15 minutes)**

#### 1. Connect Pi to Network
```bash
# Plug in Ethernet OR configure WiFi
# Power on Pi
# Wait 2 minutes for boot
```

#### 2. Find Pi's IP Address
```bash
# Check your router's DHCP client list
# OR use nmap from your Mac:
nmap -sn 192.168.1.0/24 | grep -B1 "Raspberry Pi"
```

#### 3. Configure Connection
```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi

# Edit the config file
nano tests/hardware/pi_config.json
```

**Change to:**
```json
{
  "hostname": "192.168.1.XXX",
  "username": "pi",
  "key_file": "~/.ssh/id_rsa",
  "port": 22
}
```

#### 4. Test Connection
```bash
# Test SSH
ssh pi@192.168.1.XXX

# If that works, test the deploy tool
./deploy --status
```

---

### **Deploy BattyBirdNET-Pi (10-15 minutes)**

#### Option A: Fresh Install (Recommended for First Time)
```bash
# Complete fresh install from dev branch
./deploy --install

# Or from your local code
./deploy --install --local
```

#### Option B: Quick Deploy (if already installed)
```bash
# Update to latest
./deploy

# Or deploy your local changes
./deploy --local
```

**Wait for:** "✓ Installation complete" or "✓ Deployment complete"

---

### **Run Hardware Tests (10-15 minutes)**

#### Run All Tests
```bash
# Full test suite
pytest tests/hardware/ -v

# Or use the convenience script
tests/hardware/run_all_tests.sh
```

#### Run Specific Test Categories
```bash
# System tests (CPU, memory, disk, network)
pytest tests/hardware/test_system.py -v

# Service tests (systemd, logs, processes)
pytest tests/hardware/test_services.py -v

# Audio tests (recording, devices, formats)
pytest tests/hardware/test_audio.py -v

# Integration tests (full stack health)
pytest tests/hardware/test_integration.py -v

# Skip GPIO tests (unless you have hardware connected)
pytest tests/hardware/ -v -m "not requires_gpio"
```

---

## 🧪 What Gets Tested

### **1. System Tests** (`test_system.py`) - 20+ tests

**What's tested:**
- ✅ Hostname resolves
- ✅ OS version (Raspberry Pi OS)
- ✅ CPU architecture (ARM64)
- ✅ Python 3 available
- ✅ CPU info and load
- ✅ CPU temperature
- ✅ Memory usage
- ✅ Disk space
- ✅ Network interfaces
- ✅ Internet connectivity
- ✅ USB devices
- ✅ Audio devices detected

**Example output:**
```
tests/hardware/test_system.py::TestCPU::test_cpu_temperature PASSED
tests/hardware/test_system.py::TestMemory::test_memory_usage_reasonable PASSED
tests/hardware/test_system.py::TestNetwork::test_internet_connectivity PASSED
```

---

### **2. Service Tests** (`test_services.py`) - 25+ tests

**What's tested:**
- ✅ birdnet_server service exists
- ✅ birdnet_analysis service status
- ✅ Services can start/stop/restart
- ✅ Logs accessible via journalctl
- ✅ Service configuration
- ✅ Python dependencies installed
- ✅ Required directories exist
- ✅ Config file accessible

**Example output:**
```
tests/hardware/test_services.py::TestServiceStatus::test_birdnet_server_running PASSED
tests/hardware/test_services.py::TestServiceControl::test_service_restart PASSED
tests/hardware/test_services.py::TestServiceLogs::test_birdnet_logs_accessible PASSED
```

---

### **3. Audio Tests** (`test_audio.py`) - 15+ tests

**What's tested:**
- ✅ arecord command available
- ✅ Audio capture devices detected
- ✅ USB audio device (bat detector)
- ✅ Recording test (2 seconds of silence)
- ✅ Recording file created
- ✅ File format correct (WAV)
- ✅ 256kHz sample rate support
- ✅ 384kHz sample rate support
- ✅ 16-bit format support
- ✅ Audio group permissions

**Example output:**
```
tests/hardware/test_audio.py::TestAudioDevices::test_usb_audio_device PASSED
tests/hardware/test_audio.py::TestRecording::test_record_silence PASSED
tests/hardware/test_audio.py::TestAudioFormats::test_sample_rate_256k PASSED
```

---

### **4. Integration Tests** (`test_integration.py`) - 20+ tests

**What's tested:**
- ✅ BattyBirdNET-Pi directory exists
- ✅ Key scripts present (server.py, analyze.py)
- ✅ Configuration file exists
- ✅ Config has required values (LATITUDE, LONGITUDE)
- ✅ Database exists and accessible
- ✅ Database schema valid
- ✅ Services running
- ✅ Web server responding (port 8080)
- ✅ Caddy web server running
- ✅ Disk space adequate
- ✅ Memory adequate
- ✅ Full stack health check

**Example output:**
```
tests/hardware/test_integration.py::TestInstallation::test_scripts_directory_exists PASSED
tests/hardware/test_integration.py::TestDatabase::test_database_accessible PASSED
tests/hardware/test_integration.py::TestEndToEnd::test_full_stack_health_check PASSED
```

---

### **5. GPIO Tests** (`test_gpio.py`) - 15+ tests ⚠️

**What's tested:**
- ✅ RPi.GPIO library installed
- ✅ gpiozero library installed
- ✅ GPIO pin access
- ✅ LED control (if connected)
- ✅ Pi model detection
- ✅ Pi serial number
- ✅ GPU memory
- ✅ CPU clock rates

**Note:** These require GPIO libraries and may need physical hardware (LEDs, buttons).

**Skip if no hardware:**
```bash
pytest tests/hardware/ -v -m "not requires_gpio"
```

---

## 📊 Expected Test Results

### **Typical Output (Healthy Pi):**
```
tests/hardware/test_system.py ................... [ 20%]
tests/hardware/test_services.py ..................... [ 45%]
tests/hardware/test_audio.py ............... [ 65%]
tests/hardware/test_integration.py .................. [ 90%]
tests/hardware/test_gpio.py sssss [100%]

=========== 95 passed, 5 skipped in 45.23s ===========
```

**Skipped tests are normal!** (GPIO without hardware)

---

## 🎯 What You'll Learn

After running tests, you'll know:

### ✅ System Health
- Is Pi running properly?
- Is it overheating?
- Enough disk space?
- Network working?

### ✅ Service Status  
- Are all services running?
- Can they restart cleanly?
- Are logs accessible?

### ✅ Audio Hardware
- Is USB audio device detected?
- Can it record?
- Does it support 256kHz/384kHz?

### ✅ BattyBirdNET-Pi Installation
- Is it installed correctly?
- Is config valid?
- Is database working?
- Is web interface accessible?

### ✅ Integration
- Does everything work together?
- Full stack health
- Ready for bat detection?

---

## 🐛 If Tests Fail

### "Cannot connect to Pi"
```bash
# Check Pi is on network
ping 192.168.1.XXX

# Check SSH
ssh pi@192.168.1.XXX

# Update pi_config.json with correct IP
```

### "Service not running"
```bash
# Check status
./deploy --status

# SSH in and check logs
ssh pi@birdnetpi.local
journalctl -u birdnet_server -n 50
```

### "Audio device not found"
```bash
# Check USB devices
ssh pi@birdnetpi.local "lsusb"

# Check audio devices
ssh pi@birdnetpi.local "arecord -l"
```

### "Tests skipped"
- **Normal!** Tests skip gracefully if hardware unavailable
- Check skip reason in output
- GPIO tests skip if no GPIO hardware

---

## 📈 Test Coverage Summary

| Category | Tests | What It Validates |
|----------|-------|-------------------|
| **System** | 20+ | CPU, memory, disk, network, temperature |
| **Services** | 25+ | systemd services, logs, configuration |
| **Audio** | 15+ | Recording devices, formats, sample rates |
| **Integration** | 20+ | Full stack, database, web interface |
| **GPIO** | 15+ | GPIO pins, LEDs, buttons (optional) |
| **TOTAL** | **95+** | Complete hardware & software health |

---

## 🎯 Quick Command Reference

```bash
# Full test suite
pytest tests/hardware/ -v

# Specific categories
pytest tests/hardware/test_system.py -v
pytest tests/hardware/test_services.py -v
pytest tests/hardware/test_audio.py -v
pytest tests/hardware/test_integration.py -v

# Skip GPIO
pytest tests/hardware/ -v -m "not requires_gpio"

# Check status
./deploy --status

# Deploy fresh
./deploy --install

# Deploy local changes
./deploy --local
```

---

## 📝 Checklist for Tomorrow

- [ ] Pi connected to network
- [ ] Pi IP address noted
- [ ] `tests/hardware/pi_config.json` configured
- [ ] SSH connection tested
- [ ] Deploy BattyBirdNET-Pi (`./deploy --install`)
- [ ] Run all tests (`pytest tests/hardware/ -v`)
- [ ] Review test results
- [ ] Fix any failures
- [ ] Check web interface: `http://192.168.1.XXX:8080`

---

**See Also:**
- `QUICK_START.md` - Setup checklist
- `DEPLOYMENT_GUIDE.md` - Deployment details
- `CLEAN_INSTALL.md` - Clean install options
- `CHEAT_SHEET.md` - Quick reference