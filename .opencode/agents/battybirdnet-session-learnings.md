# BattyBirdNET-Pi Session Learnings & Best Practices

## 1. Trixie / Python 3.13 Compatibility
- **Requirements.txt**: Remove strict version pins (`==`) and `tflite-runtime`. Use `tensorflow` instead. Add `joblib>=1.0.0` to avoid deprecation warnings.
- **Build Dependencies**: `numpy` fails to compile on Python 3.13 without `python3-dev` and `build-essential`. Install them before creating the venv.
- **Deprecated Commands**: `netstat` is removed in Trixie. Replace all occurrences with `ss -tulpn`.
- **Missing Packages**: `icecast2`, `ffmpeg`, `sox`, `lsof`, `bc` may be missing if `apt update` fails earlier. Ensure `apt install` succeeds by removing broken repos (e.g., Cloudsmith Caddy repo).
- **PHP Version**: Trixie uses PHP 8.4. Ensure `php8.4-fpm` and `php-sqlite3` are installed. Socket path is `/run/php/php8.4-fpm.sock`.

## 2. Systemd & Service Management
- **Boot Ordering**: All custom services need `After=multi-user.target` to start reliably after reboot.
- **Dependencies**: Explicitly define `After=` and `Requires=` for inter-service dependencies (e.g., `birdnet_analysis` needs `birdnet_server` and `batnet_server`; `livestream` needs `icecast2`).
- **Environment**: Systemd services run with a minimal `PATH`. Add `Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` to units that call external binaries like `ffmpeg`.
- **Installer Robustness**: Add `set -e` to `install_services.sh` to fail fast on `apt` errors instead of silently skipping packages.

## 3. Web UI & Caddy Configuration
- **Port 80 Binding**: Caddy user needs `AmbientCapabilities=CAP_NET_BIND_SERVICE` in the systemd unit to bind to port 80.
- **Symlinks & Permissions**: Caddy 2 blocks symlinks by default. Ensure parent directories (`BirdNET-Pi`, `BirdSongs`) have `o+rX` permissions so Caddy can traverse them.
- **Web UI Sudo**: `www-data` needs passwordless sudo for `systemctl` to allow service restarts from the web UI. Add to `/etc/sudoers.d/www-data-systemctl`.
- **PHP-FPM Socket**: Update Caddyfile to use `php_fastcgi unix//run/php/php8.4-fpm.sock` for Trixie.

## 4. Streamlit & Data Handling
- **Empty Database**: `plotly_streamlit.py` crashes with `NaT` errors if the database is empty. Add a guard: `if df2.empty: st.info("No detections yet..."); st.stop()`.
- **Pandas Series vs Scalar**: `hourly[hourly.index == specie]['All']` returns a Series. Use `hourly.loc[specie, 'All']` to get a scalar for `int()`.
- **Database Busy Errors**: PHP files (`overview.php`, etc.) crash if `SQLite3::prepare()` fails. Always add `exit;` after printing "Database is busy".

## 5. Update & Migration Strategy
- **Update Snippets**: `scripts/update_birdnet_snippets.sh` is the migration path for existing systems. Always add new fixes here so `git pull` updates live systems correctly.
- **New Installer**: `newinstaller.sh` should auto-setup passwordless sudo for the current user to reduce manual pre-configuration.

## 6. Workflow & Branching
- **Fix Branches**: Always create fix branches on top of `upstream/main`. Rebase if conflicts arise.
- **PR Strategy**: Push to `origin/<branch>`, create PR to `main`. Merge to `main` to sync local and remote.
- **Testing**: Verify fixes on a clean Trixie install. Check systemd logs (`journalctl -u <service>`) and service status after reboot.