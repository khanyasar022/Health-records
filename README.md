# PHR (Personal Health Record) App POC

A Flutter-based Proof of Concept application demonstrating key mobile features that would be used in a Personal Health Record (PHR) application. This application is designed to test these features on both iOS and Android platforms.

## Features

This POC app includes:

1. **QR Code Scanning**: Test scanning medical QR codes using device camera
2. **Push Notifications**: Test FCM push notifications and in-app notifications
3. **Location Access**: Test device location permissions and access
4. **PDF Report Handling**: Test viewing, generating, and mock uploading PDF health reports
5. **Camera Integration**: Test image capture, gallery selection, and mock uploading

## Setup Instructions

### Prerequisites

- Flutter SDK v3.7.2 or higher
- Android Studio or VS Code with Flutter extensions
- iOS development: macOS with Xcode 13+ (for iOS builds)
- Android development: Android SDK and emulator/device

### Getting Started

1. Clone the repository
   ```
   git clone [repository-url]
   cd phr_poc
   ```

2. Install dependencies
   ```
   flutter pub get
   ```

3. Run the app
   ```
   flutter run
   ```

### Firebase Configuration (for Push Notifications)

To fully test push notifications:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Register your app (iOS and Android) with Firebase
3. Download and add the configuration files:
   - For Android: `google-services.json` to `android/app/`
   - For iOS: `GoogleService-Info.plist` to `ios/Runner/`
4. Update iOS and Android native configuration based on Firebase documentation

## Testing the Features

### QR Code Scanner
- Navigate to the QR Scanner from the home screen
- Allow camera permissions when prompted
- Point camera at any QR code to scan
- For testing without a physical QR code, use the "Simulate Scan" button

### Notifications
- Navigate to Notifications screen
- Use "Send Test Notification" to test local notifications
- For push notifications, send a test message from Firebase console

### Location
- Navigate to Location screen
- Grant location permissions when prompted
- Tap "Get Current Location" to retrieve device coordinates

### PDF Handling
- Navigate to PDF screen
- Use "Generate PDF" to create a sample health report
- Use "Upload PDF" to select an existing PDF from device
- View, print, or share the PDF using provided options

### Camera
- Navigate to Camera screen
- Take photos using the built-in camera interface
- Select photos from the gallery
- Mock upload your selected images

## Notes

- This is a POC application intended for feature testing only
- No real data is stored or transmitted
- Some features like PDF sharing require additional plugins in a production app
- Firebase configuration is required for push notifications to work

## License

[Include your license information here]
