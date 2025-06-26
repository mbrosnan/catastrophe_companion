# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Catastrophe Companion is a Flutter mobile app companion for a board game where players act as insurance companies. The app helps track policies, calculate premiums/victory points, and manage game state.

Key features:
- Policy tracker for 24 policy types (8 storm types × 3 property types)
- Payout calculator for storm events
- Victory point tracking from cards
- Insolvency calculator
- Map configuration tool

Target platforms: Android (primary), iOS, tablets, and web.

## Common Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app (ensure device/emulator is connected)
flutter run

# Build for platforms
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build ios          # iOS (requires macOS with Xcode)
flutter build web          # Web

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
dart format .

# Run a specific test file
flutter test test/widget_test.dart

# Clean build artifacts
flutter clean
```

## Architecture & Code Structure

The app follows a tabbed navigation pattern with these main screens:
1. **Tracker Tab** - Manages policy counts and calculates totals
2. **Payout Calculator** - Calculates storm payout amounts
3. **Cards Tab** - Tracks victory point cards
4. **Insolvency Calculator** - Risk analysis tool
5. **Map Configuration** - Board setup tool
6. **Settings** - App configuration

### Data Model

Core data types to implement:
- **Policy**: Combination of StormType (8 types) and PropertyType (3 types)
- **PolicyCount**: Tracks quantity of each policy type
- **Card**: Victory point cards with checkbox state
- **StormPayout**: Payout calculations per storm type

Storm types with colors:
1. Snow (white)
2. Earthquake (brown)
3. Hurricane-Other (lavender)
4. Flood (blue)
5. Fire (red)
6. Hail (yellow)
7. Tornado (grey)
8. Hurricane-Florida (purple)

Property types: Mansion, House, Mobile Home

### State Management

The app requires persistent state for:
- Policy counts (24 values)
- Card selections
- User settings

Consider using Provider, Riverpod, or similar for state management across tabs.

## Implementation Priority

1. **Core MVP** (must have):
   - Tracker tab with policy management
   - Payout calculator
   - Cards tab
   - Android build

2. **Secondary** (important):
   - Insolvency calculator
   - iOS build

3. **Tertiary** (nice to have):
   - Map configuration
   - Web build and deployment

## Development Guidelines

- Use Material Design for UI components
- Design for flexibility in theming/animations
- Maintain color consistency for storm types
- Test on both phones and tablets
- Ensure data persists across app sessions
- Show popups when policy thresholds are reached