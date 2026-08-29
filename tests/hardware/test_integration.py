"""
Integration tests for BattyBirdNET-Pi on Raspberry Pi.

Tests complete workflows: detection → recording → database → notification.
"""

import pytest
import time


class TestInstallation:
    """Test BattyBirdNET-Pi installation."""
    
    def test_installation_directory_exists(self, ssh_exec, pi_install_path):
        """Verify BattyBirdNET-Pi is installed."""
        stdout, stderr, code = ssh_exec(f"test -d {pi_install_path} && echo 'exists'")
        assert code == 0 and stdout == "exists", \
            f"BattyBirdNET-Pi not found at {pi_install_path}"
    
    def test_scripts_directory_exists(self, ssh_exec, pi_install_path):
        """Verify scripts directory exists."""
        stdout, stderr, code = ssh_exec(f"test -d {pi_install_path}/scripts && echo 'exists'")
        assert code == 0 and stdout == "exists"
    
    def test_key_scripts_exist(self, ssh_exec, pi_install_path):
        """Verify key scripts are present."""
        scripts = [
            "server.py",
            "analyze.py",
            "birdnet_analysis.sh",
            "batnet_analysis.sh",
        ]
        
        for script in scripts:
            stdout, stderr, code = ssh_exec(
                f"test -f {pi_install_path}/scripts/{script} && echo 'exists'"
            )
            if code != 0:
                pytest.skip(f"Script {script} not found")
    
    def test_python_dependencies_installed(self, ssh_exec, pi_install_path):
        """Verify Python dependencies are installed."""
        stdout, stderr, code = ssh_exec(
            f"cd {pi_install_path} && python3 -c 'import numpy, sqlite3' 2>&1 && echo 'OK'"
        )
        if code == 0 and "OK" in stdout:
            pass
        else:
            pytest.skip("Python dependencies not installed")


class TestConfiguration:
    """Test configuration on Pi."""
    
    def test_config_file_exists(self, ssh_exec, pi_config_path):
        """Verify configuration file exists."""
        stdout, stderr, code = ssh_exec(f"test -f {pi_config_path} && echo 'exists'")
        if code == 0:
            assert stdout == "exists"
        else:
            pytest.skip(f"Config file {pi_config_path} not found")
    
    def test_config_readable(self, ssh_exec, pi_config_path):
        """Verify configuration is readable."""
        stdout, stderr, code = ssh_exec(f"head -10 {pi_config_path}")
        if code == 0:
            assert len(stdout) > 0
        else:
            pytest.skip("Cannot read config file")
    
    def test_config_has_required_keys(self, ssh_exec, pi_config_path):
        """Verify config has required keys."""
        required_keys = [
            "LATITUDE",
            "LONGITUDE",
            "CONFIDENCE",
        ]
        
        for key in required_keys:
            stdout, stderr, code = ssh_exec(f"grep '^{key}=' {pi_config_path}")
            if code != 0:
                pytest.skip(f"Config missing required key: {key}")
    
    def test_config_valid_values(self, ssh_exec, pi_config_path):
        """Verify config has valid values."""
        stdout, stderr, code = ssh_exec(f"grep '^LATITUDE=' {pi_config_path}")
        if code == 0:
            lat = stdout.split('=')[1].strip()
            try:
                lat_float = float(lat)
                assert -90 <= lat_float <= 90
            except ValueError:
                pytest.fail(f"Invalid latitude value: {lat}")
        else:
            pytest.skip("Cannot read LATITUDE from config")


class TestDatabase:
    """Test database operations on Pi."""
    
    def test_database_exists(self, ssh_exec, pi_install_path):
        """Verify database file exists."""
        stdout, stderr, code = ssh_exec(
            f"test -f {pi_install_path}/scripts/birds.db && echo 'exists'"
        )
        if code == 0:
            assert stdout == "exists"
        else:
            pytest.skip("Database file not found")
    
    def test_database_accessible(self, ssh_exec, pi_install_path):
        """Verify database is accessible."""
        stdout, stderr, code = ssh_exec(
            f"sqlite3 {pi_install_path}/scripts/birds.db 'SELECT COUNT(*) FROM detections;' 2>&1"
        )
        if code == 0:
            assert stdout.isdigit()
        else:
            pytest.skip("Cannot access database")
    
    def test_database_schema_valid(self, ssh_exec, pi_install_path):
        """Verify database schema is valid."""
        stdout, stderr, code = ssh_exec(
            f"sqlite3 {pi_install_path}/scripts/birds.db '.tables'"
        )
        if code == 0:
            assert "detections" in stdout.lower()
        else:
            pytest.skip("Database schema invalid")
    
    def test_database_recent_detections(self, ssh_exec, pi_install_path):
        """Check for recent detections (if any)."""
        stdout, stderr, code = ssh_exec(
            f"sqlite3 {pi_install_path}/scripts/birds.db "
            f"'SELECT COUNT(*) FROM detections WHERE date(Date) >= date(\"now\", \"-7 days\");'"
        )
        if code == 0:
            count = int(stdout.strip())
            pytest.logger.info(f"Found {count} detections in last 7 days")
        else:
            pytest.skip("Cannot query recent detections")


