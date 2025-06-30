import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum StormType {
  snow,
  earthquake,
  hurricaneOther,
  flood,
  fire,
  hail,
  tornado,
  hurricaneFlorida,
}

// Storm type colors based on the game
const Map<StormType, Color> stormColors = {
  StormType.snow: Colors.white,
  StormType.earthquake: Color(0xFF8B4513), // Brown
  StormType.hurricaneOther: Color(0xFFE6E6FA), // Lavender
  StormType.hurricaneFlorida: Color(0xFF9370DB), // Purple (medium purple)
  StormType.flood: Colors.blue,
  StormType.fire: Colors.red,
  StormType.hail: Colors.yellow,
  StormType.tornado: Colors.grey,
};

enum PropertyType {
  mansion,
  house,
  mobileHome,
}

@immutable
class StateInfo {
  final String code;
  final String name;
  final int spaces;
  final List<StormType> stormTypes;

  const StateInfo({
    required this.code,
    required this.name,
    required this.spaces,
    required this.stormTypes,
  });
}

@immutable
class MapProfile {
  final String name;
  final String filename;
  final String description;
  final Map<String, double> mansionWeights;
  final Map<String, double> mobileHomeWeights;
  final int acceptableStormDifference;
  final String? specialMode;

  const MapProfile({
    required this.name,
    required this.filename,
    required this.description,
    required this.mansionWeights,
    required this.mobileHomeWeights,
    required this.acceptableStormDifference,
    this.specialMode,
  });

  factory MapProfile.fromJson(Map<String, dynamic> json) {
    return MapProfile(
      name: json['name'],
      filename: json['filename'],
      description: json['description'],
      mansionWeights: Map<String, double>.from(json['mansionWeights']),
      mobileHomeWeights: Map<String, double>.from(json['mobileHomeWeights']),
      acceptableStormDifference: json['acceptableStormDifference'],
      specialMode: json['specialMode'],
    );
  }
}

@immutable
class GenerationResult {
  final Map<String, int> mansionAssignments;
  final Map<String, int> mobileHomeAssignments;
  final List<String> emptyStates;

  const GenerationResult({
    required this.mansionAssignments,
    required this.mobileHomeAssignments,
    required this.emptyStates,
  });
}

class MapConfigurationSettings {
  bool limitFloridaToOne = false;
  bool limitTexasToOne = false;
  bool limitCaliforniaToOne = false;
  int numberOfMansions = 10;
  int numberOfMobileHomes = 10;
  String selectedProfile = 'balanced_random';

  MapConfigurationSettings();
}

