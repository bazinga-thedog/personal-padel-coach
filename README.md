# Personal Padel Coach - Flutter Mobile App

A beautiful Flutter mobile application for Android and iOS that features a text input field, a button, and toast message functionality.

## Features

- ✨ Modern and beautiful Material Design 3 UI
- 📱 Cross-platform support (Android & iOS)
- 📝 Text input field with multi-line support
- 🔘 Interactive button with visual feedback
- 🍞 Toast message functionality
- 🎨 Responsive design with shadows and animations
- 🎾 Padel-themed design elements

## Screenshots

The app features:
- A clean, modern interface with a padel-themed icon
- A text input field where users can enter their messages
- A prominent button to trigger the toast message
- Beautiful toast notifications that appear at the bottom of the screen
- Responsive design that works on different screen sizes

## Prerequisites

Before running this app, make sure you have:

1. **Flutter SDK** installed (version 3.0.0 or higher)
2. **Android Studio** (for Android development)
3. **Xcode** (for iOS development, macOS only)
4. **VS Code** or any other code editor

## Installation

1. **Clone or download this project**
   ```bash
   git clone <repository-url>
   cd personal-padel-coach
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**

   **For Android:**
   ```bash
   flutter run
   ```
   
   **For iOS (macOS only):**
   ```bash
   flutter run
   ```

## How to Use

1. **Launch the app** on your device or emulator
2. **Enter a message** in the text field (or leave it empty for a default message)
3. **Tap the "Show Toast Message" button**
4. **Watch the toast notification** appear at the bottom of the screen

## Project Structure

```
personal-padel-coach/
├── lib/
│   └── main.dart              # Main app entry point
├── android/                   # Android-specific files
├── ios/                      # iOS-specific files
├── pubspec.yaml              # Flutter dependencies
└── README.md                 # This file
```

## Dependencies

- `flutter`: The Flutter framework
- `cupertino_icons`: iOS-style icons
- `fluttertoast`: Toast message functionality

## Building for Production

**For Android APK:**
```bash
flutter build apk
```

**For Android App Bundle:**
```bash
flutter build appbundle
```

**For iOS:**
```bash
flutter build ios
```

## Customization

You can easily customize the app by modifying:

- **Colors**: Change the `ColorScheme.fromSeed(seedColor: Colors.blue)` in `main.dart`
- **Text**: Update the welcome messages and button text
- **Toast settings**: Modify the `Fluttertoast.showToast()` parameters
- **UI elements**: Adjust padding, margins, and styling

## Troubleshooting

**Common issues:**

1. **Flutter not found**: Make sure Flutter is installed and in your PATH
2. **Dependencies not found**: Run `flutter pub get`
3. **Build errors**: Try `flutter clean` then `flutter pub get`
4. **iOS build issues**: Make sure you have Xcode installed (macOS only)

## Contributing

Feel free to contribute to this project by:
- Adding new features
- Improving the UI/UX
- Fixing bugs
- Adding tests

## License

This project is open source and available under the MIT License.

---

**Enjoy your Personal Padel Coach app! 🎾📱** 