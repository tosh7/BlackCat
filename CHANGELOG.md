# Changelog

All notable changes to BlackCat will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2025-07-06

### New Features

#### Multi-Carrier Support
- **Sagawa Express (佐川急便) API Integration**: Added full support for tracking packages from Sagawa Express
  - New `SagawaRequest` and `Sagawa` response models with HTML parsing
  - Completion handlers, async/await, and Combine Future support
  - Comprehensive unit tests for Sagawa API client

- **Japan Post (日本郵便) Support**: Added tracking capability for Japan Post packages
  - Support for domestic packages (11-13 digits)
  - Support for international mail format (e.g., EA123456789JP)

- **DeliveryCarrier Model**: New unified carrier model (`BlackCat/Models/DeliveryCarrier.swift`)
  - Carrier enumeration: Yamato, Sagawa, Japan Post
  - Brand colors and SF Symbol icons for each carrier
  - Tracking URL generation for each carrier's website
  - Carrier-specific tracking number validation

#### Automatic Carrier Detection
- **Smart Tracking Number Detection**: Automatically identifies carrier from tracking number pattern
  - Yamato: Numbers starting with 1-4 (12 digits)
  - Sagawa: Numbers starting with 5-7 (12 digits)
  - Japan Post: 11-13 digits or international format
  - Real-time detection feedback with confidence scoring
  - Support for multiple candidates when pattern is ambiguous

#### Enhanced UI/UX
- **Modernized AddListView**: Complete redesign of the package registration screen
  - New carrier selection cards with brand colors
  - Modern text field with validation indicators
  - Shake animation for invalid input
  - Success overlay animation
  - Barcode scan button (UI ready)
  - Improved accessibility support with VoiceOver

- **Widget Improvements**: Enhanced home screen widget
  - Dark mode support for widget background
  - Improved delivery status display

### Improvements

- **AddListViewModel**: Enhanced input validation
  - Debounced carrier auto-detection (300ms)
  - Carrier-specific tracking number format validation
  - Support for international postal format validation
  - Improved error messaging

- **Color Extensions**: Added new design system colors
  - Primary gradients and accent colors
  - Background variants for cards and sections
  - Shadow levels for depth effects

- **Notification Extensions**: New notification name extensions for app-wide events

### Bug Fixes

- Fixed layout issues in delivery list view
- Improved empty state handling for API calls

### Security

- Updated fastlane and dependencies to resolve security vulnerabilities
- Updated rexml and webrick gems for security patches

### Technical Improvements

- Extended APIClient with Sagawa endpoint support
- Enhanced APIError handling with more descriptive error types
- Added HapticManager integration for tactile feedback
- Improved Combine pipeline for reactive state management

---

## [1.1.0] - Previous Release

- Initial multi-carrier groundwork
- Core tracking functionality for Yamato Transport

---

## Notes for Reviewers

### Code Quality Observations

1. **Print Statements**: Debug print statements exist in `BackgroundRefreshManager.swift` and `NotificationManager.swift`. These are intentional for background task debugging but should be wrapped in `#if DEBUG` blocks for production.

2. **Unused Variable**: In `Domain/Endpoints/Sagawa.swift` line 67, the `index` variable in the for loop is unused. Consider using `for line in lines` or `for (_, line) in lines.enumerated()`.

3. **TODO/FIXME Comments**: No TODO or FIXME comments found in the codebase.

### Files Changed

- 27 files modified
- ~5,000 lines added
- ~300 lines removed

### New Files

- `BlackCat/Models/DeliveryCarrier.swift` - Carrier enumeration and detection logic
- `Domain/Endpoints/Sagawa.swift` - Sagawa API models and parser
- `DomainTests/SagawaTests.swift` - Unit tests for Sagawa API
