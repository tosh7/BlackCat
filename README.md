# BlackCat - 配達状況追跡アプリ
![](https://img.shields.io/badge/Xcode-14.2%2B-blue.svg)
![](https://img.shields.io/badge/iOS-16.0%2B-blue.svg)
![](https://img.shields.io/badge/Swift-5.7%2B-orange.svg)

Welcome to BlackCat's open source iOS app! Come on in, take your shoes off, stay a while - explore how BlackCat's native squad has built and continues to build the app.
This is a 配達状況追跡アプリ's repository. Available at the [App Store](https://apps.apple.com/jp/app/%E3%82%AF%E3%83%AD%E3%83%8D%E3%82%B3%E9%85%8D%E9%81%94%E7%8A%B6%E6%B3%81/id1585504785).

## What you can do with BlackCat

Track your package deliveries from multiple Japanese carriers:

### Supported Carriers

| Carrier | Japanese Name | Tracking Number Format |
|---------|---------------|------------------------|
| Yamato Transport | ヤマト運輸 | 12 digits (starts with 1-4) |
| Sagawa Express | 佐川急便 | 12 digits (starts with 5-7) |
| Japan Post | 日本郵便 | 11-13 digits or international format (e.g., EA123456789JP) |

### Key Features

- **Multi-Carrier Support**: Track packages from Yamato, Sagawa, and Japan Post in one app
- **Automatic Carrier Detection**: Just enter your tracking number - the app automatically identifies the carrier
- **Real-time Status Updates**: Get the latest delivery status with a single tap
- **Home Screen Widget**: Quick glance at your deliveries without opening the app
- **Push Notifications**: Get notified when your package status changes
- **Dark Mode Support**: Beautiful interface in both light and dark modes

## Getting Started

1. Install Xcode (Xcode 14.2 or later recommended)
2. Clone this repository
   ```bash
   git clone https://github.com/tosh7/BlackCat.git
   ```
3. Open `BlackCat.xcodeproj` in Xcode
4. Build and run on your device or simulator

## Architecture

The app follows MVVM architecture with Combine for reactive programming:

```
BlackCat/
├── Models/           # Data models (DeliveryCarrier, DeliveryItem, etc.)
├── Scenes/           # Views and ViewModels
│   ├── AddList/      # Package registration screen
│   ├── DeliveryList/ # Main delivery list screen
│   └── StateDetail/  # Delivery status detail screen
├── Utils/            # Extensions and utilities
└── CommonViews/      # Reusable UI components

Domain/
├── APIProtocols/     # API client and error handling
└── Endpoints/        # Request/Response models (Tneko, Sagawa)
```

## Dependencies

No third-party libraries are used. All frameworks are provided by Apple:
- SwiftUI
- Combine
- WidgetKit
- UserNotifications

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## License

MIT License

## Contact

- Email: zlia.6.lj.425@gmail.com
- Twitter: [tosh_3](https://twitter.com/tosh_3)
- LinkedIn: [Satoshi Komatsu](https://www.linkedin.com/in/satoshi-komatsu-5a8a4a220/)
