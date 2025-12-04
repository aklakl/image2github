# Image2GitHub

A Flutter mobile application that allows you to browse your GitHub repositories and upload images directly to them.

## Features

- 📱 Browse all your GitHub repositories
- 📁 Browse repository files and folders
- 👁️ View file contents with syntax highlighting for code
- 🖼️ View images with zoom and pan support
- 📋 Copy file paths to clipboard
- 🎯 Quick path selection from browse mode to upload screen
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
2. Clear Gradle cache `rm -rf ~/.gradle/caches/`  and`flutter clean` 
3. Run `flutter clean && flutter pub get` to install dependencies
4. Update the GitHub credentials in `lib/config/constants.dart` with your information
5. Run the app using `flutter run` or `flutter run -d chrome --web-port=3000` for web
6. Build APK => `flutter build apk --debug`

`$env:GRADLE_USER_HOME = 'D:\.gradle_home'; flutter clean; flutter build apk --debug --verbose`

## Usage

### Basic Image Upload

1. Launch the app to see your list of GitHub repositories
2. Tap on a repository to open the upload screen
3. Tap the image picker to select an image from your device
4. Enter the target path in the repository (e.g., `images/logo.png`)
5. Tap "Upload to GitHub" to upload the image

### Method 1: Browse and Select Path from Upload Screen

1. In the repository upload screen, tap the "Browse Files" button
2. Browse through files and folders
3. Find the target path where you want to upload
4. Tap the green "Upload" icon 📤 next to a file
5. The path is automatically copied to the "Target Path in Repository" input field

### Method 2: View File Contents

1. In any file browsing interface, tap the "View" icon 👁️ next to a file
2. For code files:
   - View code with syntax highlighting
   - Toggle between dark/light themes using the button in the top-right
   - Select and copy code as needed
3. For image files:
   - Pinch to zoom and view images
   - Double-tap to reset zoom

### Method 3: Copy File Paths

- Tap the "Copy" icon 📋 next to any file
- Path is copied to clipboard
- Manually paste wherever needed

## New Features

### 1. File Content Viewer

A new `FileViewerScreen` supports viewing various file types:

#### Code File Viewing Mode
- ✅ Syntax highlighting for multiple programming languages:
  - Dart, Java, Kotlin, Swift
  - JavaScript, TypeScript, Python, Ruby, Go, Rust
  - C, C++, C#, PHP
  - HTML, XML, CSS, SCSS
  - JSON, YAML, Markdown
  - SQL, Bash, Gradle
  - And more...
- ✅ Dark/Light theme toggle
- ✅ Display line numbers and language type
- ✅ Support for text selection and copying

#### Image File Viewing Mode
- ✅ Support for common image formats: PNG, JPG, JPEG, GIF, WebP, BMP, SVG
- ✅ Zoom and pan functionality (InteractiveViewer)
- ✅ Display file size
- ✅ Loading progress indicator

### 2. Path Copy to Upload Screen

When accessing file browser from repository details page:

- ✅ "Upload" button (green icon) displayed next to each file
- ✅ Automatically copies path and returns to upload screen when clicked
- ✅ Path auto-fills into "Target Path in Repository" input field
- ✅ "Upload using this path" button also available in file viewer

### 3. Enhanced File Browser Interface

- ✅ "View" button (👁️ icon) added for each file
- ✅ Original "Copy Path" button retained
- ✅ Additional "Upload" button shown when opened from upload screen
- ✅ Clicking on file row also opens the viewer directly

## Technical Highlights

- **Syntax Highlighting**: Uses `flutter_highlight` package for professional code highlighting
- **Image Interaction**: Uses `InteractiveViewer` for smooth zoom and pan
- **State Management**: Data passed between screens via callback functions
- **User Experience**: 
  - Multiple operation methods for different use cases
  - Clear icons and tooltips
  - Smooth navigation experience
  - Auto-fill paths to reduce manual input

## Implementation Details

### New Files
1. **`lib/screens/file_viewer_screen.dart`** - File viewer screen
   - Supports both code and image viewing modes
   - Syntax highlighting
   - Zoom functionality

### Modified Files
1. **`lib/screens/repo_files_screen.dart`**
   - Added `fromUploadScreen` parameter
   - Added `onPathSelected` callback
   - Updated file tap handling logic
   - Added view and upload buttons

2. **`lib/screens/image_upload_screen.dart`**
   - Updated browse files button with upload screen identifier
   - Added path selection callback for auto-filling paths

3. **`pubspec.yaml`**
   - Added `flutter_highlight: ^0.7.0` dependency

## Compatibility

- ✅ Supports Flutter 3.0.0+
- ✅ Supports Android and iOS
- ✅ Supports Web platform
- ✅ Backward compatible, doesn't affect existing features

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
