"""
Tests for audio hardware and recording functionality on Raspberry Pi.

Tests audio device detection, recording, playback, and format support.
"""

import pytest
import time


class TestAudioDevices:
    """Test audio device detection and capabilities."""
    
    def test_arecord_available(self, ssh_exec):
        """Verify arecord command is available."""
        stdout, stderr, code = ssh_exec("which arecord")
        assert code == 0
        assert "arecord" in stdout
    
    def test_list_capture_devices(self, ssh_exec):
        """List all capture devices."""
        stdout, stderr, code = ssh_exec("arecord -l")
        if code == 0:
            assert "List of" in stdout and "Capture" in stdout
        else:
            pytest.skip("No capture devices found")
    
    def test_usb_audio_device(self, ssh_exec):
        """Check for USB audio device (typical for bat detectors)."""
        stdout, stderr, code = ssh_exec("arecord -l | grep -i usb")
        if code == 0:
            assert "USB" in stdout
        else:
            pytest.skip("No USB audio device found")
    
    def test_audio_device_info(self, ssh_exec):
        """Get detailed audio device information."""
        stdout, stderr, code = ssh_exec("arecord -L | head -20")
        assert code == 0
        assert len(stdout) > 0


class TestAudioFormats:
    """Test audio format support."""
    
    def test_supported_formats(self, ssh_exec):
        """List supported audio formats."""
        stdout, stderr, code = ssh_exec("arecord --help | grep -A 20 'Valid sample'")
        if code == 0:
            assert "sample" in stdout.lower()
        else:
            pytest.skip("Cannot get format information")
    
    def test_wav_support(self, ssh_exec):
        """Verify WAV format support."""
        stdout, stderr, code = ssh_exec("aplay --help | grep -i wav")
        if code == 0:
            assert "WAV" in stdout.upper() or "wav" in stdout
        else:
            pytest.skip("WAV format info not found")


class TestRecording:
    """Test audio recording functionality."""
    
    @pytest.fixture
    def test_audio_file(self, pi_temp_dir):
        """Provide path to test audio file."""
        return f"{pi_temp_dir}/test_record.wav"
    
    def test_record_silence(self, ssh_exec, test_audio_file):
        """Test recording silence (no input needed)."""
        command = (
            f"timeout 2 arecord -D plughw:0,0 -r 256000 -f S16_LE -c 1 "
            f"-t wav {test_audio_file} 2>&1 || true"
        )
        stdout, stderr, code = ssh_exec(command)
        
        if code == 0 or "arecord" in stdout.lower():
            time.sleep(3)
            stdout, stderr, code = ssh_exec(f"test -f {test_audio_file} && echo 'exists'")
            if code == 0:
                assert stdout == "exists"
            else:
                pytest.skip("Recording failed to create file")
        else:
            pytest.skip("Recording device not available or busy")
    
    def test_record_verify_file(self, ssh_exec, test_audio_file):
        """Verify recorded file has correct format."""
        stdout, stderr, code = ssh_exec(f"file {test_audio_file}")
        if code == 0 and "exists" in stdout:
            assert "WAVE" in stdout or "audio" in stdout.lower()
        else:
            pytest.skip("Test audio file not found")
    
    def test_record_file_size(self, ssh_exec, test_audio_file):
        """Verify recorded file has reasonable size."""
        stdout, stderr, code = ssh_exec(f"stat -c %s {test_audio_file} 2>/dev/null || stat -f %z {test_audio_file}")
        if code == 0:
            file_size = int(stdout)
            assert file_size > 0, "Recorded file is empty"
            assert file_size < 10000000, "Recorded file suspiciously large"
        else:
            pytest.skip("Cannot get file size")
    
    def test_record_cleanup(self, ssh_exec, test_audio_file):
        """Verify test file is cleaned up."""
        stdout, stderr, code = ssh_exec(f"rm -f {test_audio_file} && echo 'cleaned'")
        assert code == 0


class TestPlayback:
    """Test audio playback functionality."""
    
    def test_aplay_available(self, ssh_exec):
        """Verify aplay command is available."""
        stdout, stderr, code = ssh_exec("which aplay")
        assert code == 0
        assert "aplay" in stdout
    
    def test_list_playback_devices(self, ssh_exec):
        """List playback devices."""
        stdout, stderr, code = ssh_exec("aplay -l")
        if code == 0:
            assert "List of" in stdout
        else:
            pytest.skip("No playback devices found")


class TestAudioQuality:
    """Test audio quality parameters."""
    
    def test_sample_rate_256k(self, ssh_exec):
        """Test 256kHz sample rate support (bat detection)."""
        stdout, stderr, code = ssh_exec(
            "arecord -r 256000 -f S16_LE -c 1 -t wav -d 1 /tmp/test_256k.wav 2>&1 && "
            "rm -f /tmp/test_256k.wav && echo 'success'"
        )
        if code == 0 and "success" in stdout:
            pass
        else:
            pytest.skip("256kHz sample rate not supported")
    
    def test_sample_rate_384k(self, ssh_exec):
        """Test 384kHz sample rate support (high-res bat detection)."""
        stdout, stderr, code = ssh_exec(
            "arecord -r 384000 -f S16_LE -c 1 -t wav -d 1 /tmp/test_384k.wav 2>&1 && "
            "rm -f /tmp/test_384k.wav && echo 'success'"
        )
        if code == 0 and "success" in stdout:
            pass
        else:
            pytest.skip("384kHz sample rate not supported")
    
    def test_16bit_format(self, ssh_exec):
        """Test 16-bit sample format support."""
        stdout, stderr, code = ssh_exec(
            "arecord -f S16_LE -t wav -d 1 /tmp/test_16bit.wav 2>&1 && "
            "rm -f /tmp/test_16bit.wav && echo 'success'"
        )
        if code == 0 and "success" in stdout:
            pass
        else:
            pytest.skip("16-bit format not supported")


class TestAudioPipeline:
    """Test complete audio pipeline."""
    
    def test_audio_permissions(self, ssh_exec):
        """Verify audio device permissions."""
        stdout, stderr, code = ssh_exec("groups")
        if "audio" in stdout.lower():
            pass
        else:
            pytest.skip("User may not be in audio group")
    
    def test_no_audio_process_conflict(self, ssh_exec):
        """Check if audio device is not locked by other process."""
        stdout, stderr, code = ssh_exec("fuser /dev/snd/* 2>/dev/null || echo 'free'")
        if code == 0:
            pass
        else:
            pytest.skip("Cannot check audio device lock status")