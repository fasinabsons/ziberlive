# DreamFlow Co-Living Management App - Installation Guide

## System Requirements

- Flutter SDK 3.19.0 or higher
- Dart 3.2.0 or higher
- Android Studio / VS Code with Flutter extensions
- For iOS development: macOS with Xcode 14.0+
- For Android development: Android SDK 33+
- For web development: Chrome browser

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/dreamflow-coliving.git
cd dreamflow-coliving
```

### 2. Install Dependencies

Run the following command to install all required dependencies:

```bash
flutter pub get
```

Alternatively, you can use our installation script:

```bash
chmod +x install_dependencies.sh
./install_dependencies.sh
```

### 3. Configure Environment

Create a `.env` file in the project root (if not already present):

```bash
FIREBASE_ENABLED=false
DEBUG_MODE=true
APP_NAME=DreamFlow
```

### 4. Run the App

#### For Web Development (Recommended for Testing)

```bash
flutter run -d chrome
```

#### For Android

```bash
flutter run -d android
```

#### For iOS

```bash
flutter run -d ios
```

#### For Desktop (Windows/macOS/Linux)

```bash
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## Troubleshooting

### Web Platform Issues

If you encounter issues with SQLite on web platform:

1. Make sure you're using the latest version of the app with the platform-agnostic LocalStorageService
2. Clear browser cache and local storage
3. Check browser console for any JavaScript errors

### Android Build Issues

If you encounter build issues on Android:

1. Make sure your Android SDK is up to date
2. Run `flutter clean` and try again
3. Check that your `android/app/build.gradle` has the correct minSdkVersion (21+)

### iOS Build Issues

If you encounter build issues on iOS:

1. Make sure your Xcode is up to date
2. Run `flutter clean` and try again
3. Check that your iOS deployment target is set to iOS 12.0 or higher

### Database Issues

If you encounter database-related errors:

1. Delete the app and reinstall to reset the database
2. For web, clear browser local storage
3. For mobile, uninstall and reinstall the app

## Development Tips

- Use the built-in sample data for testing
- The app uses a platform-agnostic storage solution that works on web, mobile, and desktop
- For web development, the app uses SharedPreferences instead of SQLite
- For mobile and desktop, the app uses SQLite for better performance and storage capabilities

## Getting Help

If you need further assistance, please:

1. Check the GitHub issues for known problems
2. Join our Discord community at [discord.gg/dreamflow](https://discord.gg/dreamflow)
3. Contact the development team at support@dreamflow.com

## Contributing

Please see CONTRIBUTING.md for guidelines on how to contribute to this project. 