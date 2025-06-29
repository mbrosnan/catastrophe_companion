import 'package:flutter/material.dart';
import '../models/policy_data.dart';

class PolicyTrackerProvider extends ChangeNotifier {
  final Map<PolicyKey, int> _policyCounts = {};
  final Set<StormType> _shownGrowthTargetPopups = {};
  final Set<StormType> _shownAgentOfYearPopups = {};
  
  static const int growthTargetThreshold = 2;
  static const int agentOfYearThreshold = 7;

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
    return getStormTotal(storm) >= growthTargetThreshold;
  }

  bool hasAgentOfYearCard(StormType storm) {
    return getStormTotal(storm) >= agentOfYearThreshold;
  }

  void _checkThreshold(StormType storm, BuildContext context) {
    final total = getStormTotal(storm);
    
    // Check Growth Target threshold
    if (total >= growthTargetThreshold && !_shownGrowthTargetPopups.contains(storm)) {
      _shownGrowthTargetPopups.add(storm);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Growth Target Card Available!'),
            content: Text(
              'You now have $growthTargetThreshold or more ${PolicyData.stormNames[storm]} policies.\n\n'
              'Remember to collect your ${PolicyData.stormNames[storm]} Growth Target card from the game!',
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
    if (total >= agentOfYearThreshold && !_shownAgentOfYearPopups.contains(storm)) {
      _shownAgentOfYearPopups.add(storm);
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Agent of the Year Card Available!'),
            content: Text(
              'You now have $agentOfYearThreshold or more ${PolicyData.stormNames[storm]} policies.\n\n'
              'Congratulations! Remember to collect your ${PolicyData.stormNames[storm]} Agent of the Year card from the game!',
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