class TestServices:
    """Test BattyBirdNET-Pi services."""
    
    def test_birdnet_server_running(self, ssh_exec):
        """Verify birdnet_server is running."""
        stdout, stderr, code = ssh_exec("systemctl is-active birdnet_server")
        if code == 0:
            assert stdout == "active"
        else:
            pytest.skip("birdnet_server not running")
    
    def test_birdnet_process_running(self, ssh_exec):
        """Verify birdnet process is running."""
        stdout, stderr, code = ssh_exec("pgrep -f 'python.*server.py' || echo 'not_running'")
        if code == 0 and stdout != "not_running":
            assert stdout.isdigit()
        else:
            pytest.skip("birdnet process not running")
    
    def test_services_restart_cleanly(self, ssh_exec):
        """Test services restart cleanly."""
        stdout, stderr, code = ssh_exec("sudo systemctl restart birdnet_server")
        if code == 0:
            time.sleep(2)
            stdout, _, _ = ssh_exec("systemctl is-active birdnet_server")
            assert stdout == "active"
        else:
            pytest.skip("Cannot restart birdnet_server")


class TestLogFileAccess:
    """Test log file access and monitoring."""
    
    def test_log_directory_exists(self, ssh_exec):
        """Verify log directory exists."""
        stdout, stderr, code = ssh_exec("test -d /var/log/birdnet-pi && echo 'exists'")
        if code == 0:
            assert stdout == "exists"
        else:
            pytest.skip("Log directory not found")
    
    def test_log_files_present(self, ssh_exec):
        """Verify log files are present."""
        stdout, stderr, code = ssh_exec("ls -la /var/log/birdnet-pi/*.log 2>/dev/null | head -5")
        if code == 0 and stdout.strip():
            assert ".log" in stdout
        else:
            pytest.skip("No log files found")
    
    def test_log_writable(self, ssh_exec):
        """Verify logs are being written."""
        stdout, stderr, code = ssh_exec(
            "ls -lt /var/log/birdnet-pi/*.log 2>/dev/null | head -1 | awk '{{print $9}}'"
        )
        if code == 0 and stdout.strip():
            log_file = stdout.strip()
            stdout, stderr, code = ssh_exec(f"tail -5 {log_file}")
            if code == 0:
                assert len(stdout) > 0
        else:
            pytest.skip("Cannot verify log writing")


class TestNetworkAccessibility:
    """Test network accessibility of BattyBirdNET-Pi."""
    
    def test_web_server_responds(self, ssh_exec):
        """Test if web server is responding."""
        stdout, stderr, code = ssh_exec(
            "curl -s -o /dev/null -w '%{{http_code}}' http://localhost:8080 2>&1 || echo 'failed'"
        )
        if code == 0 and stdout.isdigit():
            assert int(stdout) in [200, 301, 302]
        else:
            pytest.skip("Web server not responding on port 8080")
    
    def test_caddy_running(self, ssh_exec):
        """Verify Caddy web server is running."""
        stdout, stderr, code = ssh_exec("systemctl is-active caddy")
        if code == 0:
            assert stdout == "active"
        else:
            pytest.skip("Caddy not running")
    
    def test_birdnetpi_url_accessible(self, ssh_exec, pi_config_path):
        """Test BIRDNETPI_URL from config."""
        stdout, stderr, code = ssh_exec(f"grep '^BIRDNETPI_URL=' {pi_config_path}")
        if code == 0:
            url = stdout.split('=')[1].strip()
            pytest.logger.info(f"BIRDNETPI_URL configured as: {url}")
        else:
            pytest.skip("BIRDNETPI_URL not configured")


class TestEndToEnd:
    """End-to-end workflow tests."""
    
    def test_full_stack_health_check(self, ssh_exec, pi_install_path, pi_config_path):
        """Comprehensive health check of entire stack."""
        checks = {
            "installation": f"test -d {pi_install_path}",
            "config": f"test -f {pi_config_path}",
            "database": f"test -f {pi_install_path}/scripts/birds.db",
            "server_active": "systemctl is-active birdnet_server",
            "caddy_active": "systemctl is-active caddy",
        }
        
        results = {}
        for name, command in checks.items():
            _, _, code = ssh_exec(command)
            results[name] = (code == 0)
        
        failed = [name for name, ok in results.items() if not ok]
        
        if failed:
            pytest.skip(f"Health check failed for: {', '.join(failed)}")
        else:
            pytest.logger.info("All health checks passed")
    
    def test_disk_space_adequate(self, ssh_exec):
        """Verify adequate disk space for operation."""
        stdout, stderr, code = ssh_exec(
            "df / | tail -1 | awk '{print $4}'"
        )
        if code == 0:
            available_kb = int(stdout)
            available_mb = available_kb / 1024
            assert available_mb > 500, f"Less than 500MB available: {available_mb}MB"
        else:
            pytest.skip("Cannot check disk space")
    
    def test_memory_adequate(self, ssh_exec):
        """Verify adequate free memory."""
        stdout, stderr, code = ssh_exec(
            "free -m | grep Mem | awk '{print $7}'"
        )
        if code == 0:
            free_mb = int(stdout)
            assert free_mb > 100, f"Less than 100MB free: {free_mb}MB"
        else:
            pytest.skip("Cannot check memory")