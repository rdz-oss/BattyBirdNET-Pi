"""
Remote deployment tool for BattyBirdNET-Pi.

Deploys development versions to Raspberry Pi via SSH/SCP.

Usage:
    # Deploy current branch to Pi
    python3 deploy_to_pi.py
    
    # Deploy specific branch
    python3 deploy_to_pi.py --branch feature/my-branch
    
    # Uninstall from Pi
    python3 deploy_to_pi.py --uninstall
    
    # Reinstall (uninstall + install)
    python3 deploy_to_pi.py --reinstall
    
    # Deploy without restarting services
    python3 deploy_to_pi.py --no-restart
    
    # Verbose output
    python3 deploy_to_pi.py -v
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from datetime import datetime


class BattyBirdNETDeploy:
    """Deploy BattyBirdNET-Pi to Raspberry Pi via SSH/SCP."""
    
    def __init__(self, config_path: str = None, verbose: bool = False):
        self.verbose = verbose
        self.config = self._load_config(config_path)
        self.ssh_cmd = self._build_ssh_cmd()
        self.scp_cmd = self._build_scp_cmd()
    
    def _load_config(self, config_path: str = None) -> dict:
        """Load Pi configuration."""
        if config_path is None:
            config_path = Path(__file__).parent / "pi_config.json"
        
        if not config_path.exists():
            raise FileNotFoundError(
                f"Config file not found: {config_path}\n"
                "Please configure tests/hardware/pi_config.json first"
            )
        
        with open(config_path) as f:
            config = json.load(f)
        
        # Override with environment variables
        if os.environ.get("BATTY_PI_HOST"):
            config["hostname"] = os.environ["BATTY_PI_HOST"]
        if os.environ.get("BATTY_PI_USER"):
            config["username"] = os.environ["BATTY_PI_USER"]
        if os.environ.get("BATTY_PI_KEY_FILE"):
            config["key_file"] = os.environ["BATTY_PI_KEY_FILE"]
        
        return config
    
    def _build_ssh_cmd(self, use_sshpass: bool = False) -> str:
        """Build SSH command."""
        password = self.config.get("password")
        port = self.config.get("port", 22)
        user = self.config.get("username", "pi")
        host = self.config.get("hostname", "birdnetpi.local")
        
        # Use sshpass if password is provided or requested
        if use_sshpass or (password and not self.config.get("key_file")):
            if password:
                return f"sshpass -p '{password}' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p {port} {user}@{host}"
            else:
                # sshpass will prompt for password
                return f"sshpass ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p {port} {user}@{host}"
        
        # Use SSH key if available
        key_file = self.config.get("key_file", "~/.ssh/id_rsa")
        key_file = os.path.expanduser(key_file)
        
        if os.path.exists(key_file):
            return f"ssh -i {key_file} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p {port} {user}@{host}"
        else:
            return f"ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p {port} {user}@{host}"
    
    def _build_scp_cmd(self, use_sshpass: bool = False) -> str:
        """Build SCP command."""
        password = self.config.get("password")
        port = self.config.get("port", 22)
        user = self.config.get("username", "pi")
        host = self.config.get("hostname", "birdnetpi.local")
        
        # Use sshpass if password is provided or requested
        if use_sshpass or (password and not self.config.get("key_file")):
            if password:
                return f"sshpass -p '{password}' scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -P {port}"
            else:
                return f"sshpass scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -P {port}"
        
        # Use SSH key if available
        key_file = self.config.get("key_file", "~/.ssh/id_rsa")
        key_file = os.path.expanduser(key_file)
        
        if os.path.exists(key_file):
            return f"scp -i {key_file} -o StrictHostKeyChecking=no -o ConnectTimeout=10 -P {port}"
        else:
            return f"scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 -P {port}"
    
    def _run_ssh(self, command: str, capture: bool = False) -> tuple:
        """Execute command on Pi via SSH."""
        full_cmd = f"{self.ssh_cmd} '{command}'"
        
        if self.verbose:
            print(f"SSH: {full_cmd}")
        
        try:
            if capture:
                result = subprocess.run(
                    full_cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                return result.returncode, result.stdout, result.stderr
            else:
                result = subprocess.run(full_cmd, shell=True, timeout=60)
                return result.returncode, "", ""
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as e:
            return -1, "", str(e)
    
    def _run_sudo(self, command: str, capture: bool = False) -> tuple:
        """Execute sudo command on Pi with password."""
        password = self.config.get('password')
        if password:
            # Use echo to pipe password to sudo
            full_cmd = f"{self.ssh_cmd} 'echo \"{password}\" | sudo -S {command}'"
        else:
            full_cmd = f"{self.ssh_cmd} 'sudo {command}'"
        
        if self.verbose:
            print(f"SUDO: {command}")
        
        try:
            if capture:
                result = subprocess.run(
                    full_cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                return result.returncode, result.stdout, result.stderr
            else:
                result = subprocess.run(full_cmd, shell=True, timeout=60)
                return result.returncode, "", ""
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as e:
            return -1, "", str(e)
    
    def _run_scp(self, source: str, dest: str, recursive: bool = False) -> int:
        """Copy files to Pi via SCP."""
        recursive_flag = "-r" if recursive else ""
        full_cmd = f"{self.scp_cmd} {recursive_flag} {source} {self.config['username']}@{self.config['hostname']}:{dest}"
        
        if self.verbose:
            print(f"SCP: {full_cmd}")
        
        result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"SCP error: {result.stderr}")
        
        return result.returncode
    
    def test_connection(self) -> bool:
        """Test SSH connection to Pi."""
        print("Testing SSH connection...")
        code, stdout, stderr = self._run_ssh("hostname", capture=True)
        
        if code == 0:
            print(f"✓ Connected to {stdout.strip()}")
            return True
        else:
            print(f"✗ Connection failed: {stderr}")
            return False
    
    def get_current_version(self) -> str:
        """Get current version on Pi."""
        code, stdout, stderr = self._run_ssh(
            "cat ~/BattyBirdNET-Pi/version.md 2>/dev/null | head -5",
            capture=True
        )
        
        if code == 0 and stdout.strip():
            return stdout.strip()
        return "Unknown"
    
    def stop_services(self) -> bool:
        """Stop BattyBirdNET-Pi services on Pi."""
        print("Stopping services...")
        
        services = [
            "birdnet_analysis",
            "birdnet_server",
            "batnet_server",
            "batnet_timer",
            "birdnet_recording",
            "birdnet_livestream",
        ]
        
        for service in services:
            self._run_sudo(f"sudo systemctl stop {service} 2>/dev/null || true")
        
        # Give services time to stop
        time.sleep(2)
        
        print("✓ Services stopped")
        return True
    
    def start_services(self) -> bool:
        """Start BattyBirdNET-Pi services on Pi."""
        print("Starting services...")
        
        services = [
            "birdnet_server",
            "birdnet_analysis",
            "batnet_server",
            "batnet_timer",
            "birdnet_recording",
            "birdnet_livestream",
        ]
        
        for service in services:
            self._run_sudo(f"sudo systemctl start {service} 2>/dev/null || true")
        
        time.sleep(3)
        print("✓ Services started")
        return True
    
    def backup_current_install(self, backup_path: str = None) -> str:
        """Backup current installation."""
        if backup_path is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = f"/tmp/battypird_backup_{timestamp}"
        
        print(f"Creating backup at {backup_path}...")
        
        # Create backup directory
        self._run_ssh(f"mkdir -p {backup_path}")
        
        # Backup config
        self._run_ssh(f"cp -r /etc/birdnet {backup_path}/ 2>/dev/null || true")
        
        # Backup database
        self._run_ssh(
            "cp ~/BattyBirdNET-Pi/scripts/birds.db "
            f"{backup_path}/birds.db 2>/dev/null || true"
        )
        
        # Backup user configs
        self._run_ssh(
            "cp ~/BattyBirdNET-Pi/Include.txt "
            f"{backup_path}/Include.txt 2>/dev/null || true"
        )
        self._run_ssh(
            "cp ~/BattyBirdNET-Pi/Exclude.txt "
            f"{backup_path}/Exclude.txt 2>/dev/null || true"
        )
        
        print(f"✓ Backup created: {backup_path}")
        return backup_path
    
    def uninstall(self) -> bool:
        """Uninstall BattyBirdNET-Pi from Pi."""
        print("\n=== Uninstalling BattyBirdNET-Pi ===\n")
        
        # Stop services
        self.stop_services()
        
        # Run uninstall script if it exists
        code, _, _ = self._run_ssh(
            "test -f ~/BattyBirdNET-Pi/scripts/uninstall.sh && echo 'exists'",
            capture=True
        )
        
        if code == 0:
            print("Running uninstall script...")
            self._run_ssh("bash ~/BattyBirdNET-Pi/scripts/uninstall.sh")
            time.sleep(2)
        
        # Remove installation directory
        print("Removing installation directory...")
        self._run_ssh("rm -rf ~/BattyBirdNET-Pi")
        self._run_ssh("rm -rf ~/BattyBirdNET-Analyzer")
        
        # Remove config (optional - comment out to preserve)
        # print("Removing configuration...")
        # self._run_ssh("sudo rm -rf /etc/birdnet")
        
        # Remove virtual environment
        self._run_ssh("rm -rf ~/birdnet")
        
        print("✓ Uninstall complete")
        return True
    

    def clone_analyzer(self, branch: str = "main") -> bool:
        """Clone and setup BattyBirdNET-Analyzer."""
        print("\nCloning BattyBirdNET-Analyzer...")
        
        # Remove old if exists
        self._run_ssh("rm -rf ~/BattyBirdNET-Analyzer")
        
        # Clone
        code, out, err = self._run_ssh(
            f"git clone --depth=1 -b {branch} "
            "https://github.com/rdz-oss/BattyBirdNET-Analyzer.git ~/BattyBirdNET-Analyzer",
            capture=True
        )
        
        if code != 0:
            print(f"✗ Analyzer clone failed: {err}")
            return False
        
        print("✓ Analyzer cloned")
        
        # Setup virtual environment
        print("Setting up Analyzer environment...")
        self._run_ssh("cd ~/BattyBirdNET-Analyzer && python3 -m venv birdnet_analyzer")
        self._run_ssh("cd ~/BattyBirdNET-Analyzer && source birdnet_analyzer/bin/activate && pip install --upgrade pip")
        self._run_ssh("cd ~/BattyBirdNET-Analyzer && source birdnet_analyzer/bin/activate && pip install -r requirements.txt")
        
        print("✓ Analyzer setup complete")
        return True

    def install(self, branch: str = "dev", analyzer_branch: str = "main", 
            backup: bool = True, local: bool = False) -> bool:
        """Install BattyBirdNET-Pi on Pi.
        
        Args:
            branch: Git branch for BattyBirdNET-Pi (default: dev)
            analyzer_branch: Git branch for BattyBirdNET-Analyzer (default: main)
            backup: Whether to backup current installation
            local: If True, deploy from local directory instead of git clone
        """
        print(f"\n=== Installing BattyBirdNET-Pi ===")
        if local:
            print(f"Source: Local directory")
        else:
            print(f"BattyBirdNET-Pi branch: {branch}")
        print(f"BattyBirdNET-Analyzer branch: {analyzer_branch}")
        print()
        
        # Backup current installation
        if backup:
            self.backup_current_install()
        
        # Stop services
        self.stop_services()
        
        # Remove old installation
        print("Removing old installation...")
        self._run_ssh("rm -rf ~/BattyBirdNET-Pi")
        self._run_ssh("rm -rf ~/BattyBirdNET-Analyzer")
        
        if local:
            # Deploy from local directory
            print("Deploying BattyBirdNET-Pi from local directory...")
            if not self.deploy_from_local():
                return False
        else:
            # Clone BattyBirdNET-Pi from GitHub
            print(f"Cloning BattyBirdNET-Pi (branch: {branch})...")
            code, _, stderr = self._run_ssh(
                f"git clone -b {branch} --depth=1 "
                "https://github.com/rdz-oss/BattyBirdNET-Pi.git ~/BattyBirdNET-Pi"
            )
            
            if code != 0:
                print(f"✗ Clone failed: {stderr}")
                return False
            
            print("✓ BattyBirdNET-Pi cloned")
        
        # Clone BattyBirdNET-Analyzer
        print(f"Cloning BattyBirdNET-Analyzer (branch: {analyzer_branch})...")
        code, _, stderr = self._run_ssh(
            f"git clone -b {analyzer_branch} --depth=1 "
            "https://github.com/rdz-oss/BattyBirdNET-Analyzer.git ~/BattyBirdNET-Analyzer"
        )
        
        if code != 0:
            print(f"✗ Analyzer clone failed: {stderr}")
            # Continue anyway - analyzer might not be critical
            print("⚠ Continuing without Analyzer...")
        else:
            print("✓ BattyBirdNET-Analyzer cloned")
        
        # Install dependencies
        print("Installing system dependencies...")
        self._run_sudo(
            "apt update && apt install -y "
            "git python3-pip python3-venv sqlite3 ffmpeg sox"
        )
        
        # Create virtual environment
        print("Creating virtual environment...")
        self._run_ssh(
            "cd ~/BattyBirdNET-Pi && "
            "python3 -m venv birdnet && "
            "source birdnet/bin/activate && "
            "pip install --upgrade pip"
        )
        
        # Install Python dependencies
        print("Installing Python dependencies...")
        self._run_ssh(
            "cd ~/BattyBirdNET-Pi && "
            "source birdnet/bin/activate && "
            "pip install -r requirements.txt"
        )
        
        # Run complete installation script
        print("Running installation script...")
        code, out, err = self._run_ssh(
            "cd ~/BattyBirdNET-Pi && "
            "bash scripts/install_on_pi.sh",
            capture=True
        )
        if code != 0:
            print(f"Installation script warning: {err}")
        else:
            print("✓ Installation script completed")
        
        # Configuration and services handled by install_on_pi.sh
        print("Configuration handled by installation script...")
        
        # Fix ownership of virtual environment (ensure pip can install)
        print("Fixing file ownership...")
        self._run_ssh("sudo chown -R bat:bat ~/BattyBirdNET-Pi/birdnet ~/BattyBirdNET-Analyzer/birdnet_analyzer 2>/dev/null || true")
        
        # Create species list files if missing
        self._run_ssh("touch ~/BattyBirdNET-Pi/include_species_list.txt ~/BattyBirdNET-Pi/exclude_species_list.txt 2>/dev/null || true")
        
        # Verify database
        print("Verifying database...")
        code, out, err = self._run_ssh(
            "test -f ~/BattyBirdNET-Pi/scripts/birds.db && echo 'exists' || echo 'missing'",
            capture=True
        )
        if code != 0 or out.strip() == 'missing':
            print("⚠ Database not found, attempting to create...")
            self._run_ssh(
                "cd ~/BattyBirdNET-Pi/scripts && "
                "source ~/BattyBirdNET-Pi/birdnet/bin/activate && "
                "bash createdb.sh"
            )
        
        # Clone and setup Analyzer
        print("\nSetting up BattyBirdNET-Analyzer...")
        self.clone_analyzer(branch=analyzer_branch)
        
        # Caddy config handled by install_on_pi.sh, just verify
        print("Verifying Caddy configuration...")
        code, out, _ = self._run_ssh("curl -s http://localhost/ | grep -o '<title>.*</title>'", capture=True)
        if "BattyBirdNET-Pi" in out:
            print("✓ Web interface working")
        else:
            print("⚠ Web interface may need manual configuration")
            self.fix_caddy_config()
        
        print("✓ Installation complete")
        return True
    
    def update(self, branch: str = "dev", analyzer_branch: str = None,
           restart: bool = True, local: bool = False) -> bool:
        """Update BattyBirdNET-Pi on Pi.
        
        Args:
            branch: Git branch for BattyBirdNET-Pi (default: dev)
            analyzer_branch: Git branch for Analyzer (optional, updates if specified)
            restart: Whether to restart services after update
            local: If True, deploy from local directory instead of git
        """
        print(f"\n=== Updating BattyBirdNET-Pi ===")
        if local:
            print(f"Source: Local directory")
        else:
            print(f"BattyBirdNET-Pi branch: {branch}")
        if analyzer_branch:
            print(f"BattyBirdNET-Analyzer branch: {analyzer_branch}")
        print()
        
        # Backup current installation
        self.backup_current_install()
        
        # Stop services
        self.stop_services()
        
        if local:
            # Deploy from local
            self.deploy_from_local()
        else:
            # Pull latest changes for BattyBirdNET-Pi
            print("Pulling latest changes...")
            code, stdout, stderr = self._run_ssh(
                f"cd ~/BattyBirdNET-Pi && "
                f"git fetch origin {branch} && "
                f"git reset --hard origin/{branch}"
            )
            
            if code != 0:
                print(f"✗ Git pull failed: {stderr}")
                return False
            
            print("✓ BattyBirdNET-Pi updated")
        
        # Update Analyzer if branch specified
        if analyzer_branch:
            print(f"Updating Analyzer to {analyzer_branch}...")
            code, _, stderr = self._run_ssh(
                f"cd ~/BattyBirdNET-Analyzer && "
                f"git fetch origin {analyzer_branch} && "
                f"git reset --hard origin/{analyzer_branch}"
            )
            if code == 0:
                print(f"✓ Analyzer updated to {analyzer_branch}")
            else:
                print(f"⚠ Analyzer update failed: {stderr}")
        
        # Check for new dependencies
        print("Checking dependencies...")
        self._run_ssh(
            "cd ~/BattyBirdNET-Pi && "
            "source birdnet/bin/activate && "
            "pip install -r requirements.txt --upgrade"
        )
        
        # Reinstall services (in case of changes)
        print("Reinstalling services...")
        self._run_ssh(
            "cd ~/BattyBirdNET-Pi && "
            "source birdnet/bin/activate && "
            "bash scripts/install_services.sh"
        )
        
        # Restart services
        if restart:
            self.start_services()
        
        # Get new version
        version = self.get_current_version()
        print(f"\n✓ Update complete")
        print(f"Current version:\n{version}")
        
        return True
    
    def deploy_from_local(self, source_dir: str = None, install_services: bool = True) -> bool:
        """Deploy from local development directory.
        
        Args:
            source_dir: Local directory to deploy from (default: project root)
            install_services: Whether to reinstall services (default: True)
        """
        if source_dir is None:
            # Get project root (parent of tests directory)
            source_dir = Path(__file__).parent.parent.parent
        
        source_dir = Path(source_dir).resolve()
        
        if not source_dir.exists():
            print(f"✗ Source directory not found: {source_dir}")
            return False
        
        print(f"\n=== Deploying from {source_dir} ===\n")
        
        # Check if BattyBirdNET-Pi exists on Pi
        code, _, _ = self._run_ssh("test -d ~/BattyBirdNET-Pi && echo 'exists'", capture=True)
        is_fresh_install = (code != 0)
        
        if is_fresh_install:
            print("⚠ BattyBirdNET-Pi not found on Pi - performing fresh install")
            print("  Use --install instead for full setup")
            # Stop services (if any)
            self.stop_services()
        else:
            # Stop services
            self.stop_services()
            
            # Backup
            self.backup_current_install()
        
        # Sync files
        print("Syncing files to Pi...")
        dest = f"{self.config['username']}@{self.config['hostname']}:~/BattyBirdNET-Pi"
        
        # Use rsync if available, otherwise scp
        # Build rsync SSH command with password support
        password = self.config.get('password')
        if password:
            rsync_ssh = f"sshpass -p '{password}' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10"
        else:
            rsync_ssh = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10"
        
        rsync_cmd = (
            f"rsync -avz --delete "
            f"-e '{rsync_ssh}' "
            f"--exclude '.git' "
            f"--exclude 'venv' "
            f"--exclude 'birdnet' "
            f"--exclude '*.db' "
            f"--exclude '__pycache__' "
            f"--exclude '*.pyc' "
            f"--exclude '.pytest_cache' "
            f"--exclude 'reports' "
            f"{source_dir}/ {dest}"
        )
        
        result = subprocess.run(rsync_cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Rsync failed, trying scp: {result.stderr}")
            # Fallback to scp
            self._run_scp(f"{source_dir}/*", "~/BattyBirdNET-Pi/", recursive=True)
        
        print("✓ Files synced")
        
        # Check if virtual environment exists
        code, _, _ = self._run_ssh("test -d ~/birdnet && echo 'exists'", capture=True)
        if code != 0:
            print("Creating virtual environment...")
            self._run_ssh(
                "cd ~/BattyBirdNET-Pi && "
                "python3 -m venv birdnet && "
                "source birdnet/bin/activate && "
                "pip install --upgrade pip"
            )
        
        # Install dependencies
        print("Installing Python dependencies...")
        self._run_ssh(
            "cd ~/BattyBirdNET-Pi && "
            "source birdnet/bin/activate && "
            "pip install -r requirements.txt"
        )
        
        # Install/reinstall services if requested
        if install_services:
            if is_fresh_install:
                print("Installing services (fresh install)...")
            else:
                print("Reinstalling services...")
            
            self._run_ssh(
                "cd ~/BattyBirdNET-Pi && "
                "source birdnet/bin/activate && "
                "bash scripts/install_services.sh"
            )
            
            # Create database if it doesn't exist
            code, _, _ = self._run_ssh(
                "test -f ~/BattyBirdNET-Pi/scripts/birds.db && echo 'exists'",
                capture=True
            )
            if code != 0:
                print("Creating database...")
                self._run_ssh(
                    "cd ~/BattyBirdNET-Pi/scripts && "
                    "source ~/birdnet/bin/activate && "
                    "bash createdb.sh"
                )
            
            # Setup config if it doesn't exist
            code, _, _ = self._run_ssh(
                "test -f /etc/birdnet/birdnet.conf && echo 'exists'",
                capture=True
            )
            if code != 0:
                print("Setting up configuration...")
                self._run_sudo(
                    "mkdir -p /etc/birdnet && "
                    "cp ~/BattyBirdNET-Pi/birdnet.conf-defaults /etc/birdnet/birdnet.conf"
                )
        
        # Restart services
        self.start_services()
        
        print("✓ Deployment complete")
        return True
    
    def status(self) -> bool:
        """Show status of BattyBirdNET-Pi on Pi."""
        print("\n=== BattyBirdNET-Pi Status ===\n")
        
        # Connection
        if not self.test_connection():
            return False
        
        # Version
        version = self.get_current_version()
        print(f"\nVersion:\n{version}")
        
        # Services
        print("\nServices:")
        services = [
            "birdnet_server",
            "birdnet_analysis",
            "batnet_server",
            "batnet_timer",
            "birdnet_recording",
            "birdnet_livestream",
        ]
        
        for service in services:
            code, stdout, _ = self._run_ssh(
                f"systemctl is-active {service}",
                capture=True
            )
            status = "✓" if stdout.strip() == "active" else "✗"
            print(f"  {status} {service}: {stdout.strip()}")
        
        # Disk usage
        code, stdout, _ = self._run_ssh(
            "df -h / | tail -1 | awk '{print $3, $4}'",
            capture=True
        )
        if code == 0:
            used, avail = stdout.strip().split()
            print(f"\nDisk: Used {used}, Available {avail}")
        
        # Database size
        code, stdout, _ = self._run_ssh(
            "ls -lh ~/BattyBirdNET-Pi/scripts/birds.db 2>/dev/null | awk '{print $5}'",
            capture=True
        )
        if code == 0 and stdout.strip():
            print(f"Database size: {stdout.strip()}")
        
        # Recent detections
        code, stdout, _ = self._run_ssh(
            "sqlite3 ~/BattyBirdNET-Pi/scripts/birds.db "
            "'SELECT COUNT(*) FROM detections WHERE date(Date) >= date(\"now\", \"-7 days\");'",
            capture=True
        )
        if code == 0:
            print(f"Detections (7 days): {stdout.strip()}")
        
        print()
        return True
    
    def fix_caddy_config(self):
        """Fix Caddy configuration to serve web interface correctly."""
        print("Configuring Caddy web server...")
        
        caddyfile = """:80 {
    root * /home/bat/BattyBirdNET-Pi/homepage
    php_fastcgi unix//run/php/php8.4-fpm.sock
    file_server
    try_files {path} {path}/ /index.php
}
"""
        # Write Caddyfile using SSH
        self._run_sudo("tee /etc/caddy/Caddyfile > /dev/null << 'CEOF'\n:80 {\n    root * /home/bat/BattyBirdNET-Pi/homepage\n    php_fastcgi unix//run/php/php8.4-fpm.sock\n    file_server\n    try_files {path} {path}/ /index.php\n}\nCEOF")
        
        # Restart Caddy
        self._run_sudo("systemctl restart caddy")
        
        print("✓ Caddy configured")


def main():
    parser = argparse.ArgumentParser(
        description="Deploy BattyBirdNET-Pi to Raspberry Pi",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    
    parser.add_argument(
        "--config",
        type=str,
        default=None,
        help="Path to pi_config.json (default: tests/hardware/pi_config.json)"
    )
    
    parser.add_argument(
        "--branch",
        type=str,
        default="dev",
        help="Git branch to deploy for BattyBirdNET-Pi (default: dev)"
    )
    
    parser.add_argument(
        "--analyzer-branch",
        type=str,
        default="main",
        help="Git branch for BattyBirdNET-Analyzer (default: main)"
    )
    
    parser.add_argument(
        "--local",
        action="store_true",
        help="Deploy BattyBirdNET-Pi from local directory (rsync)"
    )
    
    parser.add_argument(
        "--install",
        action="store_true",
        help="Install BattyBirdNET-Pi"
    )
    
    parser.add_argument(
        "--update",
        action="store_true",
        help="Update BattyBirdNET-Pi (git pull)"
    )
    
    parser.add_argument(
        "--uninstall",
        action="store_true",
        help="Uninstall BattyBirdNET-Pi"
    )
    
    parser.add_argument(
        "--reinstall",
        action="store_true",
        help="Reinstall (uninstall + install)"
    )
    
    parser.add_argument(
        "--deploy",
        action="store_true",
        help="Deploy from local development directory"
    )
    
    parser.add_argument(
        "--status",
        action="store_true",
        help="Show status"
    )
    
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip backup during install/update"
    )
    
    parser.add_argument(
        "--no-restart",
        action="store_true",
        help="Don't restart services after update"
    )
    
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output"
    )
    
    args = parser.parse_args()
    
    try:
        deploy = BattyBirdNETDeploy(
            config_path=args.config,
            verbose=args.verbose
        )
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Test connection first
    if not deploy.test_connection():
        print("\nCannot connect to Pi. Please check:")
        print("  1. Pi is powered on and connected to network")
        print("  2. SSH is enabled on Pi")
        print("  3. tests/hardware/pi_config.json is configured correctly")
        sys.exit(1)
    
    # Execute requested action
    if args.reinstall:
        success = deploy.uninstall() and deploy.install(
            branch=args.branch,
            analyzer_branch=args.analyzer_branch,
            backup=not args.no_backup,
            local=args.local
        )
    elif args.uninstall:
        success = deploy.uninstall()
    elif args.install:
        success = deploy.install(
            branch=args.branch,
            analyzer_branch=args.analyzer_branch,
            backup=not args.no_backup,
            local=args.local
        )
    elif args.update:
        success = deploy.update(
            branch=args.branch,
            analyzer_branch=args.analyzer_branch if args.analyzer_branch != "main" else None,
            restart=not args.no_restart,
            local=args.local
        )
    elif args.deploy or args.local:
        success = deploy.deploy_from_local()
    elif args.status:
        success = deploy.status()
    else:
        # Default: update from dev branch
        success = deploy.update(
            branch=args.branch,
            restart=not args.no_restart
        )
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
    def complete_installation(self):
        """Complete the installation after code is deployed.
        
        This method:
        1. Clones BattyBirdNET-Analyzer
        2. Fixes hardcoded paths in scripts
        3. Creates missing config files
        4. Sets default location
        5. Creates database
        6. Installs all services including recording
        7. Starts all services
        """
        print("\n=== Completing Installation ===\n")
        
        # 1. Clone Analyzer if not exists
        code, _, _ = self._run_ssh("test -d ~/BattyBirdNET-Analyzer && echo 'exists'", capture=True)
        if code != 0:
            print("Cloning BattyBirdNET-Analyzer...")
            self.clone_analyzer()
        
        # 2. Fix hardcoded paths BEFORE running install_services
        print("Fixing hardcoded paths in all scripts...")
        # Fix paths in all shell scripts
        # Fix apt commands to use sudo
        self._run_ssh("cd ~/BattyBirdNET-Pi/scripts && sed -i 's|^\s*apt |sudo apt |g' install_services.sh && sed -i 's|ln -sf |sudo ln -sf |g' install_services.sh && sed -i 's|systemctl |sudo systemctl |g' install_services.sh")
        self._run_ssh("cd ~/BattyBirdNET-Pi/scripts && for f in *.sh; do sed -i 's|BirdNET-Pi|BattyBirdNET-Pi|g' \"\$f\" && sed -i 's|/root/BirdSongs|/home/bat/BirdSongs|g' \"\$f\"; done")
        self._run_ssh("cd ~/BattyBirdNET-Pi/scripts && for f in *.sh; do sed -i 's|BirdNET-Pi|BattyBirdNET-Pi|g' \"\$f\" && sed -i 's|/root/BirdSongs|/home/bat/BirdSongs|g' \"\$f\"; done")
        # Fix install_services.sh specifically
        self._run_ssh("sed -i 's|\$HOME/BirdNET-Pi|\$HOME/BattyBirdNET-Pi|g' ~/BattyBirdNET-Pi/scripts/install_services.sh")
        print("Fixing hardcoded paths in scripts...")
        self._run_ssh("cd ~/BattyBirdNET-Pi/scripts && sed -i 's|BirdNET-Pi|BattyBirdNET-Pi|g' *.sh")
        
        # 3. Create missing config files
        print("Creating config files...")
        self._run_ssh("cd ~/BattyBirdNET-Pi && touch include_species_list.txt exclude_species_list.txt scripts/lastrun.txt")
        self._run_ssh("cp ~/BattyBirdNET-Pi/scripts/thisrun.txt ~/BattyBirdNET-Pi/scripts/lastrun.txt")
        
        # 4. Set default location (Frankfurt as example)
        print("Setting default location...")
        self._run_sudo("sed -i 's/LATITUDE=0.0000/LATITUDE=50.1109/' /birdnet.conf")
        self._run_sudo("sed -i 's/LONGITUDE=0.0000/LONGITUDE=8.6821/' /birdnet.conf")
        
        # 5. Create recording directories
        print("Creating recording directories...")
        self._run_ssh("mkdir -p ~/BirdSongs/Processed ~/BirdSongs/Extracted && chmod -R 755 ~/BirdSongs")
        
        # 6. Fix recording directory path in config
        print("Configuring recording paths...")
        self._run_sudo("sed -i 's|RECS_DIR=/root/BirdSongs|RECS_DIR=/home/bat/BirdSongs|g' /birdnet.conf")
        self._run_sudo("sed -i 's|PROCESSED=/root|PROCESSED=/home/bat|g' /birdnet.conf")
        self._run_sudo("sed -i 's|EXTRACTED=/root|EXTRACTED=/home/bat|g' /birdnet.conf")
        
        # 7. Create database
        print("Creating database...")
        self._run_ssh("cd ~/BattyBirdNET-Pi/scripts && source ~/BattyBirdNET-Pi/birdnet/bin/activate && bash createdb.sh")
        
        # 8. Install recording service
        print("Installing recording service...")
        self._run_ssh("""
