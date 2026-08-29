"""
System-level tests for Raspberry Pi hardware.

Tests CPU, memory, disk, temperature, and network connectivity.
"""

import pytest


class TestSystemInfo:
    """Test system information retrieval."""
    
    def test_hostname_resolves(self, ssh_exec):
        """Verify we can connect and get hostname."""
        stdout, stderr, code = ssh_exec("hostname")
        assert code == 0, f"hostname command failed: {stderr}"
        assert len(stdout) > 0, "Hostname should not be empty"
    
    def test_os_version(self, ssh_exec):
        """Verify Raspberry Pi OS version."""
        stdout, stderr, code = ssh_exec("cat /etc/os-release")
        assert code == 0
        assert "Raspberry" in stdout or "Debian" in stdout
    
    def test_architecture(self, ssh_exec):
        """Verify ARM architecture."""
        stdout, stderr, code = ssh_exec("uname -m")
        assert code == 0
        assert "arm" in stdout.lower() or "aarch64" in stdout.lower()
    
    def test_python_version(self, ssh_exec):
        """Verify Python 3 is available."""
        stdout, stderr, code = ssh_exec("python3 --version")
        assert code == 0
        assert "Python 3" in stdout


class TestCPU:
    """Test CPU monitoring."""
    
    def test_cpu_info(self, ssh_exec):
        """Get CPU information."""
        stdout, stderr, code = ssh_exec("cat /proc/cpuinfo | grep 'model name' | head -1")
        assert code == 0
        assert "model name" in stdout.lower()
    
    def test_cpu_load(self, ssh_exec):
        """Get CPU load average."""
        stdout, stderr, code = ssh_exec("uptime")
        assert code == 0
        assert "load average" in stdout.lower()
    
    def test_cpu_temperature(self, ssh_exec):
        """Get CPU temperature (Pi-specific)."""
        stdout, stderr, code = ssh_exec("vcgencmd measure_temp")
        if code == 0:
            assert "temp" in stdout.lower()
            assert "C" in stdout
        else:
            pytest.skip("vcgencmd not available (not running on Pi?)")


class TestMemory:
    """Test memory monitoring."""
    
    def test_memory_info(self, ssh_exec):
        """Get memory information."""
        stdout, stderr, code = ssh_exec("free -m")
        assert code == 0
        lines = stdout.split('\n')
        assert len(lines) >= 2
        assert "Mem:" in lines[1]
    
    def test_memory_usage_reasonable(self, ssh_exec):
        """Verify memory usage is within reasonable bounds."""
        stdout, stderr, code = ssh_exec(
            "free | grep Mem | awk '{printf \"%.2f\", $3/$2 * 100.0}'"
        )
        assert code == 0
        usage_percent = float(stdout)
        assert 0 <= usage_percent <= 100, f"Memory usage {usage_percent}% out of range"


class TestDisk:
    """Test disk monitoring."""
    
    def test_disk_usage(self, ssh_exec):
        """Get disk usage information."""
        stdout, stderr, code = ssh_exec("df -h /")
        assert code == 0
        assert "/" in stdout
        assert "%" in stdout
    
    def test_disk_space_available(self, ssh_exec):
        """Verify sufficient disk space available."""
        stdout, stderr, code = ssh_exec(
            "df / | tail -1 | awk '{print $4}'"
        )
        assert code == 0
        available_kb = int(stdout)
        assert available_kb > 100000, f"Less than 100MB available: {available_kb}KB"
    
    def test_birdnet_dir_exists(self, ssh_exec, pi_install_path):
        """Verify BattyBirdNET-Pi directory exists."""
        stdout, stderr, code = ssh_exec(f"test -d {pi_install_path} && echo 'exists'")
        if code == 0:
            assert stdout == "exists"
        else:
            pytest.skip(f"BattyBirdNET-Pi not installed at {pi_install_path}")


class TestNetwork:
    """Test network connectivity."""
    
    def test_network_interfaces(self, ssh_exec):
        """List network interfaces."""
        stdout, stderr, code = ssh_exec("ip addr show | grep -E '^[0-9]+:' | awk -F: '{print $2}'")
        assert code == 0
        interfaces = [iface.strip() for iface in stdout.split('\n') if iface.strip()]
        assert len(interfaces) > 0
        assert "lo" in interfaces
    
    def test_default_route(self, ssh_exec):
        """Verify default route exists."""
        stdout, stderr, code = ssh_exec("ip route | grep default")
        assert code == 0
        assert "default" in stdout
    
    def test_dns_resolution(self, ssh_exec):
        """Test DNS resolution."""
        stdout, stderr, code = ssh_exec("getent hosts google.com || ping -c 1 google.com")
        assert code == 0, "DNS resolution failed"
    
    def test_internet_connectivity(self, ssh_exec):
        """Test internet connectivity."""
        stdout, stderr, code = ssh_exec("ping -c 2 8.8.8.8")
        if code == 0:
            assert "2 received" in stdout or "100% packet loss" not in stdout
        else:
            pytest.skip("No internet connectivity")


class TestUSBDevices:
    """Test USB device detection."""
    
    def test_usb_devices(self, ssh_exec):
        """List USB devices."""
        stdout, stderr, code = ssh_exec("lsusb")
        assert code == 0
        assert "Bus" in stdout
    
    def test_audio_devices(self, ssh_exec):
        """List audio devices."""
        stdout, stderr, code = ssh_exec("arecord -l")
        if code == 0:
            assert "card" in stdout.lower() or "List of" in stdout
        else:
            pytest.skip("No audio recording devices found")


@pytest.mark.requires_root
class TestPrivilegedOperations:
    """Tests that require sudo/root access."""
    
    def test_sudo_available(self, ssh_exec):
        """Check if sudo is available."""
        stdout, stderr, code = ssh_exec("sudo -n whoami")
        if code == 0:
            assert stdout == "root"
        else:
            pytest.skip("Sudo not available or requires password")
    
    def test_systemd_status(self, ssh_exec):
        """Test systemd is running."""
        stdout, stderr, code = ssh_exec("systemctl --version")
        if code == 0:
            assert "systemd" in stdout.lower()
        else:
            pytest.skip("systemd not available")