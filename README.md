# Personal Padel Coach

A Flutter application for personal padel coaching with voice recording capabilities.

## Features

- **Voice Recording**: Record voice for up to 5 seconds with automatic stop
- **Audio Playback**: Listen to recorded audio with progress tracking
- **Modern UI**: Beautiful, responsive interface with smooth animations
- **Cross-Platform**: Works on both Android and iOS
- **Permission Handling**: Automatic microphone permission requests

## Setup

### Prerequisites

- Flutter SDK (>=2.12.0)
- Android Studio / Xcode
- Android SDK (API level 21+) / iOS 11.0+

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Permissions

### Android
The app automatically requests the following permissions:
- `RECORD_AUDIO` - For voice recording
- `WRITE_EXTERNAL_STORAGE` - For saving recordings
- `READ_EXTERNAL_STORAGE` - For accessing recordings

### iOS
The app requests microphone access with the description:
"This app needs access to microphone to record voice for padel coaching sessions."

## Dependencies

- `record: ^5.0.4` - Audio recording functionality
- `audioplayers: ^5.2.1` - Audio playback
- `permission_handler: ^11.3.0` - Permission management
- `fluttertoast: ^8.2.4` - Toast notifications

## Usage

1. **Recording**: Tap the "Record (5s)" button to start recording. The app will automatically stop after 5 seconds.
2. **Playback**: Tap the "Play" button to listen to your recording. Tap "Stop" to stop playback.
3. **Notes**: Use the text field to add notes about your recording.
4. **Progress**: View recording duration and playback progress in real-time.

## Architecture

The app uses a stateful widget approach with:
- Audio recording and playback state management
- Permission handling
- Real-time UI updates
- Error handling with user-friendly messages

## Troubleshooting

- Ensure microphone permissions are granted
- For Android, make sure the app has storage permissions
- For iOS, check that microphone access is allowed in Settings
