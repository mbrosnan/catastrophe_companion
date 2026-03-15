import 'package:flutter/material.dart';
import '../models/policy_data.dart';
import 'game_config_provider.dart';

class PolicyTrackerProvider extends ChangeNotifier {
  final Map<PolicyKey, int> _policyCounts = {};
  final Set<StormType> _shownGrowthTargetPopups = {};
  final Set<StormType> _shownAgentOfYearPopups = {};
  bool _shownDiversifiedAgentPopup = false;

  // Store reference to GameConfigProvider
  GameConfigProvider? _configProvider;

  // Update the game configuration reference
  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }

  // Get thresholds from config (with defaults if not loaded)
  int get growthTargetThreshold => _configProvider?.growthTargetThreshold ?? 2;
  int get agentOfYearThreshold => _configProvider?.agentOfTheYearThreshold ?? 6;

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

  /// Get total policies for a base storm type, including its state-specific variant.
  /// e.g., getCombinedStormTotal(hurricaneOther) includes hurricaneFlorida.
  int getCombinedStormTotal(StormType baseStorm) {
    int total = getStormTotal(baseStorm);
    // Add any state-specific variants that map to this base storm
    for (final entry in PolicyData.parentStormTypes.entries) {
      if (entry.value == baseStorm) {
        total += getStormTotal(entry.key);
      }
    }
    return total;
  }

  int getTotalPremium() {
    if (_configProvider == null) return 0;

    int total = 0;
    _policyCounts.forEach((key, count) {
      final premium = _configProvider!.getPremium(key.storm, key.property);
      total += premium * count;
    });
    return total;
  }

  int getTotalVictoryPoints() {
    if (_configProvider == null) return 0;

    int total = 0;
    _policyCounts.forEach((key, count) {
      final victoryPoints = _configProvider!.getVictoryPoints(key.storm, key.property);
      total += victoryPoints * count;
    });
    return total;
  }

  bool hasGrowthTargetCard(StormType storm) {
    // State-specific types: show icon on their parent base storm, not on themselves
    final parentStorm = PolicyData.parentStormTypes[storm];
    if (parentStorm != null) {
      return false; // Never show icon on state-specific buttons
    }
    return getCombinedStormTotal(storm) >= growthTargetThreshold;
  }

  bool hasAgentOfYearCard(StormType storm) {
    // State-specific types: show icon on their parent base storm, not on themselves
    final parentStorm = PolicyData.parentStormTypes[storm];
    if (parentStorm != null) {
      return false; // Never show icon on state-specific buttons
    }
    return getCombinedStormTotal(storm) >= agentOfYearThreshold;
  }

  bool hasDiversifiedAgent() {
    // Check if player has at least 1 policy in every base storm type
    // State-specific types count toward their parent base type
    int typesWithPolicies = 0;

    for (final baseStorm in PolicyData.baseStormTypes) {
      if (getCombinedStormTotal(baseStorm) > 0) {
        typesWithPolicies++;
      }
    }

    return typesWithPolicies >= (_configProvider?.diversifiedAgentMinTypes ?? 6);
  }

  void _checkThreshold(StormType storm, BuildContext context) {
    // Determine the base storm type for popup purposes
    final parentStorm = PolicyData.parentStormTypes[storm];
    final baseStorm = parentStorm ?? storm;
    final total = getCombinedStormTotal(baseStorm);
    final displayName = PolicyData.stormNames[baseStorm] ?? '';

    // Check Growth Target threshold
    if (total >= growthTargetThreshold && !_shownGrowthTargetPopups.contains(baseStorm)) {
      _shownGrowthTargetPopups.add(baseStorm);

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
    if (total >= agentOfYearThreshold && !_shownAgentOfYearPopups.contains(baseStorm)) {
      _shownAgentOfYearPopups.add(baseStorm);

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
