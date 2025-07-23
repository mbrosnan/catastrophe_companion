import 'dart:math';
import '../models/map_configuration.dart';

class MapGenerator {
  final Random _random = Random();

  // Helper method to treat Florida hurricanes as regular hurricanes
  StormType _getEffectiveStormType(StormType storm) {
    return storm == StormType.hurricaneFlorida ? StormType.hurricaneOther : storm;
  }

  GenerationResult generateMap({
    required MapProfile profile,
    required MapConfigurationSettings settings,
  }) {
    // Handle special stacking modes
    if (profile.specialMode == 'stackedTogether' || profile.specialMode == 'stackedApart') {
      return _generateStackedMap(profile: profile, settings: settings);
    }
    
    // Normal generation for regular profiles
    return _generateNormalMap(profile: profile, settings: settings);
  }

  GenerationResult _generateNormalMap({
    required MapProfile profile,
    required MapConfigurationSettings settings,
  }) {
    // For profiles with tight balance constraints, retry a few times
    final maxRetries = profile.acceptableStormDifference <= 2 ? 5 : 1;
    
    for (int retry = 0; retry < maxRetries; retry++) {
      try {
        return _attemptNormalGeneration(
          profile: profile,
          settings: settings,
        );
      } catch (e) {
        if (retry < maxRetries - 1 && e.toString().contains('maintaining storm balance')) {
          // Try again with a fresh random state
          continue;
        }
        // Last attempt or different error, propagate it
        throw e;
      }
    }
    
    // Should never reach here
    throw Exception('Failed to generate map after $maxRetries attempts');
  }
  
  GenerationResult _attemptNormalGeneration({
    required MapProfile profile,
    required MapConfigurationSettings settings,
  }) {
    // Validate inputs
    final totalSpaces = _calculateTotalSpaces();
    final totalTokens = settings.numberOfMansions + settings.numberOfMobileHomes;
    
    if (totalTokens > totalSpaces) {
      throw Exception('Too many tokens ($totalTokens) for available spaces ($totalSpaces)');
    }

    // Initialize tracking structures
    final mansionAssignments = <String, int>{};
    final mobileHomeAssignments = <String, int>{};
    final availableSpaces = <String, int>{};
    final stormCounts = <StormType, int>{};
    
    // Initialize available spaces and storm counts
    for (final entry in usStates.entries) {
      availableSpaces[entry.key] = entry.value.spaces;
      
      // Apply state limits if enabled
      if (settings.limitFloridaToOne && entry.key == 'FL') {
        availableSpaces[entry.key] = 2; // Max 1 of each type
      } else if (settings.limitTexasToOne && entry.key == 'TX') {
        availableSpaces[entry.key] = 2; // Max 1 of each type
      } else if (settings.limitCaliforniaToOne && entry.key == 'CA') {
        availableSpaces[entry.key] = 2; // Max 1 of each type
      }
    }
    
    // Initialize storm counts to 0 (excluding hurricaneFlorida which is treated as hurricaneOther)
    for (final storm in StormType.values) {
      if (storm != StormType.hurricaneFlorida) {
        stormCounts[storm] = 0;
      }
    }

    // Generate mansion assignments
    try {
      _assignTokens(
        tokenType: PropertyType.mansion,
        count: settings.numberOfMansions,
        weights: profile.mansionWeights,
        assignments: mansionAssignments,
        availableSpaces: availableSpaces,
        stormCounts: stormCounts,
        acceptableDifference: profile.acceptableStormDifference,
        stateLimit: settings.limitFloridaToOne || settings.limitTexasToOne || settings.limitCaliforniaToOne,
      );
    } catch (e) {
      throw Exception('Failed to assign mansions: ${e.toString()}');
    }

    // Generate mobile home assignments
    try {
      _assignTokens(
        tokenType: PropertyType.mobileHome,
        count: settings.numberOfMobileHomes,
        weights: profile.mobileHomeWeights,
        assignments: mobileHomeAssignments,
        availableSpaces: availableSpaces,
        stormCounts: stormCounts,
        acceptableDifference: profile.acceptableStormDifference,
        stateLimit: settings.limitFloridaToOne || settings.limitTexasToOne || settings.limitCaliforniaToOne,
      );
    } catch (e) {
      throw Exception('Failed to assign mobile homes: ${e.toString()}');
    }

    // Calculate empty states
    final emptyStates = <String>[];
    for (final entry in availableSpaces.entries) {
      if (entry.value == usStates[entry.key]!.spaces) {
        emptyStates.add(entry.key);
      }
    }
    emptyStates.sort();

    return GenerationResult(
      mansionAssignments: mansionAssignments,
      mobileHomeAssignments: mobileHomeAssignments,
      emptyStates: emptyStates,
    );
  }

