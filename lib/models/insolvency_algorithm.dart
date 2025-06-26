import 'dart:math' as math;
import 'package:catastrophe_companion/models/policy_data.dart';

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
  }) {
    // Convert property counts to array format expected by algorithm
    final propertyCounts = [
      propertyCount[StormType.snow] ?? 0,
      propertyCount[StormType.earthquake] ?? 0,
      propertyCount[StormType.hurricaneOther] ?? 0,
      propertyCount[StormType.flood] ?? 0,
      propertyCount[StormType.fire] ?? 0,
      propertyCount[StormType.hail] ?? 0,
      propertyCount[StormType.tornado] ?? 0,
      propertyCount[StormType.hurricaneFlorida] ?? 0,
    ];

    // Get storm occurrences from PolicyData
    final stormOccurrences = [
      PolicyData.stormOccurrenceD20[StormType.snow]!,
      PolicyData.stormOccurrenceD20[StormType.earthquake]!,
      PolicyData.stormOccurrenceD20[StormType.hurricaneOther]!,
      PolicyData.stormOccurrenceD20[StormType.flood]!,
      PolicyData.stormOccurrenceD20[StormType.fire]!,
      PolicyData.stormOccurrenceD20[StormType.hail]!,
      PolicyData.stormOccurrenceD20[StormType.tornado]!,
      PolicyData.stormOccurrenceD20[StormType.hurricaneFlorida]!,
    ];

    // Get storm severities from PolicyData
    final stormSeverities = [
      PolicyData.stormSeverityD6[StormType.snow]!,
      PolicyData.stormSeverityD6[StormType.earthquake]!,
      PolicyData.stormSeverityD6[StormType.hurricaneOther]!,
      PolicyData.stormSeverityD6[StormType.flood]!,
      PolicyData.stormSeverityD6[StormType.fire]!,
      PolicyData.stormSeverityD6[StormType.hail]!,
      PolicyData.stormSeverityD6[StormType.tornado]!,
      PolicyData.stormSeverityD6[StormType.hurricaneFlorida]!,
    ];

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
    for (int i = 0; i < 8; i++) {
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
    final totalCap = maxSinglePayout * 8;

    // Create probability distribution array
    List<double> dp = List.filled(totalCap + 1, 0.0);
    dp[0] = 1.0; // 100% probability of 0 payout initially

    // Step 4: Process each storm/die
    bool processedHurricane = false;

    for (int i = 0; i < 8; i++) {
      final pStorm = stormOccurrences[i] / 20.0;

      List<double> pmf = List.filled(totalCap + 1, 0.0);

      if (i == 2 || i == 7) {
        // Hurricane storms
        if (processedHurricane) {
          continue; // Skip, already processed both together
        }

        // Get both hurricane severities
        final hoSeverities = adjustedSeverities[2]; // Hurricane-Other
        final hfSeverities = adjustedSeverities[7]; // Hurricane-Florida

        // Create PMF for hurricane occurrence
        pmf[0] = 1.0 - pStorm; // Probability hurricane doesn't occur

        // When hurricane occurs, both storms happen
        for (final hoValue in hoSeverities) {
          for (final hfValue in hfSeverities) {
            final combinedPayout = hoValue + hfValue;
            if (combinedPayout < pmf.length) {
              pmf[combinedPayout] += pStorm / 36.0; // 6×6 = 36 combinations
            }
          }
        }

        processedHurricane = true;
      } else {
        // Regular storm
        pmf[0] = 1.0 - pStorm; // Probability storm doesn't occur

        // When storm occurs
        final pEach = pStorm / 6.0; // Each die face has 1/6 probability
        for (final value in adjustedSeverities[i]) {
          if (value < pmf.length) {
            pmf[value] += pEach;
          }
        }
      }

      // Update dp using convolution
      dp = _convolve(dp, pmf, totalCap + 1);
    }

    // Step 5: Calculate insolvency probability
    double insolvencyProbability = 0.0;
    for (int i = playerMoney + 1; i <= totalCap; i++) {
      insolvencyProbability += dp[i];
    }

    // Calculate expected payout
    double expectedPayout = 0.0;
    for (int i = 0; i <= totalCap; i++) {
      expectedPayout += i * dp[i];
    }

    // Create payout distribution map (only include non-zero probabilities)
    final payoutDistribution = <int, double>{};
    for (int i = 0; i <= totalCap; i++) {
      if (dp[i] > 0.0001) { // Include only significant probabilities
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
        // Skip zero probabilities for efficiency
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

    // Check each die
    for (int dieIdx = 0; dieIdx < 7; dieIdx++) {
      if (dieIdx == 2) {
        // Hurricane die
        if (propertyCounts[2] > 0 || propertyCounts[7] > 0) {
          // Hurricane die affects properties
          noRelevantStormProb *= (1 - stormOccurrences[2] / 20.0);
        }
      } else {
        // Other dice map directly to storms
        if (propertyCounts[dieIdx] > 0) {
          noRelevantStormProb *= (1 - stormOccurrences[dieIdx] / 20.0);
        }
      }
    }

    final insolvencyProb = (1 - noRelevantStormProb) * 100.0;
    
    // For zero money case, any payout > 0 causes insolvency
    return InsolvencyResult(
      insolvencyProbability: insolvencyProb,
      payoutDistribution: {
        0: noRelevantStormProb,
        1: 1 - noRelevantStormProb, // Simplified - any payout causes insolvency
      },
      expectedPayout: 0.0, // Not meaningful in this case
    );
  }
}