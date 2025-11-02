# Configuration Integration Guide

This guide shows how to integrate the new centralized game configuration system into your Catastrophe Companion app.

## Overview

The new configuration system centralizes all game constants into a single `game_config.json` file, making it easy to update values without touching code. The system includes:

1. **game_config.json** - All game constants in one place
2. **GameConfig model** - Type-safe access to configuration
3. **GameConfigProvider** - State management for configuration
4. **Refactored components** - Updated providers and screens

## Files Created

- `/assets/game_config.json` - Central configuration file
- `/lib/models/game_config.dart` - Configuration model classes
- `/lib/providers/game_config_provider.dart` - Configuration provider
- `/lib/models/policy_data_refactored.dart` - Updated PolicyData using config
- `/lib/main_with_config.dart` - Updated main.dart with config integration
- `/lib/providers/policy_tracker_provider_refactored.dart` - Example provider update

## Step-by-Step Integration

### Step 1: Run Flutter Pub Get

After adding the new files, update dependencies:

```bash
flutter pub get
```

### Step 2: Update main.dart

Replace your current `main.dart` with the pattern shown in `main_with_config.dart`:

```dart
// Add GameConfigProvider import
import 'providers/game_config_provider.dart';

// Update MultiProvider to include GameConfigProvider first
providers: [
  ChangeNotifierProvider(create: (_) => GameConfigProvider()),
  // ... other providers
]

// Add ConfigLoader widget to handle loading state
home: const ConfigLoader(),
```

### Step 3: Update Providers

Each provider that uses game constants needs to be updated to use GameConfig:

#### PolicyTrackerProvider

```dart
class PolicyTrackerProvider extends ChangeNotifier {
  GameConfigProvider? _configProvider;

  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }

  // Replace hardcoded values with config lookups:
  int get growthTargetThreshold =>
    _configProvider?.growthTargetThreshold ?? 2;

  int getTotalPremium() {
    // Use _configProvider.getPremium(storm, property)
    // instead of PolicyData.policies lookup
  }
}
```

#### PayoutCalculatorProvider

```dart
class PayoutCalculatorProvider extends ChangeNotifier {
  GameConfigProvider? _configProvider;

  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }

  int calculatePayout(StormType storm, int hitCount) {
    return _configProvider?.getStormPayout(storm, hitCount) ?? 0;
  }

  // Hurricane Florida multiplier from config:
  int hurricaneFloridaPayout =
    otherPayout * (_configProvider?.hurricaneFloridaMultiplier ?? 2);
}
```

#### CardsProvider

```dart
class CardsProvider extends ChangeNotifier {
  GameConfigProvider? _configProvider;

  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }

  int getCardPoints(String cardType) {
    return _configProvider?.getCardPoints(cardType) ?? 0;
  }
}
```

#### InsolvencyCalculatorProvider

```dart
class InsolvencyCalculatorProvider extends ChangeNotifier {
  GameConfigProvider? _configProvider;

  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }

  void calculateInsolvency() {
    final constants = _configProvider?.insolvencyConstants;
    if (constants == null) return;

    // Use constants.d20Base instead of hardcoded 20
    // Use constants.d6Base instead of hardcoded 6
    // Use constants.probabilityThreshold instead of 0.0001
  }
}
```

### Step 4: Update Screens

Screens that directly access PolicyData constants should be updated:

```dart
// Old way:
final premium = PolicyData.policies
  .firstWhere((p) => p.storm == storm && p.property == property)
  .premium;

// New way using Provider:
final configProvider = Provider.of<GameConfigProvider>(context);
final premium = configProvider.getPremium(storm, property);
```

### Step 5: Update PolicyData References

Replace imports of the old PolicyData with the refactored version:

```dart
// Old:
import 'models/policy_data.dart';

// New:
import 'models/policy_data_refactored.dart';
```

## Configuration Structure

### Policy Configuration

Each policy has premium and victory points:

```json
"snow_mansion": {"premium": 9, "victoryPoints": -2}
```

### Storm Payouts

Array indexed by hit count (0 = no payout):

```json
"snow": [0, 5, 10, 15, 25]
```

### Storm Frequency (D20)

Number out of 20 for probability:

```json
"snow": 12  // 12/20 = 60% chance
```

### Storm Severity (D6)

Six values for D6 die faces:

```json
"snow": [5, 5, 5, 10, 10, 25]
```

### Game Thresholds

```json
"gameThresholds": {
  "growthTarget": 2,
  "agentOfTheYear": 6,
  "diversifiedAgentMinTypes": 7
}
```

## Updating Values

To change any game constant:

1. Edit `/assets/game_config.json`
2. Hot reload the app (the configuration will be reloaded automatically)
3. For production, rebuild the app

### Example: Changing Snow Premium

```json
// Before:
"snow_mansion": {"premium": 9, "victoryPoints": -2}

// After:
"snow_mansion": {"premium": 12, "victoryPoints": -3}
```

### Example: Adjusting Growth Target Threshold

```json
"gameThresholds": {
  "growthTarget": 3,  // Changed from 2
  "agentOfTheYear": 6
}
```

### Example: Modifying Storm Payouts

```json
// Add more payout tiers:
"snow": [0, 5, 10, 15, 25, 35, 45]
```

## Benefits

1. **Single Source of Truth** - All constants in one file
2. **No Code Changes** - Update values without touching source code
3. **Version Control** - Track configuration changes separately
4. **Easy Testing** - Swap configuration files for different game modes
5. **Hot Reload Support** - See changes immediately during development

## Testing Different Configurations

You can create multiple configuration files for different game modes:

- `game_config.json` - Standard game
- `game_config_easy.json` - Easier difficulty
- `game_config_tournament.json` - Tournament rules

Switch between them by changing the asset path in `GameConfig.load()`.

## Migration Checklist

- [ ] Copy new files to project
- [ ] Run `flutter pub get`
- [ ] Update `main.dart` with GameConfigProvider
- [ ] Update PolicyTrackerProvider
- [ ] Update PayoutCalculatorProvider
- [ ] Update CardsProvider
- [ ] Update InsolvencyCalculatorProvider
- [ ] Update screens that directly access PolicyData
- [ ] Test all features
- [ ] Verify calculations match previous values

## Rollback Plan

If you need to rollback:

1. Keep your original files as backups (`policy_data_original.dart`, etc.)
2. The refactored files are created as new files, not overwrites
3. Simply revert the imports and provider updates

## Future Enhancements

Consider these potential improvements:

1. **Remote Configuration** - Load config from a server
2. **User Profiles** - Different configs per player
3. **Config Validation** - Ensure values are within valid ranges
4. **Config Editor UI** - In-app configuration editing
5. **Export/Import** - Share configurations between devices