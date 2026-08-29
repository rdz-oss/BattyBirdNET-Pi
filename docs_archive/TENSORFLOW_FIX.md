# TensorFlow vs TFLite-Runtime - Python 3.13 Compatibility Fix

## The Problem

**Original Issue:**
- BattyBirdNET-Pi used `tflite-runtime` package
- `tflite-runtime` doesn't support Python 3.13 (latest Raspberry Pi OS Bookworm)
- Installation failed with: `ERROR: No matching distribution found for tflite-runtime`

## The Solution (from Nachtzuster/BirdNET-Pi)

**Nachtzuster's repository solved this by:**
- Replacing `tflite-runtime` with full `tensorflow` package
- TensorFlow 2.21.0+ supports Python 3.13
- Works on both ARM64 (Pi) and x86_64

### Updated requirements.txt

**Before:**
```
tflite-runtime
```

**After:**
```
tensorflow  # Full tensorflow, supports Python 3.13
```

## Why This Works

### tflite-runtime:
- ❌ Lightweight version of TensorFlow Lite
- ❌ Only for inference (running models)
- ❌ Not updated for Python 3.13
- ❌ ARM wheels not available for new Python versions

### tensorflow:
- ✅ Full TensorFlow package
- ✅ Supports Python 3.9-3.13
- ✅ ARM64 wheels available
- ✅ Can run TFLite models
- ✅ Larger download (~500MB vs ~50MB) but more compatible

## Implementation

### Files Changed:
1. `requirements.txt` - Replaced tflite-runtime with tensorflow
2. Updated other package versions to match Nachtzuster's repo

### Commands to Apply Fix:

```bash
# On your Pi:
cd ~/BattyBirdNET-Pi
source birdnet/bin/activate

# Remove old (if installed)
pip uninstall tflite-runtime

# Install tensorflow
pip install tensorflow

# Verify
python3 -c "import tensorflow as tf; print(f'TensorFlow {tf.__version__}')"
```

## Performance Impact

**TensorFlow vs TFLite-Runtime:**

| Metric | tflite-runtime | tensorflow |
|--------|----------------|------------|
| **Package Size** | ~50MB | ~500MB |
| **Install Time** | Fast | Slower |
| **Memory Usage** | Lower | Higher |
| **Inference Speed** | Same | Same |
| **Python 3.13** | ❌ No | ✅ Yes |
| **Compatibility** | Limited | Full |

**For Bat Detection:**
- Inference speed is essentially the same
- Memory difference is negligible on Pi 4 (4GB+ RAM)
- Disk space is cheap, compatibility is priceless

## Testing

After installing tensorflow:

```bash
# Test import
python3 -c "import tensorflow as tf; print('✓ TensorFlow works')"

# Test model loading
python3 -c "
import tensorflow as tf
interpreter = tf.lite.Interpreter(model_path='model/BATNET.tflite')
print('✓ Can load TFLite models')
"

# Run hardware tests
pytest tests/hardware/ -v
```

## References

- **Nachtzuster/BirdNET-Pi:** https://github.com/Nachtzuster/BirdNET-Pi
- **TensorFlow Python Support:** https://www.tensorflow.org/install/pip
- **Raspberry Pi OS Bookworm:** Uses Python 3.11/3.13

## Status

✅ **Fixed:** requirements.txt updated  
⏳ **Installing:** TensorFlow on Pi (may take 10-15 minutes)  
📝 **Next:** Test web interface, complete installation

---

**Summary:** Nachtzuster's repo uses `tensorflow` instead of `tflite-runtime` for Python 3.13 compatibility. We've adopted the same approach.
