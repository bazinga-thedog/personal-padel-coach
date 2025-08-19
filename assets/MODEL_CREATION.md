# Creating Your VAD Model

This directory contains everything you need to create a `vad_model.tflite` file for your Flutter app.

## Quick Start

### Option 1: Windows Batch File (Recommended)
1. Double-click `create_vad_model.bat`
2. Follow the prompts
3. The model will be created automatically

### Option 2: PowerShell Script
1. Right-click `create_vad_model.ps1`
2. Select "Run with PowerShell"
3. Follow the prompts

### Option 3: Manual Python Execution
1. Open command prompt in this directory
2. Run: `pip install -r requirements.txt`
3. Run: `python create_vad_model.py`

## Requirements

- **Python 3.8+** installed and in PATH
- **pip** package manager
- **Internet connection** for package downloads

## What Gets Created

The script will create:
- A simple neural network model for voice activity detection
- Convert it to TensorFlow Lite format
- Optimize it for mobile devices
- Save it as `vad_model.tflite`

## Model Specifications

- **Input**: 1024 audio samples (16kHz, normalized)
- **Output**: Single probability [0, 1] for voice activity
- **Architecture**: 3-layer dense neural network
- **Optimization**: FP16 quantization for mobile
- **Size**: ~100KB (very lightweight)

## Troubleshooting

### Python Not Found
- Install Python from https://python.org
- Ensure "Add to PATH" is checked during installation

### Package Installation Failed
- Try: `python -m pip install --upgrade pip`
- Then: `pip install -r requirements.txt`

### Model Creation Failed
- Check Python version: `python --version`
- Ensure TensorFlow 2.10+ is installed
- Check available disk space

## Alternative: Download Pre-trained Model

If you prefer not to create your own model:

1. Visit [Silero VAD](https://github.com/snakers4/silero-vad)
2. Download a pre-trained model
3. Convert to TensorFlow Lite format
4. Rename to `vad_model.tflite`
5. Place in the `assets/` folder

## Model Quality

**Note**: This creates a basic demonstration model. For production use:
- Train on real voice/non-voice audio data
- Use larger, more sophisticated architectures
- Validate on your specific use case
- Consider using pre-trained models for better accuracy

## Next Steps

After creating the model:
1. Ensure `vad_model.tflite` is in your `assets/` folder
2. Run `flutter pub get` to update dependencies
3. Test the ML VAD functionality in your app
4. Adjust thresholds and parameters as needed
