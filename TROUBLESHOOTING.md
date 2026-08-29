# BattyBirdNET-Pi Troubleshooting Guide

**Common issues and their solutions**

---

## Quick Diagnostics

```bash
# Check all services
ssh pi@[IP] "sudo systemctl status birdnet_server birdnet_analysis birdnet_recording"

# View recent logs
ssh pi@[IP] "journalctl -u birdnet_server -n 50"

# Check disk space
ssh pi@[IP] "df -h"

# Check memory
ssh pi@[IP] "free -h"
```

---

## Service Issues

### birdnet_server Won't Start

**Symptoms:**
```
Active: failed (Result: exit-code)
```

**Common Causes:**

1. **Port already in use**
   ```bash
   # Check what's using port 5050
   ssh pi@[IP] "netstat -tlnp | grep 5050"
   
   # Kill the process
   ssh pi@[IP] "sudo kill $(sudo lsof -t -i:5050)"
   
   # Restart service
   ssh pi@[IP] "sudo systemctl restart birdnet_server"
   ```

2. **Missing dependencies**
   ```bash
   ssh pi@[IP] "cd ~/BattyBirdNET-Pi && source birdnet/bin/activate && pip install tzlocal requests"
   ```

3. **Config file missing**
   ```bash
   ssh pi@[IP] "ls -la /etc/birdnet/birdnet.conf"
   # Should exist and be readable
   ```

### birdnet_analysis Keeps Stopping

**Symptoms:**
```
Active: inactive (dead)
Result: timeout
```

**Cause:** Analysis service has a runtime limit (15 minutes)

**Solution:** This is normal. The service auto-restarts when new recordings are available.

**Check if working:**
```bash
# Check for recent analysis runs
ssh pi@[IP] "journalctl -u birdnet_analysis -n 20 | grep 'Analyzing'"
```

### birdnet_recording Not Recording

**Symptoms:**
- No `.wav` files in `~/BirdSongs/`
- Service shows "failed" or "inactive"

**Check:**
```bash
# Check service status
ssh pi@[IP] "sudo systemctl status birdnet_recording"

# Check audio device
ssh pi@[IP] "arecord -l"

# Check recording directory
ssh pi@[IP] "ls -la ~/BirdSongs/"
```

**Fix:**
```bash
# Restart service
ssh pi@[IP] "sudo systemctl restart birdnet_recording"

# Check logs
ssh pi@[IP] "journalctl -u birdnet_recording -n 50"
```

---

## Web Interface Issues

### 403 Forbidden

**Cause:** Caddy can't access the files

**Fix:**
```bash
# Fix permissions
ssh pi@[IP] "sudo chmod 755 /home/bat"
ssh pi@[IP] "sudo chown -R www-data:www-data ~/BattyBirdNET-Pi/homepage"
ssh pi@[IP] "sudo chmod -R 755 ~/BattyBirdNET-Pi/homepage"

# Restart Caddy
ssh pi@[IP] "sudo systemctl restart caddy"
```

### Page Shows Only Toolbar (Green Below)

**Cause:** No detections in database yet

**This is normal for fresh installation!**

**Wait for:**
1. Recording service to create audio files (wait 5-10 minutes)
2. Analysis service to process them (automatic)
3. Detections to appear in database

**Check progress:**
```bash
# Check for recordings
ssh pi@[IP] "ls ~/BirdSongs/*/*/*.wav | wc -l"

# Check database
ssh pi@[IP] "sqlite3 ~/BattyBirdNET-Pi/scripts/birds.db 'SELECT COUNT(*) FROM detections;'"
```

### Can't Access Web Interface

**Check:**
```bash
# Is Caddy running?
ssh pi@[IP] "sudo systemctl status caddy"

# Is port 80 open?
ssh pi@[IP] "netstat -tlnp | grep :80"

# Can you reach the Pi?
ping 192.168.1.XXX
```

**Fix:**
```bash
# Restart Caddy
ssh pi@[IP] "sudo systemctl restart caddy"

# Check firewall
ssh pi@[IP] "sudo ufw status"
# Should allow port 80
```

---

## Audio Issues

### No USB Audio Device Detected

**Check:**
```bash
ssh pi@[IP] "lsusb"
ssh pi@[IP] "arecord -l"
```

**Expected:** Should see your USB microphone (e.g., "AudioMoth", "Generic USB Audio")

**If not found:**
1. Check USB connection
2. Try different USB port
3. Check if device works on another computer

### Recording Fails

**Symptoms:**
```
arecord: set_params failed: Invalid argument
```

**Fix:**
```bash
# Check available sample rates
ssh pi@[IP] "arecord -f S16_LE -r 256000 -D default --test-position /dev/null"

# Try different sample rate
ssh pi@[IP] "arecord -f S16_LE -r 48000 -d 2 /tmp/test.wav"
```

### Poor Audio Quality

**Check configuration:**
```bash
ssh pi@[IP] "grep -E 'SAMPLING_RATE|AUDIO_DEVICE' /etc/birdnet/birdnet.conf"
```

**Recommended settings:**
```
SAMPLING_RATE=256000  # For bats
AUDIO_DEVICE=default  # Or your USB device
```

---