// State data as defined in the notes
const Map<String, StateInfo> usStates = {
  'WA': StateInfo(code: 'WA', name: 'Washington', spaces: 2, stormTypes: [StormType.fire]),
  'OR': StateInfo(code: 'OR', name: 'Oregon', spaces: 1, stormTypes: [StormType.fire]),
  'CA': StateInfo(code: 'CA', name: 'California', spaces: 10, stormTypes: [StormType.fire, StormType.earthquake]),
  'ID': StateInfo(code: 'ID', name: 'Idaho', spaces: 1, stormTypes: [StormType.fire]),
  'NV': StateInfo(code: 'NV', name: 'Nevada', spaces: 1, stormTypes: [StormType.fire]),
  'AZ': StateInfo(code: 'AZ', name: 'Arizona', spaces: 2, stormTypes: [StormType.fire]),
  'MT': StateInfo(code: 'MT', name: 'Montana', spaces: 1, stormTypes: [StormType.fire]),
  'WY': StateInfo(code: 'WY', name: 'Wyoming', spaces: 1, stormTypes: [StormType.hail]),
  'UT': StateInfo(code: 'UT', name: 'Utah', spaces: 1, stormTypes: [StormType.hail]),
  'CO': StateInfo(code: 'CO', name: 'Colorado', spaces: 2, stormTypes: [StormType.hail]),
  'NM': StateInfo(code: 'NM', name: 'New Mexico', spaces: 1, stormTypes: [StormType.hail]),
  'ND': StateInfo(code: 'ND', name: 'North Dakota', spaces: 1, stormTypes: [StormType.hail]),
  'SD': StateInfo(code: 'SD', name: 'South Dakota', spaces: 1, stormTypes: [StormType.hail]),
  'NE': StateInfo(code: 'NE', name: 'Nebraska', spaces: 1, stormTypes: [StormType.tornado]),
  'KS': StateInfo(code: 'KS', name: 'Kansas', spaces: 1, stormTypes: [StormType.tornado]),
  'OK': StateInfo(code: 'OK', name: 'Oklahoma', spaces: 1, stormTypes: [StormType.tornado]),
  'TX': StateInfo(code: 'TX', name: 'Texas', spaces: 8, stormTypes: [StormType.tornado, StormType.hurricaneOther]),
  'MN': StateInfo(code: 'MN', name: 'Minnesota', spaces: 2, stormTypes: [StormType.snow]),
  'IA': StateInfo(code: 'IA', name: 'Iowa', spaces: 1, stormTypes: [StormType.tornado]),
  'MO': StateInfo(code: 'MO', name: 'Missouri', spaces: 2, stormTypes: [StormType.tornado]),
  'AR': StateInfo(code: 'AR', name: 'Arkansas', spaces: 1, stormTypes: [StormType.tornado]),
  'LA': StateInfo(code: 'LA', name: 'Louisiana', spaces: 1, stormTypes: [StormType.hurricaneOther]),
  'WI': StateInfo(code: 'WI', name: 'Wisconsin', spaces: 2, stormTypes: [StormType.snow]),
  'IL': StateInfo(code: 'IL', name: 'Illinois', spaces: 3, stormTypes: [StormType.tornado]),
  'MS': StateInfo(code: 'MS', name: 'Mississippi', spaces: 1, stormTypes: [StormType.hurricaneOther]),
  'TN': StateInfo(code: 'TN', name: 'Tennessee', spaces: 2, stormTypes: [StormType.hail]),
  'KY': StateInfo(code: 'KY', name: 'Kentucky', spaces: 1, stormTypes: [StormType.hail]),
  'IN': StateInfo(code: 'IN', name: 'Indiana', spaces: 2, stormTypes: [StormType.hail]),
  'OH': StateInfo(code: 'OH', name: 'Ohio', spaces: 3, stormTypes: [StormType.hail]),
  'MI': StateInfo(code: 'MI', name: 'Michigan', spaces: 3, stormTypes: [StormType.snow]),
  'WV': StateInfo(code: 'WV', name: 'West Virginia', spaces: 1, stormTypes: [StormType.hail]),
  'AL': StateInfo(code: 'AL', name: 'Alabama', spaces: 2, stormTypes: [StormType.hurricaneOther]),
  'GA': StateInfo(code: 'GA', name: 'Georgia', spaces: 3, stormTypes: [StormType.hurricaneOther]),
  'FL': StateInfo(code: 'FL', name: 'Florida', spaces: 5, stormTypes: [StormType.hurricaneFlorida]),
  'SC': StateInfo(code: 'SC', name: 'South Carolina', spaces: 2, stormTypes: [StormType.hurricaneOther]),
  'NC': StateInfo(code: 'NC', name: 'North Carolina', spaces: 3, stormTypes: [StormType.hurricaneOther]),
  'VA': StateInfo(code: 'VA', name: 'Virginia', spaces: 2, stormTypes: [StormType.hurricaneOther]),
  'MD': StateInfo(code: 'MD', name: 'Maryland', spaces: 1, stormTypes: [StormType.flood]),
  'DE': StateInfo(code: 'DE', name: 'Delaware', spaces: 1, stormTypes: [StormType.flood]),
  'NJ': StateInfo(code: 'NJ', name: 'New Jersey', spaces: 1, stormTypes: [StormType.flood]),
  'PA': StateInfo(code: 'PA', name: 'Pennsylvania', spaces: 3, stormTypes: [StormType.flood]),
  'NY': StateInfo(code: 'NY', name: 'New York', spaces: 5, stormTypes: [StormType.flood]),
  'VT': StateInfo(code: 'VT', name: 'Vermont', spaces: 1, stormTypes: [StormType.snow]),
  'NH': StateInfo(code: 'NH', name: 'New Hampshire', spaces: 1, stormTypes: [StormType.snow]),
  'MA': StateInfo(code: 'MA', name: 'Massachusetts', spaces: 2, stormTypes: [StormType.snow]),
  'CT': StateInfo(code: 'CT', name: 'Connecticut', spaces: 1, stormTypes: [StormType.snow]),
  'RI': StateInfo(code: 'RI', name: 'Rhode Island', spaces: 1, stormTypes: [StormType.snow]),
  'ME': StateInfo(code: 'ME', name: 'Maine', spaces: 1, stormTypes: [StormType.snow]),
  'DC': StateInfo(code: 'DC', name: 'District of Columbia', spaces: 1, stormTypes: [StormType.flood]),
};