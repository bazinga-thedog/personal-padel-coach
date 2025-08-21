# Personal Padel Coach

A React Native mobile application that shows a "Hello World" toast when a button is clicked.

## Features

- Cross-platform (iOS and Android)
- Simple button interaction with toast notification
- Modern UI design with React Native components
- TypeScript support

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (version 16 or higher)
- **npm** or **yarn**
- **React Native CLI** (`npm install -g @react-native-community/cli`)
- **Xcode** (for iOS development - macOS only)
- **Android Studio** (for Android development)
- **Java Development Kit (JDK)** version 11 or higher

## Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone <your-repo-url>
   cd personal-padel-coach
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

## Running the App

### iOS (macOS only)

1. **Install iOS dependencies**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Start the Metro bundler**:
   ```bash
   npm start
   ```

3. **Run on iOS simulator**:
   ```bash
   npm run ios
   ```

### Android

1. **Start the Metro bundler**:
   ```bash
   npm start
   ```

2. **Run on Android device/emulator**:
   ```bash
   npm run android
   ```

## Project Structure

```
personal-padel-coach/
├── App.tsx                 # Main application component
├── index.js               # Entry point
├── package.json           # Dependencies and scripts
├── metro.config.js        # Metro bundler configuration
├── babel.config.js        # Babel configuration
├── tsconfig.json          # TypeScript configuration
├── react-native.config.js # React Native configuration
├── ios/                   # iOS-specific files
│   └── PersonalPadelCoach/
│       ├── AppDelegate.h
│       ├── AppDelegate.mm
│       ├── main.m
│       ├── Info.plist
│       └── PersonalPadelCoach.xcodeproj/
└── android/               # Android-specific files
    └── app/
        └── src/
            └── main/
                ├── java/
                ├── res/
                └── AndroidManifest.xml
```

## How It Works

The app displays a simple interface with:
- A title "Personal Padel Coach"
- A subtitle welcoming users
- A blue button labeled "Click Me!"
- Instructions text

When the button is tapped, it triggers the `showHelloWorldToast` function which displays an alert dialog with "Hello World!" message.

## Building for Production

### iOS
1. Open the project in Xcode: `open ios/PersonalPadelCoach.xcworkspace`
2. Select your target device/simulator
3. Choose Product → Archive for release builds

### Android
1. Generate a signed APK:
   ```bash
   cd android
   ./gradlew assembleRelease
   ```

## Troubleshooting

### Common Issues

1. **Metro bundler issues**: Try clearing the cache:
   ```bash
   npm start -- --reset-cache
   ```

2. **iOS build issues**: Clean the build folder in Xcode (Product → Clean Build Folder)

3. **Android build issues**: Clean the project:
   ```bash
   cd android
   ./gradlew clean
   ```

4. **Dependencies issues**: Delete node_modules and reinstall:
   ```bash
   rm -rf node_modules
   npm install
   ```

### Platform-Specific Issues

- **iOS**: Ensure Xcode is up to date and you have the latest iOS SDK
- **Android**: Make sure you have the correct Android SDK versions installed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both platforms
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue in the repository.
