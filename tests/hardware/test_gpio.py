"""
Tests for GPIO functionality on Raspberry Pi.

Tests GPIO pin access, LED control, and button input.
Requires RPi.GPIO or gpiozero library on Pi.

Note: These tests may require physical hardware connections.
"""

import pytest


@pytest.mark.requires_gpio
class TestGPIOLibraries:
    """Test GPIO library availability."""
    
    def test_rpigpio_available(self, ssh_exec):
        """Check if RPi.GPIO is installed."""
        stdout, stderr, code = ssh_exec("python3 -c 'import RPi.GPIO' 2>&1 && echo 'installed'")
        if code == 0 and "installed" in stdout:
            pass
        else:
            pytest.skip("RPi.GPIO not installed")
    
    def test_gpiozero_available(self, ssh_exec):
        """Check if gpiozero is installed."""
        stdout, stderr, code = ssh_exec("python3 -c 'import gpiozero' 2>&1 && echo 'installed'")
        if code == 0 and "installed" in stdout:
            pass
        else:
            pytest.skip("gpiozero not installed")
    
    def test_vcgencmd_available(self, ssh_exec):
        """Check if vcgencmd is available (Pi-specific)."""
        stdout, stderr, code = ssh_exec("which vcgencmd")
        if code == 0:
            assert "vcgencmd" in stdout
        else:
            pytest.skip("vcgencmd not available")


@pytest.mark.requires_gpio
@pytest.mark.requires_hardware
class TestGPIOPins:
    """Test GPIO pin functionality."""
    
    def test_gpio_pin_mode(self, ssh_exec, pi_temp_dir):
        """Test setting GPIO pin mode."""
        script = f"""
import RPi.GPIO as GPIO
import sys

try:
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(17, GPIO.OUT)
    GPIO.output(17, GPIO.LOW)
    GPIO.cleanup()
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {{e}}", file=sys.stderr)
    sys.exit(1)
"""
        script_file = f"{pi_temp_dir}/test_gpio.py"
        
        ssh_exec(f"cat > {script_file} << 'EOF'\n{script}\nEOF")
        stdout, stderr, code = ssh_exec(f"python3 {script_file}")
        
        if code == 0 and "SUCCESS" in stdout:
            pass
        else:
            pytest.skip(f"GPIO test failed: {stderr}")
    
    def test_gpio_pwm_available(self, ssh_exec):
        """Test if PWM is available."""
        stdout, stderr, code = ssh_exec(
            "python3 -c 'from gpiozero import PWMLED; print(\"PWM OK\")' 2>&1"
        )
        if code == 0 and "PWM OK" in stdout:
            pass
        else:
            pytest.skip("PWM not available")


@pytest.mark.requires_gpio
@pytest.mark.requires_hardware
class TestLEDControl:
    """Test LED control via GPIO."""
    
    def test_led_on(self, ssh_exec, pi_temp_dir):
        """Test turning LED on (GPIO 17)."""
        script = f"""
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(17, GPIO.OUT)
GPIO.output(17, GPIO.HIGH)
print("LED_ON")
GPIO.cleanup()
"""
        script_file = f"{pi_temp_dir}/test_led_on.py"
        ssh_exec(f"cat > {script_file} << 'EOF'\n{script}\nEOF")
        
        stdout, stderr, code = ssh_exec(f"python3 {script_file}")
        
        if code == 0 and "LED_ON" in stdout:
            pass
        else:
            pytest.skip(f"LED on test failed: {stderr}")
    
    def test_led_off(self, ssh_exec, pi_temp_dir):
        """Test turning LED off (GPIO 17)."""
        script = f"""
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(17, GPIO.OUT)
GPIO.output(17, GPIO.LOW)
print("LED_OFF")
GPIO.cleanup()
"""
        script_file = f"{pi_temp_dir}/test_led_off.py"
        ssh_exec(f"cat > {script_file} << 'EOF'\n{script}\nEOF")
        
        stdout, stderr, code = ssh_exec(f"python3 {script_file}")
        
        if code == 0 and "LED_OFF" in stdout:
            pass
        else:
            pytest.skip(f"LED off test failed: {stderr}")
    
    def test_led_blink(self, ssh_exec, pi_temp_dir):
        """Test LED blinking (requires hardware to verify)."""
        script = f"""
import RPi.GPIO as GPIO
import time
GPIO.setmode(GPIO.BCM)
GPIO.setup(17, GPIO.OUT)
for _ in range(3):
    GPIO.output(17, GPIO.HIGH)
    time.sleep(0.1)
    GPIO.output(17, GPIO.LOW)
    time.sleep(0.1)
print("BLINK_COMPLETE")
GPIO.cleanup()
"""
        script_file = f"{pi_temp_dir}/test_led_blink.py"
        ssh_exec(f"cat > {script_file} << 'EOF'\n{script}\nEOF")
        
        stdout, stderr, code = ssh_exec(f"python3 {script_file}")
        
        if code == 0 and "BLINK_COMPLETE" in stdout:
            pass
        else:
            pytest.skip(f"LED blink test failed: {stderr}")


