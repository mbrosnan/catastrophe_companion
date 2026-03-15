import 'package:flutter/material.dart';

enum StormType {
  snow,
  flood,
  hail,
  hurricaneOther,
  fire,
  tornado,
  hurricaneFlorida,
  fireCalifornia,
  tornadoTexas,
}

enum PropertyType {
  mansion,
  house,
  mobileHome,
}

class PolicyData {
  static const Map<StormType, String> stormNames = {
    StormType.snow: 'Snow',
    StormType.flood: 'Flood',
    StormType.hail: 'Hail',
    StormType.hurricaneOther: 'Hurricane',
    StormType.fire: 'Fire',
    StormType.tornado: 'Tornado',
    StormType.hurricaneFlorida: 'Florida',
    StormType.fireCalifornia: 'California',
    StormType.tornadoTexas: 'Texas',
  };

  /// Maps state-specific storm types to their parent base storm type.
  /// Used for card thresholds (Growth Target, Agent of Year, Diversified).
  static const Map<StormType, StormType> parentStormTypes = {
    StormType.hurricaneFlorida: StormType.hurricaneOther,
    StormType.fireCalifornia: StormType.fire,
    StormType.tornadoTexas: StormType.tornado,
  };

  /// The 6 base storm types (not including state-specific variants).
  static const List<StormType> baseStormTypes = [
    StormType.snow,
    StormType.flood,
    StormType.hail,
    StormType.hurricaneOther,
    StormType.fire,
    StormType.tornado,
  ];

  /// The 3 state-specific storm types.
  static const List<StormType> stateStormTypes = [
    StormType.hurricaneFlorida,
    StormType.fireCalifornia,
    StormType.tornadoTexas,
  ];

  static const Map<StormType, Color> stormColors = {
    StormType.snow: Color(0xFF02A9F4),
    StormType.flood: Color(0xFF1A4784), // Dark royal blue (KC Royals)
    StormType.hail: Color(0xFFFFEB3B),
    StormType.hurricaneOther: Color(0xFFE6E6FA), // Lavender
    StormType.fire: Colors.red,
    StormType.tornado: Colors.grey,
    StormType.hurricaneFlorida: Colors.purple,
    StormType.fireCalifornia: Color(0xFFB71C1C), // Darker red
    StormType.tornadoTexas: Color(0xFF424242), // Darker grey
  };

  // Custom background colors for storms that need different background than text
  static const Map<StormType, Color> stormBackgroundColors = {
    StormType.snow: Color(0xFF424242), // Dark grey
    StormType.hurricaneOther: Color(0xFF424242), // Dark grey
  };

  static const Map<PropertyType, String> propertyNames = {
    PropertyType.mansion: 'Mansion',
    PropertyType.house: 'House',
    PropertyType.mobileHome: 'Mobile Home',
  };

  // NOTE: Game configuration values (payouts, premiums, victory points, etc.)
  // have been moved to assets/game_config.json and are accessed via GameConfigProvider.
  // Only UI-related constants (colors, display names) remain here.

  // DEPRECATED: These values are kept for backward compatibility only.
  // New code should use GameConfigProvider instead.
  static const Map<StormType, List<int>> stormPayouts = {
    StormType.snow: [0, 5, 10, 25],
    StormType.hurricaneOther: [0, 5, 15, 25, 30, 35, 40],
    StormType.flood: [0, 10, 15, 20, 25, 30],
    StormType.fire: [0, 15, 30, 45],
    StormType.hail: [0, 15, 20, 25],
    StormType.tornado: [0, 25, 30, 35],
    StormType.hurricaneFlorida: [0, 5, 15, 25, 30, 35, 40], // Uses base hurricane + addition
    StormType.fireCalifornia: [0, 15, 30, 45], // Uses base fire + addition
    StormType.tornadoTexas: [0, 25, 30, 35], // Uses base tornado + addition
  };

  // DEPRECATED: Use GameConfigProvider.getStormFrequency() instead
  static const Map<StormType, int> stormOccurrenceD20 = {
    StormType.snow: 10,
    StormType.hurricaneOther: 4,
    StormType.hurricaneFlorida: 4,
    StormType.flood: 5,
    StormType.fire: 4,
    StormType.hail: 7,
    StormType.tornado: 6,
    StormType.fireCalifornia: 4, // Same as fire
    StormType.tornadoTexas: 6, // Same as tornado
  };

