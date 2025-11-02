import 'dart:convert';
import 'package:flutter/services.dart';
import 'policy_data.dart';

/// Central configuration for all game constants and values
class GameConfig {
  // Policy configurations
  final Map<String, PolicyConfig> policies;

  // Storm payout tables (indexed by number of hits)
  final Map<String, List<int>> stormPayouts;

  // Storm frequency values (out of D20)
  final Map<String, int> stormFrequencyD20;

  // Storm severity values (D6 outcomes)
  final Map<String, List<int>> stormSeverityD6;

  // Card configurations
  final CardConfigs cards;

  // Game thresholds
  final GameThresholds thresholds;

  // Hurricane Florida multiplier
  final int hurricaneFloridaMultiplier;

  // Insolvency calculation constants
  final InsolvencyConstants insolvency;

  GameConfig({
    required this.policies,
    required this.stormPayouts,
    required this.stormFrequencyD20,
    required this.stormSeverityD6,
    required this.cards,
    required this.thresholds,
    required this.hurricaneFloridaMultiplier,
    required this.insolvency,
  });

  /// Load configuration from assets
  static Future<GameConfig> load() async {
    final String jsonString = await rootBundle.loadString('assets/game_config.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return GameConfig.fromJson(json);
  }

  /// Parse configuration from JSON
  factory GameConfig.fromJson(Map<String, dynamic> json) {
    // Parse policies
    final Map<String, PolicyConfig> policies = {};
    final policiesJson = json['policies'] as Map<String, dynamic>;
    policiesJson.forEach((key, value) {
      policies[key] = PolicyConfig.fromJson(value);
    });

    // Parse storm payouts
    final Map<String, List<int>> stormPayouts = {};
    final payoutsJson = json['stormPayouts'] as Map<String, dynamic>;
    payoutsJson.forEach((key, value) {
      stormPayouts[key] = (value as List).cast<int>();
    });

    // Parse storm frequency
    final Map<String, int> stormFrequency = {};
    final frequencyJson = json['stormFrequencyD20'] as Map<String, dynamic>;
    frequencyJson.forEach((key, value) {
      stormFrequency[key] = value as int;
    });

    // Parse storm severity
    final Map<String, List<int>> stormSeverity = {};
    final severityJson = json['stormSeverityD6'] as Map<String, dynamic>;
    severityJson.forEach((key, value) {
      stormSeverity[key] = (value as List).cast<int>();
    });

    return GameConfig(
      policies: policies,
      stormPayouts: stormPayouts,
      stormFrequencyD20: stormFrequency,
      stormSeverityD6: stormSeverity,
      cards: CardConfigs.fromJson(json['cards']),
      thresholds: GameThresholds.fromJson(json['gameThresholds']),
      hurricaneFloridaMultiplier: json['hurricaneFloridaMultiplier'],
      insolvency: InsolvencyConstants.fromJson(json['insolvencyConstants']),
    );
  }

  /// Helper method to get policy config by storm and property type
  PolicyConfig? getPolicyConfig(StormType storm, PropertyType property) {
    String key = _getPolicyKey(storm, property);
    return policies[key];
  }

  /// Helper to get payout for a storm at a specific hit count
  int getStormPayout(StormType storm, int hitCount) {
    String key = _getStormKey(storm);
    final payouts = stormPayouts[key];
    if (payouts == null || hitCount >= payouts.length) return 0;
    return payouts[hitCount];
  }

  /// Helper to get storm frequency (D20)
  int getStormFrequency(StormType storm) {
    String key = _getStormKey(storm);
    return stormFrequencyD20[key] ?? 0;
  }

  /// Helper to get storm severity values (D6)
  List<int> getStormSeverity(StormType storm) {
    String key = _getStormKey(storm);
    return stormSeverityD6[key] ?? [];
  }

  String _getPolicyKey(StormType storm, PropertyType property) {
    String stormKey = _getStormKey(storm);
    String propertyKey = _getPropertyKey(property);
    return '${stormKey}_$propertyKey';
  }

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

  String _getPropertyKey(PropertyType property) {
    switch (property) {
      case PropertyType.mansion:
        return 'mansion';
      case PropertyType.house:
        return 'house';
      case PropertyType.mobileHome:
        return 'mobileHome';
    }
  }
}

/// Configuration for a single policy type
class PolicyConfig {
  final int premium;
  final int victoryPoints;

  PolicyConfig({
    required this.premium,
    required this.victoryPoints,
  });

  factory PolicyConfig.fromJson(Map<String, dynamic> json) {
    return PolicyConfig(
      premium: json['premium'],
      victoryPoints: json['victoryPoints'],
    );
  }
}

/// Card configurations
class CardConfigs {
  final Map<String, int> agentCards;
  final Map<String, int> celebrityEndorsements;
  final int loan;

  CardConfigs({
    required this.agentCards,
    required this.celebrityEndorsements,
    required this.loan,
  });

  factory CardConfigs.fromJson(Map<String, dynamic> json) {
    final agentCards = Map<String, int>.from(json['agentCards']);
    final celebrityEndorsements = Map<String, int>.from(json['celebrityEndorsements']);

    return CardConfigs(
      agentCards: agentCards,
      celebrityEndorsements: celebrityEndorsements,
      loan: json['loan'],
    );
  }
}

/// Game threshold values
class GameThresholds {
  final int growthTarget;
  final int agentOfTheYear;
  final int diversifiedAgentMinTypes;

  GameThresholds({
    required this.growthTarget,
    required this.agentOfTheYear,
    required this.diversifiedAgentMinTypes,
  });

  factory GameThresholds.fromJson(Map<String, dynamic> json) {
    return GameThresholds(
      growthTarget: json['growthTarget'],
      agentOfTheYear: json['agentOfTheYear'],
      diversifiedAgentMinTypes: json['diversifiedAgentMinTypes'],
    );
  }
}

/// Insolvency calculation constants
class InsolvencyConstants {
  final int d20Base;
  final int d6Base;
  final int hurricaneCombinationBase;
  final double probabilityThreshold;

  InsolvencyConstants({
    required this.d20Base,
    required this.d6Base,
    required this.hurricaneCombinationBase,
    required this.probabilityThreshold,
  });

  factory InsolvencyConstants.fromJson(Map<String, dynamic> json) {
    return InsolvencyConstants(
      d20Base: json['d20Base'],
      d6Base: json['d6Base'],
      hurricaneCombinationBase: json['hurricaneCombinationBase'],
      probabilityThreshold: (json['probabilityThreshold'] as num).toDouble(),
    );
  }
}