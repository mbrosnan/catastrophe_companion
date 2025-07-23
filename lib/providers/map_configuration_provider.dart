import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/map_configuration.dart';
import '../services/map_generator.dart';

class MapConfigurationProvider extends ChangeNotifier {
  final MapGenerator _generator = MapGenerator();
  
  MapConfigurationSettings settings = MapConfigurationSettings();
  GenerationResult? currentResult;
  List<MapProfile> availableProfiles = [];
  bool isLoading = false;
  String? errorMessage;

  MapConfigurationProvider() {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    isLoading = true;
    notifyListeners();

    try {
      // List of profile files to load
      final profileFiles = [
        'fully_random.json',
        'balanced_random.json',
        'coastal_elites.json',
        'northward_migration.json',
        'los_palacios.json',
        'stacked_apart.json',
      ];

      availableProfiles = [];
      
      for (final filename in profileFiles) {
        try {
          final jsonString = await rootBundle.loadString('assets/profiles/$filename');
          final json = jsonDecode(jsonString);
          availableProfiles.add(MapProfile.fromJson(json));
        } catch (e) {
          print('Error loading profile $filename: $e');
        }
      }

      if (availableProfiles.isEmpty) {
        throw Exception('No profiles could be loaded');
      }

      // Set default profile
      settings.selectedProfile = availableProfiles.first.filename;
      
    } catch (e) {
      errorMessage = 'Failed to load profiles: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  MapProfile? get selectedProfile {
    return availableProfiles.firstWhere(
      (p) => p.filename == settings.selectedProfile,
      orElse: () => availableProfiles.first,
    );
  }

  void updateLimitFlorida(bool value) {
    settings.limitFloridaToOne = value;
    notifyListeners();
  }

  void updateLimitTexas(bool value) {
    settings.limitTexasToOne = value;
    notifyListeners();
  }

  void updateLimitCalifornia(bool value) {
    settings.limitCaliforniaToOne = value;
    notifyListeners();
  }

  void updateNumberOfMansions(int value) {
    settings.numberOfMansions = value;
    notifyListeners();
  }

  void updateNumberOfMobileHomes(int value) {
    settings.numberOfMobileHomes = value;
    notifyListeners();
  }

  void updateSelectedProfile(String profileFilename) {
    settings.selectedProfile = profileFilename;
    notifyListeners();
  }

  void generateMap() {
    errorMessage = null;
    
    final profile = selectedProfile;
    if (profile == null) {
      errorMessage = 'No profile selected';
      notifyListeners();
      return;
    }

    try {
      currentResult = _generator.generateMap(
        profile: profile,
        settings: settings,
      );
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      currentResult = null;
    }
    
    notifyListeners();
  }

  void clearResult() {
    currentResult = null;
    errorMessage = null;
    notifyListeners();
  }
}