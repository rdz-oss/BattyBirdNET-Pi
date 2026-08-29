# Clean Install Options

From **most thorough** to **least thorough**:

---

## 🔥 Option 1: Complete Nuke (Cleanest)

```bash
./deploy --uninstall
./deploy --install
```

**What it does:**
- ✅ Removes ALL BattyBirdNET-Pi files
- ✅ Removes ALL BattyBirdNET-Analyzer files
- ✅ Removes ALL services
- ✅ Removes virtual environment
- ✅ Removes database
- ✅ Removes configuration (`/etc/birdnet/`)
- ✅ Fresh clone from GitHub
- ✅ Fresh service installation
- ✅ Fresh database creation

**Use when:**
- Starting completely fresh
- Troubleshooting major issues
- Preparing for production deployment
- Want absolutely clean state

**Time:** ~10-15 minutes

---

## ⚡ Option 2: Reinstall (Quick Clean)

```bash
./deploy --reinstall
```

**What it does:**
- ✅ Removes BattyBirdNET-Pi directory
- ✅ Removes BattyBirdNET-Analyzer directory
- ✅ Removes virtual environment
- ✅ Removes services
- ⚠️ **Preserves configuration** (`/etc/birdnet/birdnet.conf`)
- ⚠️ **Preserves database** (if in scripts/)
- ✅ Fresh clone from GitHub
- ✅ Fresh service installation

**Use when:**
- Testing different branches
- Want clean code but keep config
- Quick reset for development

**Time:** ~8-12 minutes

---

## 🔄 Option 3: Fresh Install (Preserves Some)

```bash
./deploy --install --no-backup
```

**What it does:**
- ✅ Removes old BattyBirdNET-Pi directory
- ✅ Removes old BattyBirdNET-Analyzer directory
- ⚠️ **Preserves configuration**
- ⚠️ **May preserve database**
- ✅ Fresh clone from GitHub
- ✅ Fresh service installation

**Use when:**
- Regular deployment
- Want to keep user settings
- Don't need to nuke everything

**Time:** ~8-12 minutes

---

## 🧹 Option 4: Clean via SSH (Manual)

```bash
# SSH into Pi
ssh pi@birdnetpi.local

# Stop services
sudo systemctl stop birdnet_server birdnet_analysis batnet_server birdnet_recording

# Remove installation
rm -rf ~/BattyBirdNET-Pi
rm -rf ~/BattyBirdNET-Analyzer
rm -rf ~/birdnet

# Remove services
sudo rm -f /etc/systemd/system/birdnet*.service
sudo rm -f /lib/systemd/system/birdnet*.service
sudo systemctl daemon-reload

# Remove config (optional)
sudo rm -rf /etc/birdnet

# Remove database
rm -f ~/BattyBirdNET-Pi/scripts/birds.db

# Come back and install
./deploy --install
```

**Use when:**
- Deployment tool isn't working
- Need fine-grained control
- Manual troubleshooting

**Time:** ~15-20 minutes

---

## 🎯 Comparison Table

| Option | Removes Code | Removes Services | Removes Config | Removes DB | Removes venv | Best For |
|--------|-------------|------------------|----------------|------------|--------------|----------|
| `--uninstall` + `--install` | ✅ | ✅ | ✅ | ✅ | ✅ | Complete fresh start |
| `--reinstall` | ✅ | ✅ | ⚠️ No | ⚠️ No | ✅ | Quick clean reset |
| `--install --no-backup` | ✅ | ✅ | ⚠️ No | ⚠️ No | ✅ | Regular deployment |
| Manual SSH | ✅ | ✅ | Optional | Optional | ✅ | Manual control |

---

## 🚀 Recommended Workflows

### Development (Daily Use)
```bash
# Test local changes
./deploy --local

# Want clean state?
./deploy --reinstall
```

### Testing Different Branches
```bash
# Switch branches cleanly
./deploy --reinstall --branch feature/my-branch
```

### Production Deployment
```bash
# Complete fresh install
./deploy --uninstall
./deploy --install --branch main --analyzer-branch main
```

### Troubleshooting
```bash
# Nuclear option
./deploy --uninstall

# Verify removal
./deploy --status  # Should fail to connect to BattyBirdNET-Pi

# Fresh install
./deploy --install --branch dev
```

---

## ⚠️ What Each Removes

### `--uninstall`
```bash
# Removes:
~/BattyBirdNET-Pi/          # All code
~/BattyBirdNET-Analyzer/    # All analyzer code
~/birdnet/                  # Virtual environment
/etc/birdnet/               # Configuration
/etc/systemd/system/birdnet*.service
/lib/systemd/system/birdnet*.service
```

### `--reinstall`
```bash
# Removes:
~/BattyBirdNET-Pi/          # All code
~/BattyBirdNET-Analyzer/    # All analyzer code
~/birdnet/                  # Virtual environment
/etc/systemd/system/birdnet*.service

# Preserves:
/etc/birdnet/birdnet.conf   # Configuration
~/BattyBirdNET-Pi/scripts/birds.db  # Database (if exists)
```

---

## 🎯 Quick Reference

```bash
# Cleanest possible
./deploy --uninstall && ./deploy --install

# Quick clean
./deploy --reinstall

# Clean install from local
./deploy --reinstall --local

# Clean install from branch
./deploy --reinstall --branch feature/my-branch

# Install without backup (faster)
./deploy --install --no-backup
```

---

## ⏱️ Time Estimates

| Option | Time |
|--------|------|
| `--uninstall` + `--install` | 10-15 min |
| `--reinstall` | 8-12 min |
| `--install --no-backup` | 8-12 min |
| Manual SSH | 15-20 min |
| `--local` (no clean) | 2-5 min |

---

## 💡 Pro Tips

1. **Use `--reinstall` for development** - Good balance of clean vs fast
2. **Use `--uninstall` for production** - Ensures completely clean state
3. **Use `--no-backup` to save time** - Skip backup if you don't need it
4. **Use `--local` for quick tests** - Fastest, preserves everything

---

## 🆚 `--reinstall` vs `--uninstall` + `--install`

### `--reinstall`
```bash
./deploy --reinstall
```
- Faster (skips config removal)
- Keeps your settings
- Keeps database
- **Best for:** Development, testing

### `--uninstall` + `--install`
```bash
./deploy --uninstall
./deploy --install
```
- Slower (removes everything)
- Fresh config
- Fresh database
- **Best for:** Production, troubleshooting

---

**See Also:**
- `DEPLOYMENT_GUIDE.md` - Full deployment documentation
- `CHEAT_SHEET.md` - Quick reference
- `SERVICES_SETUP.md` - Service installation details