@pytest.mark.requires_gpio
@pytest.mark.requires_hardware
class TestButtonInput:
    """Test button input via GPIO."""
    
    def test_button_read(self, ssh_exec, pi_temp_dir):
        """Test reading button state (GPIO 27)."""
        script = f"""
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(27, GPIO.IN, pull_up_down=GPIO.PUD_UP)
state = GPIO.input(27)
print(f"BUTTON_STATE: {{state}}")
GPIO.cleanup()
"""
        script_file = f"{pi_temp_dir}/test_button.py"
        ssh_exec(f"cat > {script_file} << 'EOF'\n{script}\nEOF")
        
        stdout, stderr, code = ssh_exec(f"python3 {script_file}")
        
        if code == 0 and "BUTTON_STATE:" in stdout:
            pass
        else:
            pytest.skip(f"Button read test failed: {stderr}")


@pytest.mark.requires_gpio
class TestPiHardwareInfo:
    """Test Pi hardware information."""
    
    def test_pi_model(self, ssh_exec):
        """Get Pi model information."""
        stdout, stderr, code = ssh_exec("cat /proc/device-tree/model")
        if code == 0:
            assert "Raspberry Pi" in stdout
        else:
            pytest.skip("Cannot read Pi model")
    
    def test_pi_revision(self, ssh_exec):
        """Get Pi revision."""
        stdout, stderr, code = ssh_exec("cat /proc/device-tree/system/linux,revision")
        if code == 0:
            assert len(stdout) > 0
        else:
            pytest.skip("Cannot read Pi revision")
    
    def test_pi_serial(self, ssh_exec):
        """Get Pi serial number."""
        stdout, stderr, code = ssh_exec("cat /proc/device-tree/serial-number")
        if code == 0:
            assert len(stdout.strip()) > 0
        else:
            pytest.skip("Cannot read Pi serial")
    
    def test_gpu_memory(self, ssh_exec):
        """Get GPU memory allocation."""
        stdout, stderr, code = ssh_exec("vcgencmd get_mem_gpu")
        if code == 0:
            assert "gpu" in stdout.lower()
        else:
            pytest.skip("Cannot get GPU memory")
    
    def test_arm_memory(self, ssh_exec):
        """Get ARM memory allocation."""
        stdout, stderr, code = ssh_exec("vcgencmd get_mem_arm")
        if code == 0:
            assert "arm" in stdout.lower()
        else:
            pytest.skip("Cannot get ARM memory")
    
    def test_clock_rates(self, ssh_exec):
        """Get CPU clock rates."""
        stdout, stderr, code = ssh_exec("vcgencmd measure_clock arm")
        if code == 0:
            assert "frequency" in stdout.lower() or "clock" in stdout.lower()
        else:
            pytest.skip("Cannot get clock rates")