  void _assignTokens({
    required PropertyType tokenType,
    required int count,
    required Map<String, double> weights,
    required Map<String, int> assignments,
    required Map<String, int> availableSpaces,
    required Map<StormType, int> stormCounts,
    required int acceptableDifference,
    required bool stateLimit,
  }) {
    int assigned = 0;
    int attempts = 0;
    const maxAttempts = 10000;

    while (assigned < count && attempts < maxAttempts) {
      attempts++;
      
      // Build weighted list of available states
      final candidateStates = <String>[];
      final candidateWeights = <double>[];
      
      for (final state in usStates.keys) {
        final spaces = availableSpaces[state] ?? 0;
        
        // Check if state has available space
        if (spaces <= 0) continue;
        
        // Check state limits for special states
        if (stateLimit && (state == 'FL' || state == 'TX' || state == 'CA')) {
          final currentAssignments = assignments[state] ?? 0;
          if (currentAssignments >= 1) continue;
        }
        
        // Check if assignment would violate storm balance
        final stateInfo = usStates[state]!;
        bool canAssign = true;
        
        for (final storm in stateInfo.stormTypes) {
          final effectiveStorm = _getEffectiveStormType(storm);
          final currentCount = stormCounts[effectiveStorm] ?? 0;
          
          // Check if adding to this storm would exceed acceptable difference
          for (final otherStorm in StormType.values) {
            final effectiveOtherStorm = _getEffectiveStormType(otherStorm);
            if (effectiveOtherStorm == effectiveStorm) continue;
            
            final otherCount = stormCounts[effectiveOtherStorm] ?? 0;
            
            if ((currentCount + 1) - otherCount > acceptableDifference) {
              canAssign = false;
              break;
            }
          }
          
          if (!canAssign) break;
        }
        
        if (!canAssign) continue;
        
        // Add state as candidate with its weight
        candidateStates.add(state);
        candidateWeights.add((weights[state] ?? 1.0) * spaces);
      }
      
      // If no candidates available, we're stuck
      if (candidateStates.isEmpty) {
        if (assigned < count) {
          throw Exception('Cannot assign remaining ${count - assigned} tokens while maintaining storm balance');
        }
        break;
      }
      
      // Select a state using weighted random selection
      final selectedState = _weightedRandomSelection(candidateStates, candidateWeights);
      
      // Assign token to selected state
      assignments[selectedState] = (assignments[selectedState] ?? 0) + 1;
      availableSpaces[selectedState] = (availableSpaces[selectedState] ?? 0) - 1;
      
      // Update storm counts
      final stateInfo = usStates[selectedState]!;
      for (final storm in stateInfo.stormTypes) {
        final effectiveStorm = _getEffectiveStormType(storm);
        stormCounts[effectiveStorm] = (stormCounts[effectiveStorm] ?? 0) + 1;
      }
      
      assigned++;
    }
    
    if (attempts >= maxAttempts && assigned < count) {
      throw Exception('Failed to assign all tokens after $maxAttempts attempts');
    }
  }

  String _weightedRandomSelection(List<String> items, List<double> weights) {
    final totalWeight = weights.reduce((a, b) => a + b);
    final randomValue = _random.nextDouble() * totalWeight;
    
    double cumulativeWeight = 0;
    for (int i = 0; i < items.length; i++) {
      cumulativeWeight += weights[i];
      if (randomValue <= cumulativeWeight) {
        return items[i];
      }
    }
    
    return items.last;
  }

  int _calculateTotalSpaces() {
    return usStates.values.fold(0, (sum, state) => sum + state.spaces);
  }

