# Installation Methods Comparison

## Regular Production Installation (newinstaller.sh)

### How It Works:

#### 1. **Fresh Install** (`newinstaller.sh`)
```bash
#!/usr/bin/env bash
# Steps:
1. Check if running as root (must NOT be root)
2. Check architecture (must be aarch64)
3. Install missing dependencies (git, jq)
4. Clone BattyBirdNET-Pi (dev branch) → ~/BirdNET-Pi
5. Clone BattyBirdNET-Analyzer (main branch) → ~/BattyBirdNET-Analyzer
6. Run install_birdnet.sh
```

#### 2. **Install Process** (`install_birdnet.sh`)
```bash
# Path: ~/BirdNET-Pi/scripts/install_birdnet.sh

Steps:
1. Set directories (my_dir=$HOME/BirdNET-Pi)
2. Run install_config.sh → Creates /etc/birdnet/birdnet.conf
3. Run install_services.sh → Creates systemd services
4. Source config file
5. Create Python venv (~/BirdNET-Pi/birdnet/)
6. Install requirements.txt
7. Run install_language_label_nm.sh
8. Reboot
```

#### 3. **Service Installation** (`install_services.sh`)
```bash
# Creates systemd service files in ~/BirdNET-Pi/templates/
- birdnet_server.service
- birdnet_analysis.service  
- batnet_server.service
- batnet_timer_server.service
- birdnet_recording.service
- extraction.service
- etc.

# Links to /usr/lib/systemd/system/
# Enables with systemctl enable

# Also:
- Installs system packages (Caddy, PHP, sox, ffmpeg, etc.)
- Sets hostname to "birdnetpi"
- Creates necessary directories
- Generates BirdDB.txt
- Sets up auto-login
```

#### 4. **Update Process** (`update_birdnet.sh`)
```bash
# Path: ~/BirdNET-Pi/scripts/update_birdnet.sh

Usage: ./update_birdnet.sh [-r remote] [-b branch]

Steps:
1. Source /etc/birdnet/birdnet.conf
2. Get current HEAD commit hash
3. git reset --hard (remove local changes)
4. git fetch origin branch
5. git switch -C branch --track origin/branch
6. Show diff stats
7. Repeat for BattyBirdNET-Analyzer
8. systemctl daemon-reload
9. Link scripts to /usr/local/bin/
10. Run update_birdnet_snippets.sh (handles migrations)
```

#### 5. **Uninstall Process** (`uninstall.sh`)
```bash
# Path: ~/BirdNET-Pi/scripts/uninstall.sh

Steps:
1. Source config
2. Parse install_services.sh to find service names
3. For each service:
   - systemctl disable --now
   - Remove from /lib/systemd/system/
   - Remove from /etc/systemd/system/
4. Remove crontab entries
5. Stop icecast2
6. Remove symlinks from /usr/local/bin/
7. Remove /etc/birdnet/
8. Remove ~/BirdNET-Pi/birdnet.conf
9. User must manually remove directory
```

---

## Our Deploy Script (`tests/hardware/deploy_to_pi.py`)

### Current Implementation:

#### 1. **Deploy Modes**
```bash
./deploy --install          # Fresh install from git
./deploy --install --local  # Fresh install from local code
./deploy --update           # Update from git
./deploy --local            # Deploy local changes
./deploy --reinstall        # Uninstall + Install
./deploy --uninstall        # Remove everything
```

#### 2. **Install Method** (lines 317-428)
```python
# Current issues:
- Uses hardcoded paths (BirdNET-Pi vs BattyBirdNET-Pi)
- Doesn't clone Analyzer properly
- Service installation incomplete
- Config path issues
```

#### 3. **Deploy from Local** (lines 483-643)
```python
# What it does:
- rsync/scp files to Pi
- Creates venv if missing
- Installs requirements.txt
- Runs install_services.sh (BROKEN - hardcoded paths)

# What's missing:
- Doesn't handle Analyzer
- Doesn't configure Caddy
- Doesn't set up web interface
```

