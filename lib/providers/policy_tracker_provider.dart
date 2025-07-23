import 'package:flutter/material.dart';
import '../models/policy_data.dart';

class PolicyTrackerProvider extends ChangeNotifier {
  final Map<PolicyKey, int> _policyCounts = {};
  final Set<StormType> _shownGrowthTargetPopups = {};
  final Set<StormType> _shownAgentOfYearPopups = {};
  bool _shownDiversifiedAgentPopup = false;
  
  static const int growthTargetThreshold = 2;
  static const int agentOfYearThreshold = 6;

  PolicyTrackerProvider() {
    // Initialize all policy counts to 0
    for (final storm in StormType.values) {
      for (final property in PropertyType.values) {
        _policyCounts[PolicyKey(storm, property)] = 0;
      }
    }
  }

  int getPolicyCount(StormType storm, PropertyType property) {
    return _policyCounts[PolicyKey(storm, property)] ?? 0;
  }

  void incrementPolicy(StormType storm, PropertyType property, BuildContext context) {
    final key = PolicyKey(storm, property);
    _policyCounts[key] = (_policyCounts[key] ?? 0) + 1;
    notifyListeners();
    
    _checkThreshold(storm, context);
  }

  void decrementPolicy(StormType storm, PropertyType property) {
    final key = PolicyKey(storm, property);
    final currentCount = _policyCounts[key] ?? 0;
    if (currentCount > 0) {
      _policyCounts[key] = currentCount - 1;
      notifyListeners();
    }
  }

  int getStormTotal(StormType storm) {
    int total = 0;
    for (final property in PropertyType.values) {
      total += getPolicyCount(storm, property);
    }
    return total;
  }

  int getTotalPremium() {
    int total = 0;
    _policyCounts.forEach((key, count) {
      final policyValue = PolicyData.policyValues[key];
      if (policyValue != null) {
        total += policyValue.premium * count;
      }
    });
    return total;
  }

  int getTotalVictoryPoints() {
    int total = 0;
    _policyCounts.forEach((key, count) {
      final policyValue = PolicyData.policyValues[key];
      if (policyValue != null) {
        total += policyValue.victoryPoints * count;
      }
    });
    return total;
  }

  bool hasGrowthTargetCard(StormType storm) {
    // For hurricanes, show icon only on Hurricane-Other when combined total reaches threshold
    if (storm == StormType.hurricaneOther) {
      return (getStormTotal(StormType.hurricaneOther) + getStormTotal(StormType.hurricaneFlorida)) >= growthTargetThreshold;
    } else if (storm == StormType.hurricaneFlorida) {
      return false; // Never show icon on Hurricane-Florida
    }
    return getStormTotal(storm) >= growthTargetThreshold;
  }

  bool hasAgentOfYearCard(StormType storm) {
    // For hurricanes, show icon only on Hurricane-Other when combined total reaches threshold
    if (storm == StormType.hurricaneOther) {
      return (getStormTotal(StormType.hurricaneOther) + getStormTotal(StormType.hurricaneFlorida)) >= agentOfYearThreshold;
    } else if (storm == StormType.hurricaneFlorida) {
      return false; // Never show icon on Hurricane-Florida
    }
    return getStormTotal(storm) >= agentOfYearThreshold;
  }

  bool hasDiversifiedAgent() {
    // Check if player has at least 1 policy in every storm type (treating hurricanes as one)
    final stormTypesWithPolicies = <StormType>{};
    
    for (final storm in StormType.values) {
      if (storm == StormType.hurricaneFlorida) continue; // Skip Florida, count as hurricaneOther
      
      final total = storm == StormType.hurricaneOther
          ? getStormTotal(StormType.hurricaneOther) + getStormTotal(StormType.hurricaneFlorida)
          : getStormTotal(storm);
          
      if (total > 0) {
        stormTypesWithPolicies.add(storm);
      }
    }
    
    // Need policies in all 7 storm types (counting hurricanes as one)
    return stormTypesWithPolicies.length == 7;
  }

  void _checkThreshold(StormType storm, BuildContext context) {
    // For hurricane cards, count both hurricane types together
    final total = (storm == StormType.hurricaneOther || storm == StormType.hurricaneFlorida)
        ? getStormTotal(StormType.hurricaneOther) + getStormTotal(StormType.hurricaneFlorida)
        : getStormTotal(storm);
    
    // Use hurricaneOther as the key for both hurricane types
    final popupKey = (storm == StormType.hurricaneFlorida) ? StormType.hurricaneOther : storm;
    final displayName = (storm == StormType.hurricaneOther || storm == StormType.hurricaneFlorida)
        ? 'Hurricane'
        : PolicyData.stormNames[storm];
    
    // Check Growth Target threshold
    if (total >= growthTargetThreshold && !_shownGrowthTargetPopups.contains(popupKey)) {
      _shownGrowthTargetPopups.add(popupKey);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Growth Target Card Available!'),
            content: Text(
              'You now have $growthTargetThreshold or more $displayName policies.\n\n'
              'Remember to collect your $displayName Growth Target card from the game!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    
    // Check Agent of the Year threshold
    if (total >= agentOfYearThreshold && !_shownAgentOfYearPopups.contains(popupKey)) {
      _shownAgentOfYearPopups.add(popupKey);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Agent of the Year Card Available!'),
            content: Text(
              'You now have $agentOfYearThreshold or more $displayName policies.\n\n'
              'Congratulations! Remember to collect your $displayName Agent of the Year card from the game!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    
    // Check Diversified Agent of the Year
    if (!_shownDiversifiedAgentPopup && hasDiversifiedAgent()) {
      _shownDiversifiedAgentPopup = true;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Diversified Agent of the Year!'),
            content: const Text(
              'You now have at least 1 policy in every storm type!\n\n'
              'Congratulations! Remember to collect your Diversified Agent of the Year card from the game (10 Victory Points)!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}