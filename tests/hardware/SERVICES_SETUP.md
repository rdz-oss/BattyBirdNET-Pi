# Does `--local` Setup Services?

## ✅ **YES!**

When you run `./deploy --local`, the following happens:

### Complete Setup Process:

1. **✅ Stops services** (if running)
2. **✅ Syncs your local files** to Pi (rsync)
3. **✅ Checks/creates virtual environment** (if missing)
4. **✅ Installs Python dependencies** (`pip install -r requirements.txt`)
5. **✅ Reinstalls services** (calls `install_services.sh`)
6. **✅ Creates database** (if missing)
7. **✅ Sets up config** (if missing)
8. **✅ Restarts services**

---

## 🎯 Fresh Install vs Update

### Fresh Install (BattyBirdNET-Pi doesn't exist on Pi)
```bash
./deploy --local
```
**What happens:**
- ⚠️ Warning that it's a fresh install
- Creates virtual environment
- Installs all dependencies
- **Installs all services**
- Creates database
- Sets up default config
- Starts services

### Update (BattyBirdNET-Pi already exists)
```bash
./deploy --local
```
**What happens:**
- Backs up current installation
- Syncs your local files
- Updates Python dependencies
- **Reinstalls services** (in case of changes)
- Restarts services

---

## 🔧 Services That Get Installed/Reinstalled

- `birdnet_server.service`
- `birdnet_analysis.service`
- `batnet_server.service`
- `batnet_timer.service`
- `birdnet_recording.service`
- `birdnet_livestream.service`
- `caddy.service` (web server)

---

## 📋 What Gets Preserved

✅ **Configuration** (`/etc/birdnet/birdnet.conf`)  
✅ **Database** (`birds.db`)  
✅ **User lists** (`Include.txt`, `Exclude.txt`)  
✅ **Virtual environment** (reused if exists)  

---

## 🚀 Example Usage

### Deploy Local Changes with Full Service Setup
```bash
# Make changes locally
# Edit scripts/server.py...

# Deploy to Pi (services will be reinstalled)
./deploy --local

# Check services
./deploy --status
```

### Deploy Without Reinstalling Services
If you only want to sync files without touching services:

```bash
# Not directly supported, but you can:
# 1. Deploy locally
./deploy --local --no-restart

# 2. Manually restart if needed
ssh pi@birdnetpi.local "sudo systemctl restart birdnet_server"
```

---

## 🆚 Comparison: `--local` vs `--install`

| Feature | `--local` | `--install` |
|---------|-----------|-------------|
| **Source** | Your local directory | GitHub branch |
| **Virtual env** | Reuses or creates | Fresh create |
| **Dependencies** | Updates | Fresh install |
| **Services** | **Reinstalls** ✅ | **Installs** ✅ |
| **Database** | Preserves | Creates new |
| **Config** | Preserves | Creates from defaults |
| **Backup** | ✅ Yes | ✅ Yes |
| **Use case** | Testing local changes | Fresh setup |

---

## ⚠️ Important Notes

### Services Are Reinstalled, Not Just Restarted
```bash
./deploy --local
```
This calls `install_services.sh`, which:
- Recreates systemd service files
- Updates symlinks
- Enables services
- Then restarts them

**Why?** In case you changed service definitions or scripts.

### If Services Fail to Start
Check logs:
```bash
ssh pi@birdnetpi.local "journalctl -u birdnet_server -n 50"
```

Common issues:
- Missing dependencies → Fixed automatically
- Port conflicts → Check with `netstat -tlnp`
- Config errors → Check `/etc/birdnet/birdnet.conf`

---

## 🎯 Summary

**Yes, `--local` does setup services!**

```bash
./deploy --local
```

✅ Stops services  
✅ Syncs files  
✅ Updates dependencies  
✅ **Reinstalls services**  
✅ Creates DB/config if missing  
✅ Restarts services  

**For fresh installations:**
```bash
./deploy --install --local
```

This is the most thorough option for first-time setup from local code.

---

**See Also:**
- `DEPLOYMENT_GUIDE.md` - Full deployment documentation
- `DEPLOYMENT_MODES.md` - Different deployment modes
- `CHEAT_SHEET.md` - Quick reference