  GenerationResult _generateStackedMap({
    required MapProfile profile,
    required MapConfigurationSettings settings,
  }) {
    final mansionAssignments = <String, int>{};
    final mobileHomeAssignments = <String, int>{};
    
    // Get valid storm types (excluding hurricaneFlorida which is treated as hurricaneOther)
    final validStormTypes = StormType.values
        .where((storm) => storm != StormType.hurricaneFlorida)
        .toList();
    
    if (profile.specialMode == 'stackedTogether') {
      // Select 2 random storm types for both property types
      final selectedStorms = _selectRandomStormTypes(validStormTypes, 2);
      
      // Get all states with these storm types
      final eligibleStates = _getStatesWithStormTypes(selectedStorms);
      
      // Validate we have enough spaces
      final totalSpaces = _calculateSpacesForStates(eligibleStates, settings);
      final totalTokens = settings.numberOfMansions + settings.numberOfMobileHomes;
      
      if (totalTokens > totalSpaces) {
        throw Exception('Not enough spaces in selected storm types. Need $totalTokens spaces but only have $totalSpaces');
      }
      
      // Assign mansions
      _assignStackedTokens(
        count: settings.numberOfMansions,
        eligibleStates: eligibleStates,
        assignments: mansionAssignments,
        settings: settings,
      );
      
      // Assign mobile homes
      _assignStackedTokens(
        count: settings.numberOfMobileHomes,
        eligibleStates: eligibleStates,
        assignments: mobileHomeAssignments,
        settings: settings,
      );
      
    } else if (profile.specialMode == 'stackedApart') {
      // Select 2 storm types for mansions
      final mansionStorms = _selectRandomStormTypes(validStormTypes, 2);
      
      // Select 2 different storm types for mobile homes
      final remainingStorms = validStormTypes
          .where((storm) => !mansionStorms.contains(storm))
          .toList();
      
      if (remainingStorms.length < 2) {
        throw Exception('Not enough different storm types for stacked apart mode');
      }
      
      final mobileHomeStorms = _selectRandomStormTypes(remainingStorms, 2);
      
      // Get eligible states for each property type
      final mansionStates = _getStatesWithStormTypes(mansionStorms);
      final mobileHomeStates = _getStatesWithStormTypes(mobileHomeStorms);
      
      // Validate spaces
      final mansionSpaces = _calculateSpacesForStates(mansionStates, settings);
      final mobileHomeSpaces = _calculateSpacesForStates(mobileHomeStates, settings);
      
      if (settings.numberOfMansions > mansionSpaces) {
        throw Exception('Not enough spaces for mansions. Need ${settings.numberOfMansions} but only have $mansionSpaces');
      }
      
      if (settings.numberOfMobileHomes > mobileHomeSpaces) {
        throw Exception('Not enough spaces for mobile homes. Need ${settings.numberOfMobileHomes} but only have $mobileHomeSpaces');
      }
      
      // Assign tokens
      _assignStackedTokens(
        count: settings.numberOfMansions,
        eligibleStates: mansionStates,
        assignments: mansionAssignments,
        settings: settings,
      );
      
      _assignStackedTokens(
        count: settings.numberOfMobileHomes,
        eligibleStates: mobileHomeStates,
        assignments: mobileHomeAssignments,
        settings: settings,
      );
    }
    
    // Calculate empty states
    final allAssignedStates = <String>{};
    allAssignedStates.addAll(mansionAssignments.keys);
    allAssignedStates.addAll(mobileHomeAssignments.keys);
    
    final emptyStates = usStates.keys
        .where((state) => !allAssignedStates.contains(state))
        .toList()
      ..sort();
    
    return GenerationResult(
      mansionAssignments: mansionAssignments,
      mobileHomeAssignments: mobileHomeAssignments,
      emptyStates: emptyStates,
    );
  }
  
  List<StormType> _selectRandomStormTypes(List<StormType> availableStorms, int count) {
    final shuffled = List<StormType>.from(availableStorms)..shuffle(_random);
    return shuffled.take(count).toList();
  }
  
  List<String> _getStatesWithStormTypes(List<StormType> stormTypes) {
    final states = <String>[];
    
    for (final entry in usStates.entries) {
      final stateStorms = entry.value.stormTypes;
      
      // Include state if it has ANY of the selected storm types
      for (final stateStorm in stateStorms) {
        if (stormTypes.contains(stateStorm)) {
          states.add(entry.key);
          break;
        }
      }
    }
    
    return states;
  }
  
  int _calculateSpacesForStates(List<String> states, MapConfigurationSettings settings) {
    int totalSpaces = 0;
    
    for (final state in states) {
      int spaces = usStates[state]!.spaces;
      
      // Apply state limits if enabled
      if ((state == 'FL' && settings.limitFloridaToOne) ||
          (state == 'TX' && settings.limitTexasToOne) ||
          (state == 'CA' && settings.limitCaliforniaToOne)) {
        spaces = 2; // Max 1 of each type
      }
      
      totalSpaces += spaces;
    }
    
    return totalSpaces;
  }
  
  void _assignStackedTokens({
    required int count,
    required List<String> eligibleStates,
    required Map<String, int> assignments,
    required MapConfigurationSettings settings,
  }) {
    // Create a map of available spaces per state
    final availableSpaces = <String, int>{};
    
    for (final state in eligibleStates) {
      int spaces = usStates[state]!.spaces;
      
      // Apply state limits
      if ((state == 'FL' && settings.limitFloridaToOne) ||
          (state == 'TX' && settings.limitTexasToOne) ||
          (state == 'CA' && settings.limitCaliforniaToOne)) {
        spaces = 1; // Max 1 for limited states
      }
      
      availableSpaces[state] = spaces;
    }
    
    // Assign tokens randomly to eligible states
    int assigned = 0;
    
    while (assigned < count) {
      // Get states with available space
      final availableStates = availableSpaces.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList();
      
      if (availableStates.isEmpty) {
        throw Exception('No more available spaces to assign tokens');
      }
      
      // Pick a random state
      final selectedState = availableStates[_random.nextInt(availableStates.length)];
      
      // Assign token
      assignments[selectedState] = (assignments[selectedState] ?? 0) + 1;
      availableSpaces[selectedState] = availableSpaces[selectedState]! - 1;
      assigned++;
    }
  }
}