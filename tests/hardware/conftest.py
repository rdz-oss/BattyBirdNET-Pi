"""
Pytest fixtures for hardware-in-the-loop tests on Raspberry Pi.

These fixtures establish SSH connections and provide utilities for
remote command execution, file transfer, and service management.
"""

import pytest
import paramiko
import scp
import json
import os
from pathlib import Path
from typing import Optional, Tuple


def load_pi_config() -> dict:
    """Load Pi configuration from JSON file or environment variables."""
    config_file = Path(__file__).parent / "pi_config.json"
    
    if config_file.exists():
        with open(config_file) as f:
            config = json.load(f)
    else:
        config = {}
    
    env_mappings = {
        "BATTY_PI_HOST": "hostname",
        "BATTY_PI_USER": "username",
        "BATTY_PI_PASSWORD": "password",
        "BATTY_PI_KEY_FILE": "key_file",
        "BATTY_PI_PORT": "port",
    }
    
    for env_var, config_key in env_mappings.items():
        if os.environ.get(env_var):
            config[config_key] = os.environ[env_var]
    
    if "key_file" in config and config["key_file"]:
        config["key_file"] = os.path.expanduser(config["key_file"])
    
    return config


@pytest.fixture(scope="session")
def pi_config(request) -> dict:
    """
    Provide Pi configuration with CLI override support.
    
    Usage:
        pytest tests/hardware/ --pi-host=192.168.1.100
    """
    config = load_pi_config()
    
    if hasattr(request, "config"):
        if request.config.getoption("--pi-host"):
            config["hostname"] = request.config.getoption("--pi-host")
        if request.config.getoption("--pi-port"):
            config["port"] = request.config.getoption("--pi-port")
        if request.config.getoption("--pi-user"):
            config["username"] = request.config.getoption("--pi-user")
    
    return config


@pytest.fixture(scope="session")
def ssh_client(pi_config) -> paramiko.SSHClient:
    """
    Create and configure SSH client connection to Pi.
    
    This is a session-scoped fixture, so the connection is reused
    across multiple tests for efficiency.
    """
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    connect_kwargs = {
        "hostname": pi_config["hostname"],
        "username": pi_config["username"],
        "port": int(pi_config.get("port", 22)),
        "timeout": int(pi_config.get("timeout", 30)),
    }
    
    if pi_config.get("key_file") and os.path.exists(pi_config["key_file"]):
        connect_kwargs["key_filename"] = pi_config["key_file"]
    elif pi_config.get("password"):
        connect_kwargs["password"] = pi_config["password"]
    
    try:
        client.connect(**connect_kwargs)
        yield client
    except Exception as e:
        pytest.skip(f"Cannot connect to Pi at {pi_config['hostname']}: {e}")
    finally:
        client.close()


@pytest.fixture
def ssh_exec(ssh_client) -> callable:
    """
    Provide a function to execute commands on Pi via SSH.
    
    Returns:
        Function that executes a command and returns (stdout, stderr, exit_code)
    
    Example:
        def test_hostname(ssh_exec):
            stdout, stderr, code = ssh_exec("hostname")
            assert code == 0
            assert "birdnetpi" in stdout.lower()
    """
    def execute_command(command: str, timeout: int = 60) -> Tuple[str, str, int]:
        stdin, stdout, stderr = ssh_client.exec_command(command, timeout=timeout)
        exit_code = stdout.channel.recv_exit_status()
        return stdout.read().decode().strip(), stderr.read().decode().strip(), exit_code
    
    return execute_command


@pytest.fixture
def ssh_scp(ssh_client) -> scp.SCPClient:
    """
    Provide SCP client for file transfers.
    
    Example:
        def test_file_upload(ssh_scp, tmp_path):
            test_file = tmp_path / "test.txt"
            test_file.write_text("hello")
            ssh_scp.put(str(test_file), "/tmp/test.txt")
    """
    return scp.SCPClient(ssh_client.get_transport())


@pytest.fixture
def pi_temp_dir(ssh_exec) -> str:
    """
    Create and provide a temporary directory on Pi for test files.
    
    Automatically cleaned up after test session.
    """
    stdout, _, code = ssh_exec("mktemp -d")
    if code != 0:
        pytest.fail("Could not create temporary directory on Pi")
    
    temp_dir = stdout.strip()
    yield temp_dir
    
    ssh_exec(f"rm -rf {temp_dir}")


@pytest.fixture
def pi_install_path(pi_config) -> str:
    """Provide the BattyBirdNET-Pi installation path on Pi."""
    return pi_config.get("install_path", "/home/pi/BattyBirdNET-Pi")


@pytest.fixture
def pi_config_path(pi_config) -> str:
    """Provide the birdnet.conf path on Pi."""
    return pi_config.get("config_path", "/etc/birdnet/birdnet.conf")


def pytest_addoption(parser):
    """Add command-line options for Pi configuration."""
    parser.addoption(
        "--pi-host",
        action="store",
        default=None,
        help="Pi hostname or IP address"
    )
    parser.addoption(
        "--pi-port",
        action="store",
        type=int,
        default=None,
        help="SSH port (default: 22)"
    )
    parser.addoption(
        "--pi-user",
        action="store",
        default=None,
        help="SSH username (default: pi)"
    )


def pytest_collection_modifyitems(config, items):
    """Mark hardware tests appropriately."""
    for item in items:
        if item.fspath.dirname.endswith("hardware"):
            item.add_marker(pytest.mark.hardware)
            item.add_marker(pytest.mark.requires_pi)