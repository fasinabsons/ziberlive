# DreamFlow Co-Living Management App - Production Guide

This guide outlines the steps needed to prepare the DreamFlow Co-Living Management App for production deployment.

## Pre-Production Checklist

Before releasing to production, ensure you have completed the following:

- [ ] All critical bugs are fixed
- [ ] Performance testing has been completed
- [ ] Security audit has been performed
- [ ] Data privacy compliance has been verified
- [ ] All UI/UX elements are polished
- [ ] App has been tested on all target platforms
- [ ] Documentation is complete and up-to-date

## Configuration Updates

### 1. Update Config Settings

Edit `lib/config.dart` to set production values:

```dart
// Change debug mode to false
const bool kDebugMode = false;

// Disable debug banner
const bool kShowDebugBanner = false;

// Set production API endpoints
const String kApiBaseUrl = 'https://api.dreamflow.com/v1';

// Enable Firebase for production
const bool kUseFirebase = true;
```

### 2. Update App Information

Update the app information in `pubspec.yaml`:

```yaml
name: dreamflow_coliving
description: A comprehensive co-living management solution
version: 1.0.0+1
```

### 3. Firebase Configuration

Ensure you have separate Firebase projects for development and production:

1. Create a production Firebase project
2. Download and replace the configuration files:
   - For Android: `google-services.json` to `android/app/`
   - For iOS: `GoogleService-Info.plist` to `ios/Runner/`
3. Enable necessary Firebase services (Authentication, Storage, Messaging, etc.)
4. Set up Firebase Analytics for production monitoring

## Platform-Specific Preparations

### Android

1. Update the package name in `android/app/build.gradle`:

```gradle
defaultConfig {
    applicationId "com.dreamflow.coliving"
    minSdkVersion 21
    targetSdkVersion 33
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

2. Generate a signing key:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

3. Configure signing in `android/app/build.gradle` and `android/key.properties`

4. Update app icons in `android/app/src/main/res/`

5. Update `AndroidManifest.xml` with necessary permissions and metadata

### iOS

1. Update the bundle identifier in Xcode

2. Configure App Store Connect with the appropriate information

3. Update app icons in Xcode

4. Configure signing certificates and provisioning profiles

5. Update `Info.plist` with necessary permissions and metadata

### Web

1. Update the web app manifest in `web/manifest.json`

2. Configure proper meta tags in `web/index.html`

3. Update web app icons in `web/icons/`

4. Configure service workers for offline capabilities

## Building for Production

### Android

```bash
# Generate an app bundle (recommended for Play Store)
flutter build appbundle --release

# OR generate an APK
flutter build apk --release

# Generate split APKs for different architectures
flutter build apk --split-per-abi --release
```

### iOS

```bash
# Build iOS release
flutter build ios --release

# Then open Xcode to archive and upload to App Store
open ios/Runner.xcworkspace
```

### Web

```bash
# Build web release
flutter build web --release --web-renderer canvaskit

# For better performance on mobile web, use html renderer
flutter build web --release --web-renderer html
```

## Deployment

### Android

1. Upload the app bundle to Google Play Console
2. Fill in all required information (descriptions, screenshots, etc.)
3. Configure pricing and distribution
4. Submit for review

### iOS

1. Use Xcode to archive and upload the build to App Store Connect
2. Fill in all required information in App Store Connect
3. Configure pricing and availability
4. Submit for review

### Web

1. Deploy the contents of the `build/web` directory to your web hosting service
2. Configure proper caching headers for static assets
3. Set up HTTPS for secure connections
4. Configure custom domain if needed

## Post-Deployment

### Monitoring

1. Set up Firebase Crashlytics to monitor app crashes
2. Configure Firebase Analytics to track user behavior
3. Set up performance monitoring
4. Create dashboards for key metrics

### Updates

1. Plan for regular updates and bug fixes
2. Set up CI/CD pipeline for automated builds and testing
3. Prepare communication channels for user feedback
4. Document the update process for future reference

### Support

1. Set up support channels (email, chat, etc.)
2. Create a knowledge base for common issues
3. Train support staff on the app's functionality
4. Implement a feedback collection system

## Security Considerations

1. Regularly update dependencies to patch security vulnerabilities
2. Implement proper data encryption for sensitive information
3. Use secure authentication methods
4. Perform regular security audits
5. Have a plan for security incidents

## Compliance

1. Ensure GDPR compliance for European users
2. Implement proper privacy policy and terms of service
3. Obtain necessary consents for data collection
4. Provide data export and deletion mechanisms
5. Comply with local regulations in target markets 