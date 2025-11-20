# Image2GitHub

A Flutter mobile application that allows you to browse your GitHub repositories and upload images directly to them.

## Features

- 📱 Browse all your GitHub repositories
- 🖼️ Select images from your device gallery
- ⬆️ Upload images to any repository
- 🔄 Replace existing images with the same filename
- ✨ Modern, beautiful Material Design UI

## Setup

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode for platform development
- A GitHub account and personal access token

### Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Update the GitHub credentials in `lib/config/constants.dart` with your information
4. Run the app using `flutter run`

## Usage

1. Launch the app to see your list of GitHub repositories
2. Tap on a repository to open the upload screen
3. Tap the image picker to select an image from your device
4. Enter the target path in the repository (e.g., `images/logo.png`)
5. Tap "Upload to GitHub" to upload the image

## Configuration

Update your GitHub credentials in `lib/config/constants.dart`:

```dart
static const String githubUsername = 'your-username';
static const String githubToken = 'your-personal-access-token';
```

## Permissions

### Android
- Internet access
- Camera access
- Storage read/write access

### iOS
- Camera usage
- Photo library access

## License

MIT License