#### 4. **Update Method** (lines 430-481)
```python
# Similar to update_birdnet.sh but:
- Can update from local OR git branch
- Backs up current installation
- Restarts services after
```

#### 5. **Uninstall Method** (lines 287-315)
```python
# Stops services
# Removes directories
# Doesn't fully clean systemd services
```

---

## Key Differences

### Regular Install:
✅ **Pros:**
- Battle-tested, production-ready
- Handles all edge cases
- Complete web interface setup
- Proper service management
- Migration handling (update_birdnet_snippets.sh)
- Auto-login configuration
- Hostname setup

❌ **Cons:**
- Only works from git (not local code)
- No password authentication (needs SSH keys or manual)
- Requires reboot
- All-or-nothing approach

### Our Deploy Script:
✅ **Pros:**
- Can deploy from local code (for testing)
- Password authentication support
- Remote deployment via SSH
- Good for development/testing
- Selective deployment possible

❌ **Cons:**
- Incomplete service installation
- Hardcoded paths (BirdNET-Pi vs BattyBirdNET-Pi)
- Doesn't clone Analyzer properly
- Web interface not configured
- No migration handling
- Not production-ready

---

## What We Need to Fix

### To Match Production Installation:

#### 1. **Fix Paths**
```python
# Current (WRONG):
my_dir = $HOME/BirdNET-Pi

# Should be:
my_dir = $HOME/BattyBirdNET-Pi  # or configurable
```

#### 2. **Clone Analyzer Properly**
```python
# Our script tries but fails
# Need to:
git clone https://github.com/rdz-oss/BattyBirdNET-Analyzer.git ~/BattyBirdNET-Analyzer
cd ~/BattyBirdNET-Analyzer
python3 -m venv birdnet_analyzer
source birdnet_analyzer/bin/activate
pip install -r requirements.txt
```

#### 3. **Fix Service Installation**
```bash
# Must run install_services.sh with correct paths
# Or replicate its functionality:
- Create service files in templates/
- Link to /usr/lib/systemd/system/
- Enable with systemctl
- Install system packages
```

#### 4. **Configure Web Interface**
```bash
# Missing from our script:
- Caddy configuration
- PHP-FPM setup
- Site configuration
- Database migration
```

#### 5. **Handle Migrations**
```bash
# Production runs update_birdnet_snippets.sh
# This handles:
- Config file changes
- Database schema updates
- Service file updates
- Language files
```

---

## Recommended Approach

### For Development/Testing:
Use our `./deploy --local` with fixes:
1. Fix hardcoded paths
2. Add Analyzer cloning
3. Fix service installation
4. Skip web interface (not needed for testing)

### For Production:
Use regular `newinstaller.sh`:
1. Clone repo
2. Run installer
3. Reboot
4. Done

### For Hybrid (Best of Both):
Modify our deploy script to:
1. ✅ Deploy refactored code from local
2. ✅ Use production service installation scripts
3. ✅ Clone Analyzer properly
4. ✅ Run production migrations
5. ✅ Keep password authentication

---

## Implementation Plan

### Phase 1: Fix Basic Deployment (DONE - Partially)
- ✅ Password authentication
- ✅ File sync (rsync/scp)
- ✅ Basic service creation
- ❌ Analyzer integration
- ❌ Web interface

### Phase 2: Match Production Features
- [ ] Fix all hardcoded paths
- [ ] Proper Analyzer cloning/setup
- [ ] Run install_services.sh correctly
- [ ] Configure Caddy
- [ ] Database migrations

### Phase 3: Add Development Features
- [ ] Deploy from local OR git
- [ ] Selective component deployment
- [ ] Quick testing mode (no web UI)
- [ ] Full production mode

---

## Current Status

**Regular Install:** ✅ 100% Production Ready  
**Our Deploy Script:** ⚠️  60% Complete (Core works, missing features)

**What Works Now:**
- ✅ Deploy refactored code
- ✅ Install basic services
- ✅ Server module running
- ✅ Hardware detection

**What's Missing:**
- ❌ Analyzer integration
- ❌ Web interface
- ❌ Full service suite
- ❌ Migration handling
