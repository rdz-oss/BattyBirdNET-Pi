# BattyBirdNET-Pi Conductor Context

## 1. Environment Baseline
- **OS**: Raspberry Pi OS Trixie (Debian 13)
- **Python**: 3.13 (no pre-compiled wheels for `numpy`/`tflite` → requires `python3-dev` + `build-essential`)
- **PHP**: 8.4 (FPM socket: `/run/php/php8.4-fpm.sock`)
- **Web Server**: Caddy 2 (strict symlink traversal, requires `CAP_NET_BIND_SERVICE` for port 80)
- **Systemd**: v255+ (strict ordering; `WantedBy=multi-user.target` is NOT enough → requires explicit `After=multi-user.target`)

## 2. Installation & Package Management
- **Silent `apt` Failures**: `install_services.sh` historically lacked `set -e`. Broken repos (e.g., Cloudsmith Caddy) caused `apt update` to fail, silently skipping `ffmpeg`, `icecast2`, `sox`, `lsof`, `bc`.
- **Fix**: Always use `set -e` in install scripts. Remove dead repos before `apt update`.
- **Python Env**: Create venv *after* installing `python3-dev` and `build-essential`. Use `tensorflow` instead of `tflite_runtime`. Pin `joblib>=1.0.0`.

## 3. Systemd & Service Orchestration
- **Boot Ordering**: All custom units need `After=multi-user.target`. Explicit `Requires=` for inter-service deps (e.g., `birdnet_analysis` → `birdnet_server` + `batnet_server`; `livestream` → `icecast2`).
- **Race Conditions**: Python servers take 10-30s to load models. `Type=simple` starts immediately. Fix: add wait loops for ports (`5050` for birdnet, `7667` for batnet) in startup scripts.
- **Environment**: Systemd runs with minimal `PATH`. Services calling external binaries (`ffmpeg`, `sox`) need `Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`.
- **Capabilities**: Caddy needs `AmbientCapabilities=CAP_NET_BIND_SERVICE` to bind port 80 without root.

## 4. Web Stack (Caddy / PHP / SQLite)
- **Symlink Traversal**: Caddy 2 blocks symlinks by default. Parent dirs (`BirdNET-Pi`, `BirdSongs`) must have `o+rX` permissions.
- **Web UI Sudo**: `www-data` needs passwordless sudo for `systemctl` to restart services from the UI. Add to `/etc/sudoers.d/www-data-systemctl`.
- **PHP-FPM Socket**: Caddyfile must use `php_fastcgi unix//run/php/php8.4-fpm.sock` for Trixie.
- **SQLite Busy**: `SQLite3::prepare()` can fail if DB is locked. PHP must `exit;` immediately after printing "Database is busy" to prevent fatal `execute()` on `False`.

## 5. Streamlit & Data Handling
- **Empty Database**: `df2.index.min()` returns `NaT` when empty → crashes Streamlit. Guard: `if df2.empty: st.info("No detections yet..."); st.stop()`.
- **Pandas Scalar Extraction**: `hourly[hourly.index == specie]['All']` returns a Series. `int()` fails. Use `hourly.loc[specie, 'All']` for scalars.

## 6. Update & Migration Path
- **`update_birdnet_snippets.sh`**: The migration path for existing systems. Always patch this file so `git pull` applies fixes to live Pi systems without reinstalling.
- **`newinstaller.sh`**: Handles fresh installs. Should auto-setup passwordless sudo for the current user.

## 7. Git & Branching Workflow
- **Base**: Always branch from `upstream/main`.
- **Naming**: `fix/<short-description>`
- **PR Flow**: Push to `origin/<branch>` → Create PR to `main` → Merge → Update local `main`.
- **Rebase**: Use `git rebase upstream/main` to resolve conflicts before pushing.