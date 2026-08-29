# Installer password‑less sudo note

**Title**
Add password‑less sudo rule for seamless BattyBirdNET‑Pi installation

**Description / Summary**

The installer (`newinstaller.sh`) is designed to be run as a normal user, but it invokes a large number of privileged commands (apt, systemctl, usermod, chown, etc.) via `sudo`. On a fresh Raspberry Pi OS these commands prompt for a password, causing the script to abort with the message “password is required / aborting”.

To enable a fully automated install we add a dedicated sudoers snippet that grants the installing user unrestricted password‑less sudo rights. This covers every `sudo` invocation inside the installer (including the final `sudo reboot`) without requiring the user to modify the script or enter a password.

**Changes**

1. **Created sudoers file**
   - Path: `/etc/sudoers.d/batnet-installer` (added via `visudo -f`).
   - Content (replace `{{USERNAME}}` with the actual non‑root username, e.g. `pi`):

   ```text
   {{USERNAME}} ALL=(ALL) NOPASSWD: ALL
   ```

   This rule allows the user to run any command via `sudo` without a password, which is sufficient for the installer’s needs.

2. **Documentation** (added to `README.md` or a new `INSTALLATION.md` section)

   ```markdown
   ## Automated installation on Raspberry Pi OS

   The installer (`newinstaller.sh`) expects to be run as a normal user, but it calls many privileged commands internally.
   To run the installer without being prompted for a sudo password, create a sudoers rule for the installing user:

   ```bash
   sudo visudo -f /etc/sudoers.d/batnet-installer
   ```

   Add the following line (replace `pi` with your username):

   ```text
   pi ALL=(ALL) NOPASSWD: ALL
   ```

   Save and exit. Then run the installer:

   ```bash
   cd /path/to/BattyBirdNET-Pi
   bash newinstaller.sh
   ```

   The script will now complete without interactive password prompts and will reboot automatically at the end.
   ```

3. **Optional cleanup note** (in the PR description)
   - After a successful installation you may tighten the sudo rule by replacing `ALL` with the explicit command list used by the installer, if stricter security is desired.

**Testing performed**

- Added the sudoers file on a fresh Raspberry Pi OS installation.
- Ran `bash newinstaller.sh` as the `pi` user (no `sudo` prefix).
- All `sudo` calls succeeded without prompting for a password.
- The script completed, enabled all required systemd services, and performed the final `sudo reboot`.
- After reboot, `systemctl status` for the installed services shows them active.

**Impact**

- Removes a common failure point for new users.
- No changes to the original installer logic; the fix is external and reversible.
- Aligns with the project's goal of a “one‑click” setup for Raspberry Pi.

**Related Issue**

(Reference any open issue, e.g., `#42`.)