  // DEPRECATED: Use GameConfigProvider.getStormSeverity() instead
  static const Map<StormType, List<int>> stormSeverityD6 = {
    StormType.snow: [5, 5, 5, 10, 10, 25],
    StormType.hurricaneOther: [5, 15, 25, 30, 35, 40],
    StormType.hurricaneFlorida: [5, 15, 25, 30, 35, 40], // Base hurricane severity
    StormType.flood: [10, 15, 20, 20, 25, 30],
    StormType.fire: [15, 15, 30, 30, 45, 45],
    StormType.hail: [15, 15, 20, 20, 25, 25],
    StormType.tornado: [25, 25, 30, 30, 35, 35],
    StormType.fireCalifornia: [15, 15, 30, 30, 45, 45], // Base fire severity
    StormType.tornadoTexas: [25, 25, 30, 30, 35, 35], // Base tornado severity
  };

  // DEPRECATED: Use GameConfigProvider.getPremium() and getVictoryPoints() instead
  static final Map<PolicyKey, PolicyValue> policyValues = {
    PolicyKey(StormType.snow, PropertyType.mansion): const PolicyValue(premium: 9, victoryPoints: -2),
    PolicyKey(StormType.snow, PropertyType.house): const PolicyValue(premium: 7, victoryPoints: 4),
    PolicyKey(StormType.snow, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 6),
    PolicyKey(StormType.hurricaneOther, PropertyType.mansion): const PolicyValue(premium: 9, victoryPoints: -2),
    PolicyKey(StormType.hurricaneOther, PropertyType.house): const PolicyValue(premium: 7, victoryPoints: 4),
    PolicyKey(StormType.hurricaneOther, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 6),
    PolicyKey(StormType.hurricaneFlorida, PropertyType.mansion): const PolicyValue(premium: 16, victoryPoints: -6),
    PolicyKey(StormType.hurricaneFlorida, PropertyType.house): const PolicyValue(premium: 13, victoryPoints: 8),
    PolicyKey(StormType.hurricaneFlorida, PropertyType.mobileHome): const PolicyValue(premium: 8, victoryPoints: 12),
    PolicyKey(StormType.flood, PropertyType.mansion): const PolicyValue(premium: 9, victoryPoints: -2),
    PolicyKey(StormType.flood, PropertyType.house): const PolicyValue(premium: 7, victoryPoints: 4),
    PolicyKey(StormType.flood, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 6),
    PolicyKey(StormType.fire, PropertyType.mansion): const PolicyValue(premium: 11, victoryPoints: -3),
    PolicyKey(StormType.fire, PropertyType.house): const PolicyValue(premium: 9, victoryPoints: 5),
    PolicyKey(StormType.fire, PropertyType.mobileHome): const PolicyValue(premium: 5, victoryPoints: 7),
    PolicyKey(StormType.hail, PropertyType.mansion): const PolicyValue(premium: 12, victoryPoints: -3),
    PolicyKey(StormType.hail, PropertyType.house): const PolicyValue(premium: 10, victoryPoints: 5),
    PolicyKey(StormType.hail, PropertyType.mobileHome): const PolicyValue(premium: 5, victoryPoints: 8),
    PolicyKey(StormType.tornado, PropertyType.mansion): const PolicyValue(premium: 16, victoryPoints: -4),
    PolicyKey(StormType.tornado, PropertyType.house): const PolicyValue(premium: 12, victoryPoints: 7),
    PolicyKey(StormType.tornado, PropertyType.mobileHome): const PolicyValue(premium: 7, victoryPoints: 10),
    PolicyKey(StormType.fireCalifornia, PropertyType.mansion): const PolicyValue(premium: 16, victoryPoints: -6),
    PolicyKey(StormType.fireCalifornia, PropertyType.house): const PolicyValue(premium: 13, victoryPoints: 8),
    PolicyKey(StormType.fireCalifornia, PropertyType.mobileHome): const PolicyValue(premium: 8, victoryPoints: 12),
    PolicyKey(StormType.tornadoTexas, PropertyType.mansion): const PolicyValue(premium: 18, victoryPoints: -7),
    PolicyKey(StormType.tornadoTexas, PropertyType.house): const PolicyValue(premium: 15, victoryPoints: 9),
    PolicyKey(StormType.tornadoTexas, PropertyType.mobileHome): const PolicyValue(premium: 9, victoryPoints: 13),
  };
}

class PolicyKey {
  final StormType storm;
  final PropertyType property;

  const PolicyKey(this.storm, this.property);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolicyKey &&
          runtimeType == other.runtimeType &&
          storm == other.storm &&
          property == other.property;

  @override
  int get hashCode => storm.hashCode ^ property.hashCode;
}

class PolicyValue {
  final int premium;
  final int victoryPoints;

  const PolicyValue({required this.premium, required this.victoryPoints});
}
