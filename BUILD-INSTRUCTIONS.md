# USAHome iOS App - Build Instructions

## Requirements
- **Xcode 14 or newer** (Xcode 15+ recommended)
- **macOS Big Sur or newer**
- **Apple Developer Account** (for device testing and App Store submission)

## Quick Start

1. **Open Project**
   - Double-click `USAHome.xcodeproj` in Finder
   - In Xcode, select the "USAHome" scheme

2. **Configure Signing**
   - Go to Project Settings → USAHome Target → Signing & Capabilities
   - Select your Apple Developer Team
   - Change Bundle Identifier to something unique (e.g., `com.yourcompany.usahome`)

3. **Build and Run**
   - Select a simulator (iPhone 15 Pro recommended) or connected device
   - Press Cmd+B to build
   - Press Cmd+R to run

## Features Included
- ✅ Native GPS location services
- ✅ Push notifications with custom actions
- ✅ WebView loading local HTML content (no internet required)
- ✅ JavaScript bridge for native feature access
- ✅ App Store ready configuration

## Troubleshooting
If the project doesn't open:
1. Make sure you have Xcode 14+ installed
2. Try: Product → Clean Build Folder
3. Restart Xcode completely

## Project Structure
- `AppDelegate.swift` - App lifecycle and notification setup
- `ViewController.swift` - Main WebView with JavaScript bridge
- `LocationService.swift` - GPS and location functionality
- `NotificationService.swift` - Push notification handling
- `www/` - Local web content (React app bundle)

This is a **hybrid app** that combines native iOS features with web content for fast development and easy maintenance.