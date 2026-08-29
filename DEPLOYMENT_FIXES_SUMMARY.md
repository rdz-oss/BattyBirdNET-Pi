# Deployment Fixes Summary

## Problem
The `deploy_to_pi.py --install --local` script was failing with multiple permission errors and path issues.

## Root Causes
1. `install_services.sh` was not running as root, causing permission denied errors
2. Hardcoded paths (`BirdNET-Pi` vs `BattyBirdNET-Pi`, `/root/BirdSongs` vs `/home/bat/BirdSongs`)
3. Virtual environment ownership issues (root vs bat user)
4. Missing config file setup (LATITUDE/LONGITUDE, species lists)
5. Service files with wrong paths and User settings
6. Missing symlinks to `/usr/local/bin/`

## Files Modified

### 1. `scripts/install_services.sh`
- Added auto-sudo re-exec at script start (runs as root if not already)
- Fixed `config_icecast()` to use `sudo` on all sed commands
- Fixed `createdb.sh` call to include proper environment variables
- Fixed all hardcoded paths (`BirdNET-Pi` → `BattyBirdNET-Pi`)

### 2. `scripts/install_on_pi.sh`
- Added path fixing for `birdnet.conf-defaults`
- Added automatic LATITUDE/LONGITUDE configuration (default: Frankfurt, Germany)
- Added creation of species list files (include/exclude)
- Added file ownership fix (`chown -R bat:bat`)
- Added service file path and User fixes
- Added symlink path fixes in `/usr/local/bin/*.sh`
- Enhanced service startup with `reset-failed` before `start`
- Added comprehensive status output at end

### 3. `tests/hardware/deploy_to_pi.py`
- Fixed database verification logic (check first, create if missing)
- Fixed virtual environment path in database creation
- Added species list file creation
- Added file ownership fix after installation
- Changed Caddy config to verify-first approach (only fix if needed)
- Moved `fix_caddy_config()` method inside `BattyBirdNETDeploy` class

## Deployment Process Now

1. ✅ Sync files from local to Pi
2. ✅ Create virtual environment (as user bat)
3. ✅ Install Python dependencies
4. ✅ Run `install_on_pi.sh` which:
   - Fixes all paths in scripts
   - Creates config with default location
   - Creates species list files
   - Runs service installation as root
   - Fixes file ownership
   - Configures Caddy
   - Fixes service files
   - Starts all services
5. ✅ Verify database
6. ✅ Setup Analyzer
7. ✅ Verify web interface

## Expected Results

After successful deployment:
- ✅ Web interface accessible at `http://<pi-ip>/`
- ✅ `birdnet_server` - active (running)
- ✅ `birdnet_analysis` - active (periodic execution)
- ✅ `birdnet_recording` - active (running)
- ✅ `caddy` - active (running)
- ✅ Config file at `/etc/birdnet/birdnet.conf` with LATITUDE/LONGITUDE set
- ✅ Species list files in `/home/bat/`
- ✅ Database at `~/BattyBirdNET-Pi/scripts/birds.db`

## Known Issues

- `birdnet_analysis` shows "activating" state - this is normal, it's a periodic service that runs, completes, and restarts
- `birdnet_recording` may fail if no audio hardware is present (expected on test systems)

## Testing

```bash
cd /Users/batfish/dev/bat/BattyBirdNET-Pi
python3 tests/hardware/deploy_to_pi.py --install --local
```

Then verify:
```bash
curl http://192.168.178.166/
ssh bat@192.168.178.166 "sudo systemctl status birdnet_server birdnet_analysis birdnet_recording"
```
