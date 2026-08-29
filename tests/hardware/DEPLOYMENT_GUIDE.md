# Deployment Guide

Deploy, update, and uninstall BattyBirdNET-Pi on Raspberry Pi from your development machine.

## Quick Start

### Deploy Current Development Version
```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi

# Update Pi with latest from 'dev' branch
python3 tests/hardware/deploy_to_pi.py
```

### Deploy Specific Branch
```bash
# Deploy feature branch
python3 tests/hardware/deploy_to_pi.py --branch feature/my-branch

# Deploy main branch
python3 tests/hardware/deploy_to_pi.py --branch main
```

## Commands

### Status Check
```bash
# Check Pi status
python3 tests/hardware/deploy_to_pi.py --status
```

Output example:
```
=== BattyBirdNET-Pi Status ===

Testing SSH connection...
✓ Connected to birdnetpi

Version:
# BattyBirdNET-Pi Version 2.4.1
Build: 2024-08-04

Services:
  ✓ birdnet_server: active
  ✓ birdnet_analysis: active
  ✗ batnet_server: inactive
  ✓ birdnet_recording: active

Disk: Used 4.2G, Available 25G
Database size: 12M
Detections (7 days): 147
```

### Install (Fresh Install)
```bash
# Fresh install (backs up existing if present)
python3 tests/hardware/deploy_to_pi.py --install

# Fresh install without backup
python3 tests/hardware/deploy_to_pi.py --install --no-backup

# Install specific branch
python3 tests/hardware/deploy_to_pi.py --install --branch dev
```

### Update (Git Pull)
```bash
# Update from current branch
python3 tests/hardware/deploy_to_pi.py --update

# Update from specific branch
python3 tests/hardware/deploy_to_pi.py --update --branch feature/test-branch

# Update without restarting services
python3 tests/hardware/deploy_to_pi.py --update --no-restart
```

### Uninstall
```bash
# Complete uninstall
python3 tests/hardware/deploy_to_pi.py --uninstall

# This removes:
# - All BattyBirdNET-Pi files
# - All services
# - Virtual environment
# - Configuration (optional)
```

### Reinstall
```bash
# Complete reinstall (uninstall + install)
python3 tests/hardware/deploy_to_pi.py --reinstall

# Reinstall specific branch
python3 tests/hardware/deploy_to_pi.py --reinstall --branch dev
```

### Deploy from Local Development
```bash
# Deploy your current local changes
python3 tests/hardware/deploy_to_pi.py --deploy

# This syncs your local files to Pi (excluding .git, venv, etc.)
```

## Configuration

Edit `tests/hardware/pi_config.json`:

```json
{
  "hostname": "192.168.1.100",
  "username": "pi",
  "key_file": "~/.ssh/id_rsa",
  "port": 22,
  "install_path": "/home/pi/BattyBirdNET-Pi",
  "config_path": "/etc/birdnet/birdnet.conf"
}
```

Or use environment variables:
```bash
export BATTY_PI_HOST=192.168.1.100
export BATTY_PI_USER=pi
export BATTY_PI_KEY_FILE=~/.ssh/id_rsa

python3 tests/hardware/deploy_to_pi.py --status
```

## Command Line Options

```
usage: deploy_to_pi.py [-h] [--config CONFIG] [--branch BRANCH] [--install]
                       [--update] [--uninstall] [--reinstall] [--deploy]
                       [--status] [--no-backup] [--no-restart] [-v]

Deploy BattyBirdNET-Pi to Raspberry Pi

optional arguments:
  -h, --help         show this help message and exit
  --config CONFIG    Path to pi_config.json
  --branch BRANCH    Git branch to deploy (default: dev)
  --install          Install BattyBirdNET-Pi
  --update           Update BattyBirdNET-Pi (git pull)
  --uninstall        Uninstall BattyBirdNET-Pi
  --reinstall        Reinstall (uninstall + install)
  --deploy           Deploy from local development directory
  --status           Show status
  --no-backup        Skip backup during install/update
  --no-restart       Don't restart services after update
  -v, --verbose      Verbose output
```

## Use Cases

### Development Workflow

1. **Make changes locally:**
   ```bash
   git checkout feature/my-feature
   # Edit files...
   git commit -m "Fix bug"
   ```

2. **Deploy to Pi for testing:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --deploy
   ```

3. **Run tests on Pi:**
   ```bash
   pytest tests/hardware/ -v
   ```

4. **Check status:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --status
   ```

5. **Update from branch:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --update --branch feature/my-feature
   ```

### Production Deployment

1. **Check current status:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --status
   ```

2. **Update to latest dev:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --update --branch dev
   ```

3. **Verify services:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --status
   ```

### Troubleshooting

1. **Service not starting:**
   ```bash
   # Check status
   python3 tests/hardware/deploy_to_pi.py --status
   
   # SSH in manually
   ssh pi@birdnetpi.local
   
   # Check logs
   journalctl -u birdnet_server -n 50
   ```

