# PowerShell script to create VAD Model for Flutter App

Write-Host "Creating VAD Model for Flutter App..." -ForegroundColor Green
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python found: $pythonVersion" -ForegroundColor Yellow
} catch {
    Write-Host "ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.8+ from https://python.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if pip is available
try {
    $pipVersion = pip --version 2>&1
    Write-Host "pip found: $pipVersion" -ForegroundColor Yellow
} catch {
    Write-Host "ERROR: pip is not available" -ForegroundColor Red
    Write-Host "Please ensure pip is installed with Python" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Installing required packages..." -ForegroundColor Cyan
pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install required packages" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Creating VAD model..." -ForegroundColor Cyan
python create_vad_model.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create VAD model" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Moving model to assets folder..." -ForegroundColor Cyan
Move-Item -Path "vad_model.tflite" -Destination "..\vad_model.tflite" -Force

Write-Host ""
Write-Host "✅ VAD model created successfully!" -ForegroundColor Green
Write-Host "📁 Model file: vad_model.tflite" -ForegroundColor Yellow
Write-Host "📱 Ready for Flutter app integration" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to exit"
