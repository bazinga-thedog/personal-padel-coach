# ML VAD Model Setup

## Voice Activity Detection (VAD) Model

This directory should contain the TensorFlow Lite model for voice activity detection.

## Required File

- `vad_model.tflite` - TensorFlow Lite model for voice activity detection

## How to Get the Model

### Option 1: Use Pre-trained Model
Download a pre-trained VAD model from:
- [Silero VAD](https://github.com/snakers4/silero-vad) - High-quality VAD models
- [TensorFlow Hub](https://tfhub.dev/) - Various VAD models
- [Hugging Face](https://huggingface.co/) - Community models

### Option 2: Train Your Own Model
1. Collect audio data with voice/non-voice labels
2. Train a model using TensorFlow
3. Convert to TensorFlow Lite format
4. Optimize for mobile deployment

### Option 3: Use Placeholder (Development)
For development/testing, you can use a simple placeholder model or disable ML VAD.

## Model Requirements

- **Input**: 1024 audio samples (16kHz, normalized)
- **Output**: Single probability value [0, 1] for voice activity
- **Format**: TensorFlow Lite (.tflite)
- **Size**: Optimized for mobile (< 5MB recommended)

## Integration

The app will automatically:
1. Load the model on startup
2. Fall back to basic VAD if model fails to load
3. Use ML inference for enhanced voice detection
4. Handle model errors gracefully

## Performance Notes

- **iOS**: Optimized for iOS performance
- **Memory**: Efficient memory usage
- **Battery**: Minimal battery impact
- **Accuracy**: Professional-grade voice detection