## Database Issues

### Database Locked

**Symptoms:**
```
sqlite3.OperationalError: database is locked
```

**Fix:**
```bash
# Find processes using database
ssh pi@[IP] "lsof ~/BattyBirdNET-Pi/scripts/birds.db"

# Restart services
ssh pi@[IP] "sudo systemctl restart birdnet_server birdnet_analysis"
```

### Database Corrupted

**Symptoms:**
```
sqlite3.DatabaseError: database disk image is malformed
```

**Fix:**
```bash
# Backup
ssh pi@[IP] "cp ~/BattyBirdNET-Pi/scripts/birds.db ~/birds.db.backup"

# Recreate
ssh pi@[IP] "cd ~/BattyBirdNET-Pi/scripts && source birdnet/bin/activate && bash createdb.sh"
```

---

## Analyzer Issues

### Module Not Found: tensorflow

**Symptoms:**
```
ModuleNotFoundError: No module named 'tensorflow'
```

**Fix:**
```bash
ssh pi@[IP] "cd ~/BattyBirdNET-Analyzer && source birdnet_analyzer/bin/activate && pip install tensorflow librosa numpy"
```

### Analyzer Not Cloned

**Symptoms:**
```
ls: cannot access '/home/pi/BattyBirdNET-Analyzer': No such file or directory
```

**Fix:**
```bash
ssh pi@[IP] "git clone https://github.com/rdz-oss/BattyBirdNET-Analyzer.git ~/BattyBirdNET-Analyzer"
ssh pi@[IP] "cd ~/BattyBirdNET-Analyzer && python3 -m venv birdnet_analyzer"
ssh pi@[IP] "cd ~/BattyBirdNET-Analyzer && source birdnet_analyzer/bin/activate && pip install -r requirements.txt"
```

---

## Python 3.13 Issues

### tflite-runtime Not Available

**Problem:** `tflite-runtime` doesn't support Python 3.13

**Solution:** Use `tensorflow` instead

**Fix:**
```bash
# Edit requirements.txt
nano ~/BattyBirdNET-Pi/requirements.txt

# Change:
# tflite-runtime
# to:
tensorflow

# Install
cd ~/BattyBirdNET-Pi
source birdnet/bin/activate
pip install -r requirements.txt
```

---

## Deployment Issues

### Cannot Connect to Pi

**Check:**
```bash
ping 192.168.1.XXX
ssh pi@192.168.1.XXX
```

**Fix:**
1. Check Pi is powered on
2. Check network connection
3. Verify IP address
4. Update `tests/hardware/pi_config.json`

### Deploy Script Fails

**Common causes:**
1. **Wrong paths** - Check `install_path` in config
2. **Permission denied** - Use sudo or check user permissions
3. **Network timeout** - Increase timeout in config

**Debug:**
```bash
# Run with verbose output
./deploy -v --local

# Check SSH manually
ssh pi@[IP] "hostname"
```

---

## Performance Issues

### High CPU Usage

**Check:**
```bash
ssh pi@[IP] "top -bn1 | head -20"
```

**Normal:** CPU usage spikes during analysis

**If always high:**
1. Check for runaway processes
2. Reduce number of parallel analyses
3. Check for infinite loops in custom scripts

### Low Disk Space

**Check:**
```bash
ssh pi@[IP] "df -h"
```

**If /home is full:**
```bash
# Find large files
ssh pi@[IP] "du -ah ~/ | sort -rh | head -20"

# Clean old recordings
ssh pi@[IP] "find ~/BirdSongs -name '*.wav' -mtime +30 -delete"
```

---

## Configuration Issues

### Wrong Location

**Symptoms:** Detections show wrong species for your area

**Fix:**
1. Open web interface
2. Go to **Tools → Settings → Location**
3. Enter correct latitude/longitude
4. Save

**Or manually:**
```bash
ssh pi@[IP] "sudo nano /birdnet.conf"
# Edit LATITUDE and LONGITUDE
```

### Wrong Threshold

**Symptoms:** Too many false positives or missed detections

**Fix:**
```bash
ssh pi@[IP] "sudo nano /birdnet.conf"
# Adjust SF_THRESH (default: 0.03)
# Lower = more sensitive, more false positives
# Higher = less sensitive, fewer false positives
```

---

## Getting Help

### Collect Debug Information

```bash
# System info
ssh pi@[IP] "uname -a"
ssh pi@[IP] "cat /etc/os-release"

# Python version
ssh pi@[IP] "python3 --version"

# Service status
ssh pi@[IP] "sudo systemctl status birdnet_server birdnet_analysis birdnet_recording"

# Recent errors
ssh pi@[IP] "journalctl -u birdnet_server -u birdnet_analysis -u birdnet_recording --since '1 hour ago'"

# Disk space
ssh pi@[IP] "df -h"

# Memory
ssh pi@[IP] "free -h"
```

### Where to Get Help

1. **Check logs first** - Most issues are logged
2. **Review documentation** - See `README_DEPLOYMENT.md`
3. **Run tests** - `pytest tests/hardware/ -v`
4. **Check GitHub issues** - Someone may have had the same problem

---

**Last Updated:** 2026-08-05  
**Version:** 1.0
