# USA Home Center - iOS App

This is the iOS application for USA Home Center, a professional services marketplace connecting homeowners with qualified service providers.

## App Features

- **Hybrid Native iOS App**: Combines native iOS functionality with WebView for React content
- **GPS Location Services**: Native location detection for finding nearby professionals
- **Push Notifications**: Real-time notifications for appointments and messages
- **Native Sharing**: Share professional profiles using iOS native sharing
- **Professional Marketplace**: Browse Build, Design, and Finance professionals

## Project Structure

- `USAHome/` - Main iOS application source code
  - `ViewController.swift` - Main view controller with WebView
  - `SceneDelegate.swift` - Scene lifecycle management
  - `AppDelegate.swift` - Application lifecycle and notification handling
  - `LocationService.swift` - GPS location services
  - `NotificationService.swift` - Push notification management
  - `Assets.xcassets/` - App icons and images
  - `www/` - React web content served in WebView

## Technical Details

- **Target iOS Version**: iOS 13.0+
- **Bundle ID**: com.usahome.center
- **App Name**: USAHome
- **Architecture**: Swift 5+ with WKWebView integration

## Build Instructions

1. Open `USAHome.xcodeproj` in Xcode
2. Select your development team in signing settings
3. Build and run on device or simulator
4. The app loads the React web content from the integrated www folder

## App Store Submission

This project is ready for App Store submission with:
- ✅ All required app icons (20px to 1024px)
- ✅ Launch screens and storyboards
- ✅ Proper Info.plist configuration
- ✅ Native iOS functionality
- ✅ Network security settings for web content

## Contact

For questions about this iOS application, please contact the development team.
