# Deployment Modes Explained

The deployment tool supports **3 different deployment modes** for BattyBirdNET-Pi and BattyBirdNET-Analyzer.

---

## 🎯 Deployment Modes

### Mode 1: **GitHub Branch Deployment** (Default)
Clones both repositories from GitHub.

**What gets installed:**
- **BattyBirdNET-Pi:** From specified branch (default: `dev`)
- **BattyBirdNET-Analyzer:** From specified branch (default: `main`)

**Commands:**
```bash
# Default: Pi from dev, Analyzer from main
./deploy

# Specify both branches
./deploy --branch dev --analyzer-branch main

# Both from dev branch
./deploy --branch dev --analyzer-branch dev
```

**Use case:** Testing production or specific branches from GitHub.

---

### Mode 2: **Local Development Deployment** (`--local` or `--deploy`)
Syncs your local BattyBirdNET-Pi code to Pi, Analyzer from GitHub.

**What gets installed:**
- **BattyBirdNET-Pi:** From your **local development directory** (rsync)
- **BattyBirdNET-Analyzer:** From specified branch (default: `main`)

**Commands:**
```bash
# Deploy local Pi code, Analyzer from main
./deploy --local

# Deploy local Pi code, Analyzer from dev
./deploy --local --analyzer-branch dev

# Same as --local
./deploy --deploy
```

**Use case:** Testing your local code changes on Pi hardware.

**What gets synced:**
- ✅ All your local Python scripts
- ✅ Shell scripts
- ✅ PHP files
- ✅ Templates
- ✅ Configuration files

**What gets excluded:**
- ❌ `.git/` directory
- ❌ `venv/`, `birdnet/` (virtual environments)
- ❌ `*.db` (databases)
- ❌ `__pycache__/`, `*.pyc`
- ❌ Test artifacts

---

### Mode 3: **Mixed Deployment**
Update Pi from one branch, Analyzer from another.

**Commands:**
```bash
# Pi from feature branch, Analyzer from main
./deploy --install --branch feature/audio-fix --analyzer-branch main

# Update Pi to dev, Analyzer to dev
./deploy --update --branch dev --analyzer-branch dev
```

---

## 📊 Quick Reference

| Mode | BattyBirdNET-Pi Source | BattyBirdNET-Analyzer Source | Command |
|------|------------------------|------------------------------|---------|
| **GitHub (default)** | GitHub `dev` branch | GitHub `main` branch | `./deploy` |
| **GitHub (custom)** | GitHub `<branch>` | GitHub `<branch>` | `./deploy --branch <branch> --analyzer-branch <branch>` |
| **Local dev** | Your local directory | GitHub `main` branch | `./deploy --local` |
| **Local + custom** | Your local directory | GitHub `<branch>` | `./deploy --local --analyzer-branch <branch>` |

---

## 🎓 Common Scenarios

### Scenario 1: Test Your Local Changes
You're developing a feature and want to test it on Pi hardware.

```bash
# Make changes locally
cd ~/dev/BattyBirdNET-Pi
git checkout feature/my-feature
# Edit files...

# Deploy to Pi
./deploy --local

# Run hardware tests
pytest tests/hardware/ -v
```

**Result:** Your local code is on the Pi, Analyzer from main branch.

---

### Scenario 2: Test Latest Dev Branch
You want to test the latest code from the dev branch.

```bash
# Update Pi to latest dev
./deploy --update --branch dev

# Check status
./deploy --status
```

**Result:** Both Pi and Analyzer updated from GitHub dev branch.

---

### Scenario 3: Test Feature Branch with Stable Analyzer
Testing a Pi feature branch but want stable Analyzer.

```bash
./deploy --install --branch feature/audio-improvements --analyzer-branch main
```

**Result:** Pi from feature branch, Analyzer from stable main.

---

### Scenario 4: Test Both from Dev
Testing latest development versions of both.

```bash
./deploy --install --branch dev --analyzer-branch dev
```

**Result:** Both from dev branch.

---

### Scenario 5: Quick Local Test
Quick test of local changes without git commits.

```bash
# Edit files locally
# Then deploy
./deploy --deploy

# Or equivalently
./deploy --local
```

**Result:** Your local files synced to Pi immediately.

---

## 🔄 Update vs Install vs Deploy

### `--install` (Fresh Install)
- Removes existing installation
- Clones/syncs fresh copy
- Creates database
- Installs services
- **Use:** First-time setup or complete reinstall

### `--update` (Git Pull)
- Preserves existing installation
- Pulls latest from GitHub
- Updates dependencies
- **Use:** Keep current installation up-to-date

### `--deploy` or `--local` (Sync Local)
- Syncs your local directory to Pi
- Uses rsync for efficiency
- **Use:** Testing local development changes

---

## 🎯 Default Behavior

If you run `./deploy` with no arguments:

```bash
./deploy
```

**What happens:**
- **BattyBirdNET-Pi:** Updated from `dev` branch (GitHub)
- **BattyBirdNET-Analyzer:** NOT updated (stays on current branch)
- **Services:** Restarted automatically

**To update both:**
```bash
./deploy --update --branch dev --analyzer-branch dev
```

---

## 🔧 Advanced Options

### No Backup
Skip backup (faster, but risky):
```bash
./deploy --update --no-backup
```

### No Service Restart
Update code but don't restart services:
```bash
./deploy --update --no-restart
```

### Verbose Output
See detailed SSH/SCP commands:
```bash
./deploy -v
```

---

## 📝 Configuration

Edit `tests/hardware/pi_config.json` to specify:
- Pi hostname/IP
- SSH credentials
- Installation paths

```json
{
  "hostname": "birdnetpi.local",
  "username": "pi",
  "key_file": "~/.ssh/id_rsa",
  "port": 22,
  "install_path": "/home/pi/BattyBirdNET-Pi",
  "config_path": "/etc/birdnet/birdnet.conf"
}
```

---

## 🎯 Summary

**For local development:**
```bash
./deploy --local
```

**For testing branches:**
```bash
./deploy --branch <branch-name> --analyzer-branch <branch-name>
```

**For default update:**
```bash
./deploy
```

**Questions?**
- See `DEPLOYMENT_GUIDE.md` for full documentation
- Run `./deploy --help` for all options
- Check `QUICK_START.md` for setup checklist