2. **Reinstall if needed:**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --reinstall
   ```

3. **Rollback to previous version:**
   ```bash
   # Restore from backup
   ssh pi@birdnetpi.local
   cd ~/BattyBirdNET-Pi
   git log --oneline -5  # Find commit to restore
   git reset --hard <commit-hash>
   python3 tests/hardware/deploy_to_pi.py --update --no-backup
   ```

## What Gets Deployed

### Files Synced
- ✅ All Python scripts
- ✅ Shell scripts
- ✅ PHP files
- ✅ Templates
- ✅ Configuration defaults
- ✅ Tests

### Files Excluded
- ❌ `.git/` directory
- ❌ `venv/` or `birdnet/` (virtual environment)
- ❌ `*.db` (databases)
- ❌ `__pycache__/`
- ❌ `*.pyc` (bytecode)
- ❌ `.pytest_cache/`
- ❌ `reports/`

### Backup Locations

Backups are created at:
```
/tmp/battyird_backup_YYYYMMDD_HHMMSS/
├── birdnet/           # /etc/birdnet config
├── birds.db           # Database
├── Include.txt        # User include list
└── Exclude.txt        # User exclude list
```

To restore from backup:
```bash
ssh pi@birdnetpi.local
sudo cp /tmp/battyird_backup_*/birdnet/* /etc/birdnet/
sudo cp /tmp/battyird_backup_*/birds.db ~/BattyBirdNET-Pi/scripts/
```

## Behind the Scenes

### Install Process
1. Stop all services
2. Backup existing installation
3. Clone repository from GitHub
4. Create Python virtual environment
5. Install dependencies
6. Install systemd services
7. Create database
8. Start services

### Update Process
1. Stop all services
2. Backup existing installation
3. Git fetch and reset to target branch
4. Update Python dependencies
5. Reinstall services (if changed)
6. Start services

### Uninstall Process
1. Stop all services
2. Run uninstall script
3. Remove installation directories
4. Remove virtual environment
5. (Optionally) preserve config

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Deploy to Test Pi

on:
  push:
    branches: [dev, feature/*]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.PI_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
      
      - name: Deploy to Pi
        run: |
          pip install paramiko scp
          python3 tests/hardware/deploy_to_pi.py --deploy
        env:
          BATTY_PI_HOST: ${{ secrets.PI_HOST }}
          BATTY_PI_USER: pi
      
      - name: Run Hardware Tests
        run: |
          pytest tests/hardware/ -v --tb=short
```

## Troubleshooting

### "Connection refused"
```bash
# Check Pi is on network
ping birdnetpi.local

# Check SSH
ssh pi@birdnetpi.local

# Update pi_config.json with correct IP
```

### "Permission denied"
```bash
# Copy SSH key
ssh-copy-id pi@birdnetpi.local

# Or use password authentication
# (edit pi_config.json to use password instead of key_file)
```

### "Service failed to start"
```bash
# SSH in and check logs
ssh pi@birdnetpi.local
journalctl -u birdnet_server -n 100 --no-pager

# Check if port is in use
sudo netstat -tlnp | grep 8080

# Restart manually
sudo systemctl restart birdnet_server
```

### "Git pull failed"
```bash
# SSH in and check git status
ssh pi@birdnetpi.local
cd ~/BattyBirdNET-Pi
git status
git log --oneline -5

# Force reset if needed
git fetch origin dev
git reset --hard origin/dev
```

## Best Practices

1. **Always test on dev branch first**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --update --branch dev
   ```

2. **Create backups before major changes**
   ```bash
   python3 tests/hardware/deploy_to_pi.py --status
   # Backup is automatic, but verify
   ssh pi@birdnetpi.local "ls -lh /tmp/battyird_backup_*"
   ```

3. **Run hardware tests after deploy**
   ```bash
   pytest tests/hardware/ -v
   ```

4. **Monitor services after update**
   ```bash
   watch -n 2 'python3 tests/hardware/deploy_to_pi.py --status'
   ```

5. **Use --no-restart for debugging**
   ```bash
   # Update code but don't restart
   python3 tests/hardware/deploy_to_pi.py --update --no-restart
   
   # SSH in and test manually
   ssh pi@birdnetpi.local
   cd ~/BattyBirdNET-Pi
   python3 scripts/server.py  # Run manually to see errors
   ```

## Next Steps

After deployment:
1. Run hardware tests: `pytest tests/hardware/ -v`
2. Check web interface: `http://birdnetpi.local`
3. Monitor logs: `journalctl -f -u birdnet_server`
4. Test detection workflow manually

## Questions?

- See `README.md` for hardware test setup
- See `QUICK_START.md` for quick reference
- Check `pi_config.json` for connection settings
- Run `python3 tests/hardware/deploy_to_pi.py --help` for usage