cat > ~/BattyBirdNET-Pi/templates/birdnet_recording.service << EOF
[Unit]
Description=BirdNET Recording
After=network.target

[Service]
Environment=XDG_RUNTIME_DIR=/run/user/1000
Restart=always
Type=simple
RestartSec=3
User=$USER
ExecStart=/usr/local/bin/birdnet_recording.sh

[Install]
WantedBy=multi-user.target
EOF
sudo cp ~/BattyBirdNET-Pi/templates/birdnet_recording.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable birdnet_recording.service
""")
        
        # 9. Start all services
        print("Starting all services...")
        self._run_sudo("systemctl start birdnet_server birdnet_analysis birdnet_recording")
        
        # 10. Verify
        print("\nVerifying installation...")
        code, out, _ = self._run_sudo("systemctl is-active birdnet_server birdnet_analysis birdnet_recording", capture=True)
        services = out.strip().split('\n')
        for i, service in enumerate(['birdnet_server', 'birdnet_analysis', 'birdnet_recording']):
            status = services[i] if i < len(services) else 'unknown'
            if status == 'active':
                print(f"  ✓ {service}: {status}")
            else:
                print(f"  ⚠ {service}: {status}")
        
        # Check for recordings
        code, out, _ = self._run_ssh("ls ~/BirdSongs/*/*/*.wav 2>/dev/null | head -1", capture=True)

    def fix_caddy_config(self):
        """Fix Caddy configuration to serve web interface correctly."""
        print("Configuring Caddy web server...")
        
        caddyfile = """:80 {
    root * /home/bat/BattyBirdNET-Pi/homepage
    php_fastcgi unix//run/php/php8.4-fpm.sock
    file_server
    try_files {path} {path}/ /index.php
}
"""
        # Write Caddyfile using SSH
        self._run_sudo("tee /etc/caddy/Caddyfile > /dev/null << 'CEOF'\n:80 {\n    root * /home/bat/BattyBirdNET-Pi/homepage\n    php_fastcgi unix//run/php/php8.4-fpm.sock\n    file_server\n    try_files {path} {path}/ /index.php\n}\nCEOF")
        
        # Restart Caddy
        self._run_sudo("systemctl restart caddy")
        
        print("✓ Caddy configured")

if __name__ == "__main__":
    main()
