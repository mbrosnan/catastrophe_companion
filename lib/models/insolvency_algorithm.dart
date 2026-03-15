import 'dart:math' as math;
import 'package:catastrophe_companion/models/policy_data.dart';
import 'package:catastrophe_companion/models/game_config.dart';

class InsolvencyResult {
  final double insolvencyProbability;
  final Map<int, double> payoutDistribution;
  final double expectedPayout;

  InsolvencyResult({
    required this.insolvencyProbability,
    required this.payoutDistribution,
    required this.expectedPayout,
  });
}

class InsolvencyAlgorithm {
  static InsolvencyResult calculate({
    required int playerMoney,
    required Map<StormType, int> propertyCount,
    GameConfig? config,
  }) {
    // Convert property counts to array format expected by algorithm
    // Order: snow, hurricaneOther, flood, fire, hail, tornado, hurricaneFlorida, fireCalifornia, tornadoTexas
    final propertyCounts = [
      propertyCount[StormType.snow] ?? 0,
      propertyCount[StormType.hurricaneOther] ?? 0,
      propertyCount[StormType.flood] ?? 0,
      propertyCount[StormType.fire] ?? 0,
      propertyCount[StormType.hail] ?? 0,
      propertyCount[StormType.tornado] ?? 0,
      propertyCount[StormType.hurricaneFlorida] ?? 0,
      propertyCount[StormType.fireCalifornia] ?? 0,
      propertyCount[StormType.tornadoTexas] ?? 0,
    ];

    final stormTypes = [
      StormType.snow,
      StormType.hurricaneOther,
      StormType.flood,
      StormType.fire,
      StormType.hail,
      StormType.tornado,
      StormType.hurricaneFlorida,
      StormType.fireCalifornia,
      StormType.tornadoTexas,
    ];

    // Get storm occurrences - use config if available, otherwise PolicyData
    final stormOccurrences = stormTypes.map((st) =>
      config != null
        ? config.getStormFrequency(st)
        : (PolicyData.stormOccurrenceD20[st] ?? 0)
    ).toList();

    // Get storm severities
    final stormSeverities = stormTypes.map((st) =>
      config != null
        ? config.getStormSeverity(st)
        : (PolicyData.stormSeverityD6[st] ?? [0])
    ).toList();

    // Step 1: Handle edge cases
    if (propertyCounts.every((count) => count == 0)) {
      return InsolvencyResult(
        insolvencyProbability: 0.0,
        payoutDistribution: {0: 1.0},
        expectedPayout: 0.0,
      );
    }

    if (playerMoney == 0) {
      return _handleZeroMoneyCase(propertyCounts, stormOccurrences);
    }

    // Step 2: Pre-calculate adjusted severities
    final adjustedSeverities = <List<int>>[];
    for (int i = 0; i < 9; i++) {
      adjustedSeverities.add(
        stormSeverities[i].map((severity) => severity * propertyCounts[i]).toList(),
      );
    }

    // Step 3: Initialize probability distribution
    int maxSinglePayout = 0;
    for (final severities in adjustedSeverities) {
      for (final severity in severities) {
        maxSinglePayout = math.max(maxSinglePayout, severity);
      }
    }
    final totalCap = maxSinglePayout * 9;

    // Create probability distribution array
    List<double> dp = List.filled(totalCap + 1, 0.0);
    dp[0] = 1.0;

    // Step 4: Process each storm
    // TODO: Phase 4 - properly handle state-specific storm types with their deck mechanics
    // For now, treat hurricane+florida as co-occurring, and state types as independent
    bool processedHurricane = false;

    for (int i = 0; i < 9; i++) {
      final d20Base = config?.insolvency.d20Base ?? 20;
      final pStorm = stormOccurrences[i] / d20Base.toDouble();

      if (pStorm == 0 && propertyCounts[i] == 0) continue;

      List<double> pmf = List.filled(totalCap + 1, 0.0);

      // Hurricane-Other (index 1) and Hurricane-Florida (index 6) co-occur
      if (i == 1 || i == 6) {
        if (processedHurricane) continue;

        final hoSeverities = adjustedSeverities[1];
        final hfSeverities = adjustedSeverities[6];

        pmf[0] = 1.0 - pStorm;

        final hurricaneCombinationBase = config?.insolvency.hurricaneCombinationBase ?? 36;
        for (final hoValue in hoSeverities) {
          for (final hfValue in hfSeverities) {
            final combinedPayout = hoValue + hfValue;
            if (combinedPayout < pmf.length) {
              pmf[combinedPayout] += pStorm / hurricaneCombinationBase.toDouble();
            }
          }
        }

        processedHurricane = true;
      } else {
        pmf[0] = 1.0 - pStorm;

        final d6Base = config?.insolvency.d6Base ?? 6;
        final pEach = pStorm / d6Base.toDouble();
        for (final value in adjustedSeverities[i]) {
          if (value < pmf.length) {
            pmf[value] += pEach;
          }
        }
      }

      dp = _convolve(dp, pmf, totalCap + 1);
    }

    // Step 5: Calculate insolvency probability
    double insolvencyProbability = 0.0;
    for (int i = playerMoney + 1; i <= totalCap; i++) {
      insolvencyProbability += dp[i];
    }

    double expectedPayout = 0.0;
    for (int i = 0; i <= totalCap; i++) {
      expectedPayout += i * dp[i];
    }

    final payoutDistribution = <int, double>{};
    for (int i = 0; i <= totalCap; i++) {
      if (dp[i] > 0.0001) {
        payoutDistribution[i] = dp[i];
      }
    }

    return InsolvencyResult(
      insolvencyProbability: insolvencyProbability * 100.0,
      payoutDistribution: payoutDistribution,
      expectedPayout: expectedPayout,
    );
  }

  static List<double> _convolve(List<double> dp, List<double> pmf, int maxSize) {
    final result = List.filled(math.min(dp.length + pmf.length - 1, maxSize), 0.0);

    for (int i = 0; i < dp.length; i++) {
      if (dp[i] > 0) {
        for (int j = 0; j < pmf.length; j++) {
          if (pmf[j] > 0) {
            final index = i + j;
            if (index < result.length) {
              result[index] += dp[i] * pmf[j];
            }
          }
        }
      }
    }

    return result;
  }

  static InsolvencyResult _handleZeroMoneyCase(
    List<int> propertyCounts,
    List<int> stormOccurrences,
  ) {
    double noRelevantStormProb = 1.0;

    // Hurricane-Other (index 1) and Hurricane-Florida (index 6) share occurrence
    bool hurricaneChecked = false;
    for (int i = 0; i < 9; i++) {
      if (i == 1 || i == 6) {
        if (!hurricaneChecked && (propertyCounts[1] > 0 || propertyCounts[6] > 0)) {
          noRelevantStormProb *= (1 - stormOccurrences[1] / 20.0);
          hurricaneChecked = true;
        }
      } else {
        if (propertyCounts[i] > 0 && stormOccurrences[i] > 0) {
          noRelevantStormProb *= (1 - stormOccurrences[i] / 20.0);
        }
      }
    }

    final insolvencyProb = (1 - noRelevantStormProb) * 100.0;

    return InsolvencyResult(
      insolvencyProbability: insolvencyProb,
      payoutDistribution: {
        0: noRelevantStormProb,
        1: 1 - noRelevantStormProb,
      },
      expectedPayout: 0.0,
    );
  }
}
