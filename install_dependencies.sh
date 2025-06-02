#!/bin/bash

# DreamFlow Co-Living Management App - Installation Script

echo "=== DreamFlow Co-Living Management App - Installation Script ==="
echo "This script will install all dependencies and set up the app for development."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed. Please install Flutter first."
    echo "Visit https://flutter.dev/docs/get-started/install for instructions."
    exit 1
fi

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]\.[0-9]*\.[0-9]*" | cut -d ' ' -f 2)
REQUIRED_VERSION="3.19.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$FLUTTER_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Warning: Flutter version $FLUTTER_VERSION detected. This app requires Flutter $REQUIRED_VERSION or higher."
    read -p "Do you want to continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# Check if there were any errors
if [ $? -ne 0 ]; then
    echo "Error installing Flutter dependencies. Please check the error messages above."
    exit 1
fi

# Create necessary directories if they don't exist
echo "Creating necessary directories..."
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/animations

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOF
FIREBASE_ENABLED=false
DEBUG_MODE=true
APP_NAME=DreamFlow
EOF
fi

# Run Flutter doctor to check for issues
echo "Running Flutter doctor to check for issues..."
flutter doctor

# Success message
echo
echo "=== Installation Complete! ==="
echo "You can now run the app with one of the following commands:"
echo "  flutter run -d chrome    # For web"
echo "  flutter run -d android   # For Android"
echo "  flutter run -d ios       # For iOS"
echo
echo "For more information, see the INSTALLATION.md and PRODUCTION.md files."
 