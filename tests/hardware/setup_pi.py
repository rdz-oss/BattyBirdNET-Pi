"""
Setup script to prepare Pi for hardware testing.

Run this on your Mac to prepare the Pi for testing:
    python3 tests/hardware/setup_pi.py

Or run the commands manually via SSH.
"""

import subprocess
import sys
from pathlib import Path


def run_ssh_command(hostname: str, username: str, command: str):
    """Run a command on Pi via SSH."""
    ssh_cmd = f"ssh {username}@{hostname} '{command}'"
    print(f"Running: {ssh_cmd}")
    
    result = subprocess.run(
        ssh_cmd,
        shell=True,
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print(f"✓ {command[:50]}")
        return True
    else:
        print(f"✗ {command[:50]}")
        if result.stderr:
            print(f"  Error: {result.stderr.strip()}")
        return False


def main():
    """Main setup routine."""
    import json
    
    config_file = Path(__file__).parent / "pi_config.json"
    
    if not config_file.exists():
        print("Error: pi_config.json not found")
        print("Please create and configure it first.")
        sys.exit(1)
    
    with open(config_file) as f:
        config = json.load(f)
    
    hostname = config.get("hostname", "birdnetpi.local")
    username = config.get("username", "pi")
    
    print(f"\n{'='*60}")
    print(f"Setting up BattyBirdNET-Pi testing on {hostname}")
    print(f"{'='*60}\n")
    
    commands = [
        ("Update package list", "sudo apt update"),
        ("Install GPIO libraries", "sudo apt install -y python3-rpi.gpio python3-gpiozero"),
        ("Install SQLite tools", "sudo apt install -y sqlite3"),
        ("Install curl for testing", "sudo apt install -y curl"),
        ("Add user to audio group", "sudo usermod -a -G audio $USER"),
        ("Check Python version", "python3 --version"),
        ("Check pip packages", "python3 -c 'import numpy; print(\"numpy OK\")'"),
    ]
    
    success_count = 0
    for name, command in commands:
        print(f"\n[{name}]")
        if run_ssh_command(hostname, username, command):
            success_count += 1
    
    print(f"\n{'='*60}")
    print(f"Setup complete: {success_count}/{len(commands)} commands succeeded")
    print(f"{'='*60}\n")
    
    print("Next steps:")
    print("1. Reboot Pi if GPIO libraries were installed:")
    print(f"   ssh {username}@{hostname} 'sudo reboot'")
    print("\n2. Run hardware tests:")
    print("   pytest tests/hardware/ -v")
    print("\n3. Run specific test categories:")
    print("   pytest tests/hardware/test_system.py -v")
    print("   pytest tests/hardware/test_services.py -v")
    print("   pytest tests/hardware/test_audio.py -v")
    print("   pytest tests/hardware/test_gpio.py -v")
    print("   pytest tests/hardware/test_integration.py -v")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nSetup interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nSetup failed: {e}")
        sys.exit(1)