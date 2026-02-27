# BlackCat - Package Delivery Tracker for iOS & Apple Watch

![](https://img.shields.io/badge/Platform-iOS%20%7C%20watchOS-blue.svg)
![](https://img.shields.io/badge/Xcode-26%2B-blue.svg)
![](https://img.shields.io/badge/Swift-5.0-orange.svg)
![](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![](https://img.shields.io/badge/License-MIT-green.svg)

A native iOS app for tracking package deliveries across major Japanese carriers — Yamato Transport, Sagawa Express, and Japan Post — all in one place. Built entirely with SwiftUI, Combine, and Apple-native frameworks. No third-party dependencies.

Available on the [App Store](https://apps.apple.com/jp/app/%E3%82%AF%E3%83%AD%E3%83%8D%E3%82%B3%E9%85%8D%E9%81%94%E7%8A%B6%E6%B3%81/id1585504785).

## Features

- **Multi-Carrier Tracking** — Track packages from Yamato (ヤマト運輸), Sagawa (佐川急便), and Japan Post (日本郵便) in a unified interface
- **Apple Watch App** — View delivery status directly from your wrist with watch complications support
- **Home Screen Widget** — Glance at your deliveries via a WidgetKit-powered widget
- **Background Refresh** — Automatically fetches updated delivery status at configurable intervals (15 min – 2 hr)
- **Push Notifications** — Get notified on status changes and delivery completion
- **Dark Mode** — Full support for both light and dark appearances
- **Zero Dependencies** — Built entirely with Apple-native frameworks

## Architecture

MVVM with Combine for reactive data binding. The codebase is organized into four targets:

```
BlackCat/                  # Main iOS app
├── Scenes/
│   ├── Splash/            # Launch screen
│   ├── DeliveryList/      # Main list of tracked packages
│   ├── AddList/           # Register a new tracking number
│   ├── StateDetail/       # Delivery status timeline
│   ├── Settings/          # Background refresh, notifications, display
│   ├── Onboarding/        # First-run experience
│   └── Help/              # FAQ
├── Models/                # DeliveryItem, DeliveryCarrier, DeliveryStatus
├── Utils/                 # BackgroundRefreshManager, NotificationManager
└── CommonViews/           # Reusable UI components

Domain/                    # Networking & API layer
├── APIProtocols/          # Generic API client, error handling
├── Endpoints/             # Carrier-specific request/response (Tneko, Sagawa, JapanPost)
└── DomainTests/           # Unit tests per carrier + API error tests

Shared/                    # Cross-target models
├── SharedDeliveryItem     # Common delivery model
├── SharedDataManager      # App Group data sync (iOS ↔ Widget ↔ Watch)
└── WatchDeliveryData      # Lightweight Codable model for WatchConnectivity

BlackCatWatch/             # watchOS companion app
├── Views/                 # Watch-optimized list & detail views
├── Complications/         # Watch face complications
└── Utils/                 # WatchConnectivityManager

BlackCarWidget/            # WidgetKit home screen widget
```

## Supported Carriers

| Carrier | Tracking Format | API |
|---|---|---|
| Yamato Transport (ヤマト運輸) | 12 digits | HTML scraping |
| Sagawa Express (佐川急便) | 12 digits | HTML scraping |
| Japan Post (日本郵便) | 11–13 digits / international (e.g. EA123456789JP) | REST API |

## Tech Stack

| Category | Technology |
|---|---|
| UI | SwiftUI |
| Reactive | Combine |
| Background | BGTaskScheduler |
| Notifications | UserNotifications |
| Widget | WidgetKit |
| Watch Sync | WatchConnectivity |
| Data Sharing | App Groups |
| Testing | XCTest |
| CI/CD | Fastlane |

## Getting Started

### Requirements

- Xcode 26 or later (recommended)
- iOS / watchOS deployment target: 26.0

### Build & Run

```bash
git clone https://github.com/tosh7/BlackCat.git
cd BlackCat
open BlackCat.xcodeproj
```

Select the `BlackCat` scheme and run on a simulator or device.

## Testing

```bash
xcodebuild test -project BlackCat.xcodeproj -scheme BlackCat -destination 'platform=iOS Simulator,name=iPhone 16'
```

Tests cover:
- Carrier API parsing (Tneko, Sagawa, Japan Post)
- ViewModel logic (DeliveryList, AddList, StateDetail)
- API error handling and HTTP method routing

## License

[MIT](license)

## Contact

- Email: zlia.6.lj.425@gmail.com
- Twitter: [tosh_3](https://twitter.com/tosh_3)
- LinkedIn: [Satoshi Komatsu](https://www.linkedin.com/in/satoshi-komatsu-5a8a4a220/)
