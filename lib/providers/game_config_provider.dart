import 'package:flutter/material.dart';
import '../models/game_config.dart';
import '../models/policy_data.dart';

/// Provider for managing centralized game configuration
class GameConfigProvider extends ChangeNotifier {
  GameConfig? _config;
  bool _isLoading = true;
  String? _error;

  GameConfig? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasConfig => _config != null;

  GameConfigProvider() {
    loadConfig();
  }

  /// Load the configuration from assets
  Future<void> loadConfig() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _config = await GameConfig.load();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load game configuration: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reload configuration (useful for hot reload during development)
  Future<void> reloadConfig() async {
    await loadConfig();
  }

  /// Get policy premium
  int getPremium(StormType storm, PropertyType property) {
    if (_config == null) return 0;
    return _config!.getPolicyConfig(storm, property)?.premium ?? 0;
  }

  /// Get policy victory points
  int getVictoryPoints(StormType storm, PropertyType property) {
    if (_config == null) return 0;
    return _config!.getPolicyConfig(storm, property)?.victoryPoints ?? 0;
  }

  /// Get storm payout for a specific hit count
  int getStormPayout(StormType storm, int hitCount) {
    if (_config == null) return 0;
    return _config!.getStormPayout(storm, hitCount);
  }

  /// Get maximum payout for a storm
  int getMaxPayout(StormType storm) {
    if (_config == null) return 0;
    final payouts = _config!.stormPayouts[_getStormKey(storm)];
    if (payouts == null || payouts.isEmpty) return 0;
    return payouts.reduce((a, b) => a > b ? a : b);
  }

  /// Get storm frequency (D20)
  int getStormFrequency(StormType storm) {
    if (_config == null) return 0;
    return _config!.getStormFrequency(storm);
  }

  /// Get storm severity values (D6)
  List<int> getStormSeverity(StormType storm) {
    if (_config == null) return [];
    return _config!.getStormSeverity(storm);
  }

  /// Get card victory points
  int getCardPoints(String cardType) {
    if (_config == null) return 0;

    // Check agent cards
    if (_config!.cards.agentCards.containsKey(cardType)) {
      return _config!.cards.agentCards[cardType]!;
    }

    // Check celebrity endorsements
    if (_config!.cards.celebrityEndorsements.containsKey(cardType)) {
      return _config!.cards.celebrityEndorsements[cardType]!;
    }

    // Check if it's a loan
    if (cardType == 'loan') {
      return _config!.cards.loan;
    }

    return 0;
  }

  /// Get growth target threshold
  int get growthTargetThreshold => _config?.thresholds.growthTarget ?? 2;

  /// Get agent of the year threshold
  int get agentOfTheYearThreshold => _config?.thresholds.agentOfTheYear ?? 6;

  /// Get diversified agent minimum types requirement
  int get diversifiedAgentMinTypes => _config?.thresholds.diversifiedAgentMinTypes ?? 7;

  /// Get Hurricane Florida multiplier
  int get hurricaneFloridaMultiplier => _config?.hurricaneFloridaMultiplier ?? 2;

  /// Get insolvency constants
  InsolvencyConstants? get insolvencyConstants => _config?.insolvency;

  String _getStormKey(StormType storm) {
    switch (storm) {
      case StormType.snow:
        return 'snow';
      case StormType.earthquake:
        return 'earthquake';
      case StormType.hurricaneOther:
        return 'hurricaneOther';
      case StormType.hurricaneFlorida:
        return 'hurricaneFlorida';
      case StormType.flood:
        return 'flood';
      case StormType.fire:
        return 'fire';
      case StormType.hail:
        return 'hail';
      case StormType.tornado:
        return 'tornado';
    }
  }
}