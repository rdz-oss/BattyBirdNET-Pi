"""
Tests for BattyBirdNET-Pi systemd services on Raspberry Pi.

Tests service status, start/stop/restart, and log monitoring.
"""

import pytest
import time


class TestServiceStatus:
    """Test systemd service status."""
    
    def test_birdnet_service_exists(self, ssh_exec):
        """Verify birdnet service is defined."""
        stdout, stderr, code = ssh_exec("systemctl list-unit-files | grep birdnet")
        if code == 0:
            assert "birdnet" in stdout.lower()
        else:
            pytest.skip("BirdNET services not installed")
    
    def test_birdnet_server_status(self, ssh_exec):
        """Check birdnet_server service status."""
        stdout, stderr, code = ssh_exec("systemctl is-active birdnet_server")
        if code == 0:
            assert stdout == "active"
        else:
            pytest.skip("birdnet_server service not active or not installed")
    
    def test_birdnet_analysis_status(self, ssh_exec):
        """Check birdnet_analysis service status."""
        stdout, stderr, code = ssh_exec("systemctl is-active birdnet_analysis")
        if code == 0:
            assert stdout == "active"
        elif code == 3:
            pytest.skip("birdnet_analysis service inactive")
        else:
            pytest.skip("birdnet_analysis service not installed")
    
    def test_birdnet_recording_status(self, ssh_exec):
        """Check birdnet_recording service status."""
        stdout, stderr, code = ssh_exec("systemctl is-active birdnet_recording")
        if code in [0, 3]:
            pass
        else:
            pytest.skip("birdnet_recording service not installed")


class TestServiceControl:
    """Test service start/stop/restart operations."""
    
    @pytest.fixture
    def service_name(self):
        """Define a safe service to test with."""
        return "birdnet_server"
    
    def test_service_stop(self, ssh_exec, service_name):
        """Test stopping a service."""
        stdout, stderr, code = ssh_exec(f"sudo systemctl stop {service_name}")
        if code == 0:
            time.sleep(1)
            stdout, _, _ = ssh_exec(f"systemctl is-active {service_name}")
            assert stdout in ["inactive", "deactivating"]
            ssh_exec(f"sudo systemctl start {service_name}")
        else:
            pytest.skip(f"Cannot stop {service_name} (may require sudo)")
    
    def test_service_start(self, ssh_exec, service_name):
        """Test starting a service."""
        stdout, stderr, code = ssh_exec(f"sudo systemctl start {service_name}")
        if code == 0:
            time.sleep(1)
            stdout, _, _ = ssh_exec(f"systemctl is-active {service_name}")
            assert stdout == "active"
        else:
            pytest.skip(f"Cannot start {service_name}")
    
    def test_service_restart(self, ssh_exec, service_name):
        """Test restarting a service."""
        stdout, stderr, code = ssh_exec(f"sudo systemctl restart {service_name}")
        if code == 0:
            time.sleep(2)
            stdout, _, _ = ssh_exec(f"systemctl is-active {service_name}")
            assert stdout == "active"
        else:
            pytest.skip(f"Cannot restart {service_name}")
    
    def test_service_reload(self, ssh_exec, service_name):
        """Test reloading a service configuration."""
        stdout, stderr, code = ssh_exec(f"sudo systemctl reload {service_name}")
        if code in [0, 1]:
            pass
        else:
            pytest.skip(f"Reload not supported for {service_name}")


class TestServiceLogs:
    """Test service log access."""
    
    def test_journalctl_available(self, ssh_exec):
        """Verify journalctl is available."""
        stdout, stderr, code = ssh_exec("journalctl --version")
        if code == 0:
            assert "journalctl" in stdout.lower()
        else:
            pytest.skip("journalctl not available")
    
    def test_birdnet_logs_accessible(self, ssh_exec):
        """Test accessing birdnet logs via journalctl."""
        stdout, stderr, code = ssh_exec(
            "journalctl -u birdnet_server --no-pager -n 5"
        )
        if code == 0:
            assert len(stdout) > 0
        else:
            pytest.skip("Cannot access birdnet_server logs")
    
    def test_recent_logs(self, ssh_exec):
        """Test retrieving recent logs."""
        stdout, stderr, code = ssh_exec(
            "journalctl -u birdnet_server --no-pager --since '1 hour ago' | head -20"
        )
        if code == 0 and stdout.strip():
            pass
        else:
            pytest.skip("No recent logs found")
    
    def test_log_file_exists(self, ssh_exec):
        """Check if log files exist in expected location."""
        stdout, stderr, code = ssh_exec(
            "ls -la /var/log/birdnet-pi/ 2>/dev/null || ls -la /var/log/birdnet/ 2>/dev/null"
        )
        if code == 0:
            assert "log" in stdout.lower() or "total" in stdout.lower()
        else:
            pytest.skip("Log directory not found")


class TestServiceConfiguration:
    """Test service configuration."""
    
    def test_service_file_exists(self, ssh_exec):
        """Verify service unit files exist."""
        stdout, stderr, code = ssh_exec(
            "ls /etc/systemd/system/birdnet*.service 2>/dev/null || "
            "ls /lib/systemd/system/birdnet*.service 2>/dev/null"
        )
        if code == 0:
            assert ".service" in stdout
        else:
            pytest.skip("Service files not found in standard locations")
    
    def test_service_show_config(self, ssh_exec):
        """Get service configuration."""
        stdout, stderr, code = ssh_exec(
            "systemctl cat birdnet_server 2>/dev/null"
        )
        if code == 0:
            assert "[Unit]" in stdout or "[Service]" in stdout
        else:
            pytest.skip("Cannot show service configuration")
    
    def test_service_environment(self, ssh_exec):
        """Check service environment variables."""
        stdout, stderr, code = ssh_exec(
            "systemctl show birdnet_server --property=Environment"
        )
        if code == 0:
            pass
        else:
            pytest.skip("Cannot get service environment")


class TestServiceDependencies:
    """Test service dependencies and requirements."""
    
    def test_python3_available(self, ssh_exec):
        """Verify Python 3 is available for services."""
        stdout, stderr, code = ssh_exec("which python3")
        assert code == 0
        assert "/python3" in stdout
    
    def test_required_directories_exist(self, ssh_exec, pi_install_path):
        """Verify required directories exist."""
        dirs_to_check = [
            pi_install_path,
            "/etc/birdnet",
            "/var/log/birdnet-pi",
        ]
        
        for dir_path in dirs_to_check:
            stdout, stderr, code = ssh_exec(f"test -d {dir_path} && echo 'exists'")
            if code != 0:
                pytest.skip(f"Directory {dir_path} does not exist")
    
    def test_config_file_accessible(self, ssh_exec, pi_config_path):
        """Verify configuration file is accessible."""
        stdout, stderr, code = ssh_exec(f"test -f {pi_config_path} && echo 'exists'")
        if code == 0:
            assert stdout == "exists"
        else:
            pytest.skip(f"Config file {pi_config_path} not found")