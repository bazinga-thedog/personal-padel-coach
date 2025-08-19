#!/usr/bin/env python3
"""
Simple VAD Model Creator for Flutter App
This script creates a basic TensorFlow model for voice activity detection
and converts it to TensorFlow Lite format.
"""

import tensorflow as tf
import numpy as np
import os

def create_simple_vad_model():
    """Create a simple VAD model for demonstration purposes."""
    
    # Create a simple model
    model = tf.keras.Sequential([
        tf.keras.layers.Input(shape=(1024,)),
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(256, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dense(1, activation='sigmoid')
    ])
    
    # Compile the model
    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    return model

def convert_to_tflite(model, output_path):
    """Convert the model to TensorFlow Lite format."""
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Optimize for mobile
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    # Convert
    tflite_model = converter.convert()
    
    # Save the model
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"Model saved to: {output_path}")

def main():
    """Main function to create and convert the VAD model."""
    
    print("Creating simple VAD model...")
    model = create_simple_vad_model()
    
    # Print model summary
    model.summary()
    
    # Convert to TFLite
    output_path = "vad_model.tflite"
    print(f"\nConverting to TensorFlow Lite...")
    convert_to_tflite(model, output_path)
    
    # Verify the model
    print(f"\nVerifying model...")
    interpreter = tf.lite.Interpreter(model_path=output_path)
    interpreter.allocate_tensors()
    
    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"Input shape: {input_details[0]['shape']}")
    print(f"Output shape: {output_details[0]['shape']}")
    
    # Test with dummy data
    test_input = np.random.random((1, 1024)).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    
    test_output = interpreter.get_tensor(output_details[0]['index'])
    print(f"Test output: {test_output[0][0]:.4f}")
    
    print(f"\n✅ VAD model created successfully!")
    print(f"📁 Model file: {output_path}")
    print(f"📱 Ready for Flutter app integration")

if __name__ == "__main__":
    main()
