@echo off
echo Creating VAD Model for Flutter App...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)

REM Check if pip is available
pip --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: pip is not available
    echo Please ensure pip is installed with Python
    pause
    exit /b 1
)

echo Installing required packages...
pip install -r requirements.txt

if errorlevel 1 (
    echo ERROR: Failed to install required packages
    pause
    exit /b 1
)

echo.
echo Creating VAD model...
python create_vad_model.py

if errorlevel 1 (
    echo ERROR: Failed to create VAD model
    pause
    exit /b 1
)

echo.
echo Moving model to assets folder...
move vad_model.tflite ..\vad_model.tflite

echo.
echo ✅ VAD model created successfully!
echo 📁 Model file: vad_model.tflite
echo 📱 Ready for Flutter app integration
echo.
pause
