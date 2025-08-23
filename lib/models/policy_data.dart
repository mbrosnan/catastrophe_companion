import 'package:flutter/material.dart';

enum StormType {
  earthquake,
  snow,
  hurricaneOther,
  flood,
  fire,
  hail,
  tornado,
  hurricaneFlorida,
}

enum PropertyType {
  mansion,
  house,
  mobileHome,
}

class PolicyData {
  static const Map<StormType, String> stormNames = {
    StormType.snow: 'Snow',
    StormType.earthquake: 'Earthquake',
    StormType.hurricaneOther: 'Hurricane-Other',
    StormType.hurricaneFlorida: 'Hurricane-Florida',
    StormType.flood: 'Flood',
    StormType.fire: 'Fire',
    StormType.hail: 'Hail',
    StormType.tornado: 'Tornado',
  };

  static const Map<StormType, Color> stormColors = {
    StormType.snow: Colors.lightBlue,
    StormType.earthquake: Colors.brown,
    StormType.hurricaneOther: Color(0xFFE6E6FA), // Lavender - will be used as text color
    StormType.hurricaneFlorida: Colors.purple,
    StormType.flood: Colors.blue,
    StormType.fire: Colors.red,
    StormType.hail: Colors.yellow,
    StormType.tornado: Colors.grey,
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

  static const Map<StormType, List<int>> stormPayouts = {
    StormType.snow: [0, 5, 10, 15, 25],
    StormType.earthquake: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50],
    StormType.hurricaneOther: [0, 5, 15, 25, 30, 35, 40],
    StormType.hurricaneFlorida: [0, 10, 30, 50, 60, 70, 80],
    StormType.flood: [0, 10, 15, 20, 25, 30],
    StormType.fire: [0, 20, 35, 50],
    StormType.hail: [0, 15, 20, 25],
    StormType.tornado: [0, 25, 30, 35],
  };

  // Storm occurrence probabilities (out of 20 for D20)
  static const Map<StormType, int> stormOccurrenceD20 = {
    StormType.snow: 12,
    StormType.earthquake: 2,
    StormType.hurricaneOther: 4,
    StormType.hurricaneFlorida: 4,
    StormType.flood: 5,
    StormType.fire: 3,
    StormType.hail: 7,
    StormType.tornado: 6,
  };

  // Severity die values (D6 outcomes)
  static const Map<StormType, List<int>> stormSeverityD6 = {
    StormType.snow: [5, 5, 5, 10, 10, 25],
    StormType.earthquake: [5, 10, 15, 20, 25, 30],
    StormType.hurricaneOther: [5, 15, 25, 30, 35, 40],
    StormType.hurricaneFlorida: [10, 30, 50, 60, 70, 80],
    StormType.flood: [10, 15, 20, 20, 25, 30],
    StormType.fire: [20, 20, 35, 35, 50, 50],
    StormType.hail: [15, 15, 20, 20, 25, 25],
    StormType.tornado: [25, 25, 30, 30, 35, 35],
  };

  static final Map<PolicyKey, PolicyValue> policyValues = {
    PolicyKey(StormType.snow, PropertyType.mansion): const PolicyValue(premium: 9, victoryPoints: -2),
    PolicyKey(StormType.snow, PropertyType.house): const PolicyValue(premium: 7, victoryPoints: 4),
    PolicyKey(StormType.snow, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 6),
    PolicyKey(StormType.earthquake, PropertyType.mansion): const PolicyValue(premium: 6, victoryPoints: -1),
    PolicyKey(StormType.earthquake, PropertyType.house): const PolicyValue(premium: 5, victoryPoints: 3),
    PolicyKey(StormType.earthquake, PropertyType.mobileHome): const PolicyValue(premium: 3, victoryPoints: 4),
    PolicyKey(StormType.hurricaneOther, PropertyType.mansion): const PolicyValue(premium: 9, victoryPoints: -2),
    PolicyKey(StormType.hurricaneOther, PropertyType.house): const PolicyValue(premium: 7, victoryPoints: 4),
    PolicyKey(StormType.hurricaneOther, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 6),
    PolicyKey(StormType.hurricaneFlorida, PropertyType.mansion): const PolicyValue(premium: 18, victoryPoints: -6),
    PolicyKey(StormType.hurricaneFlorida, PropertyType.house): const PolicyValue(premium: 14, victoryPoints: 8),
    PolicyKey(StormType.hurricaneFlorida, PropertyType.mobileHome): const PolicyValue(premium: 8, victoryPoints: 12),
    PolicyKey(StormType.flood, PropertyType.mansion): const PolicyValue(premium: 9, victoryPoints: -2),
    PolicyKey(StormType.flood, PropertyType.house): const PolicyValue(premium: 7, victoryPoints: 4),
    PolicyKey(StormType.flood, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 6),
    PolicyKey(StormType.fire, PropertyType.mansion): const PolicyValue(premium: 10, victoryPoints: -3),
    PolicyKey(StormType.fire, PropertyType.house): const PolicyValue(premium: 8, victoryPoints: 4),
    PolicyKey(StormType.fire, PropertyType.mobileHome): const PolicyValue(premium: 4, victoryPoints: 7),
    PolicyKey(StormType.hail, PropertyType.mansion): const PolicyValue(premium: 12, victoryPoints: -3),
    PolicyKey(StormType.hail, PropertyType.house): const PolicyValue(premium: 10, victoryPoints: 5),
    PolicyKey(StormType.hail, PropertyType.mobileHome): const PolicyValue(premium: 5, victoryPoints: 8),
    PolicyKey(StormType.tornado, PropertyType.mansion): const PolicyValue(premium: 16, victoryPoints: -4),
    PolicyKey(StormType.tornado, PropertyType.house): const PolicyValue(premium: 12, victoryPoints: 7),
    PolicyKey(StormType.tornado, PropertyType.mobileHome): const PolicyValue(premium: 7, victoryPoints: 10),
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