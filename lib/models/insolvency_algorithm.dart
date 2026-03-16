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
  /// The 6 base storm types and their indices used throughout the algorithm.
  /// Order: snow(0), hurricaneOther(1), flood(2), fire(3), hail(4), tornado(5)
  static const _snow = 0;
  static const _hurricane = 1;
  static const _flood = 2;
  static const _fire = 3;
  static const _hail = 4;
  static const _tornado = 5;

  static InsolvencyResult calculate({
    required int playerMoney,
    required Map<StormType, int> propertyCount,
    GameConfig? config,
  }) {
    // Policy counts for each type
    final baseCounts = [
      propertyCount[StormType.snow] ?? 0,
      propertyCount[StormType.hurricaneOther] ?? 0,
      propertyCount[StormType.flood] ?? 0,
      propertyCount[StormType.fire] ?? 0,
      propertyCount[StormType.hail] ?? 0,
      propertyCount[StormType.tornado] ?? 0,
    ];
    final flCount = propertyCount[StormType.hurricaneFlorida] ?? 0;
    final caCount = propertyCount[StormType.fireCalifornia] ?? 0;
    final txCount = propertyCount[StormType.tornadoTexas] ?? 0;

    // Storm frequencies (out of D20)
    final baseStorms = [
      StormType.snow, StormType.hurricaneOther, StormType.flood,
      StormType.fire, StormType.hail, StormType.tornado,
    ];
    final d20Base = config?.insolvency.d20Base ?? 20;
    final frequencies = baseStorms.map((st) =>
      config != null ? config.getStormFrequency(st) : (PolicyData.stormOccurrenceD20[st] ?? 0)
    ).toList();

    // Storm severities (D6 outcomes)
    final severities = baseStorms.map((st) =>
      config != null ? config.getStormSeverity(st) : (PolicyData.stormSeverityD6[st] ?? [0])
    ).toList();

    // Edge case: no policies at all
    final allCounts = [...baseCounts, flCount, caCount, txCount];
    if (allCounts.every((c) => c == 0)) {
      return InsolvencyResult(
        insolvencyProbability: 0.0,
        payoutDistribution: {0: 1.0},
        expectedPayout: 0.0,
      );
    }

    // Precompute deck probability distributions
    final flAdditionDist = _computeFloridaAdditionDist(config);
    final caAdditionDist = _computeCaliforniaAdditionDist(config);
    final txFlipOptions = _getTornadoTexasFlipOptions(config);

    // Estimate max payout for array sizing
    int maxPayout = 0;
    for (int i = 0; i < 6; i++) {
      final maxSev = severities[i].isEmpty ? 0 : severities[i].reduce(math.max);
      maxPayout += maxSev * baseCounts[i];
    }
    // FL: max base hurricane severity + max FL addition
    if (flCount > 0) {
      final maxHurSev = severities[_hurricane].isEmpty ? 0 : severities[_hurricane].reduce(math.max);
      final maxFlAdd = flAdditionDist.keys.isEmpty ? 0 : flAdditionDist.keys.reduce(math.max);
      maxPayout += (maxHurSev + maxFlAdd) * flCount;
    }
    // CA: max base fire severity + max CA addition
    if (caCount > 0) {
      final maxFireSev = severities[_fire].isEmpty ? 0 : severities[_fire].reduce(math.max);
      final maxCaAdd = caAdditionDist.keys.isEmpty ? 0 : caAdditionDist.keys.reduce(math.max);
      maxPayout += (maxFireSev + maxCaAdd) * caCount;
    }
    // TX: max tornado severity + max other storm severity
    if (txCount > 0) {
      final maxTorSev = severities[_tornado].isEmpty ? 0 : severities[_tornado].reduce(math.max);
      int maxOtherSev = 0;
      for (int i = 0; i < 6; i++) {
        if (i == _tornado) continue;
        final ms = severities[i].isEmpty ? 0 : severities[i].reduce(math.max);
        maxOtherSev = math.max(maxOtherSev, ms);
      }
      maxPayout += (maxTorSev + maxOtherSev) * txCount;
    }
    final totalCap = maxPayout + 1;

    if (playerMoney == 0) {
      return _handleZeroMoneyCase(baseCounts, flCount, caCount, txCount, frequencies, d20Base);
    }

    // Build the payout distribution via convolution.
    // Process storms in groups:
    //   1. Independent base storms (snow, flood, hail) — no state variants
    //   2. Hurricane + Florida (joint)
    //   3. Fire + California (joint)
    //   4. Tornado + Texas (conditional on flip, averaged over 6 flip outcomes)

    List<double> dp = List.filled(totalCap, 0.0);
    dp[0] = 1.0;
    final d6 = config?.insolvency.d6Base ?? 6;

    // --- 1. Independent storms: snow, flood, hail ---
    for (final idx in [_snow, _flood, _hail]) {
      if (baseCounts[idx] == 0) continue;
      final pStorm = frequencies[idx] / d20Base.toDouble();
      if (pStorm == 0) continue;

      List<double> pmf = List.filled(totalCap, 0.0);
      pmf[0] = 1.0 - pStorm;
      final pEach = pStorm / d6.toDouble();
      for (final sev in severities[idx]) {
        final payout = sev * baseCounts[idx];
        if (payout < totalCap) pmf[payout] += pEach;
      }
      dp = _convolve(dp, pmf, totalCap);
    }

    // --- 2. Hurricane + Florida (joint) ---
    {
      final hurCount = baseCounts[_hurricane];
      final pHur = frequencies[_hurricane] / d20Base.toDouble();
      if ((hurCount > 0 || flCount > 0) && pHur > 0) {
        List<double> pmf = List.filled(totalCap, 0.0);
        pmf[0] = 1.0 - pHur;

        // When hurricane occurs: roll D6 for base severity
        for (final baseSev in severities[_hurricane]) {
          final hurPayout = baseSev * hurCount;

          if (flCount > 0) {
            // For each FL addition value, compute combined payout
            for (final entry in flAdditionDist.entries) {
              final flAdd = entry.key;
              final flProb = entry.value;
              final flPayout = (baseSev + flAdd) * flCount;
              final totalPay = hurPayout + flPayout;
              if (totalPay < totalCap) {
                pmf[totalPay] += pHur * (1.0 / d6) * flProb;
              }
            }
          } else {
            // No FL policies — just hurricane base
            if (hurPayout < totalCap) {
              pmf[hurPayout] += pHur * (1.0 / d6);
            }
          }
        }
        dp = _convolve(dp, pmf, totalCap);
      }
    }

    // --- 3. Fire + California (joint) ---
    {
      final fireCount = baseCounts[_fire];
      final pFire = frequencies[_fire] / d20Base.toDouble();
      if ((fireCount > 0 || caCount > 0) && pFire > 0) {
        List<double> pmf = List.filled(totalCap, 0.0);
        pmf[0] = 1.0 - pFire;

        for (final baseSev in severities[_fire]) {
          final firePayout = baseSev * fireCount;

          if (caCount > 0) {
            for (final entry in caAdditionDist.entries) {
              final caAdd = entry.key;
              final caProb = entry.value;
              final caPayout = (baseSev + caAdd) * caCount;
              final totalPay = firePayout + caPayout;
              if (totalPay < totalCap) {
                pmf[totalPay] += pFire * (1.0 / d6) * caProb;
              }
            }
          } else {
            if (firePayout < totalCap) {
              pmf[firePayout] += pFire * (1.0 / d6);
            }
          }
        }
        dp = _convolve(dp, pmf, totalCap);
      }
    }

    // --- 4. Tornado + Texas ---
    // TX flip determines which other storm (if any) adds to TX payout.
    // For each flip outcome (prob 1/6 each), we compute differently:
    //   - "noStorm": TX payout = tornado_sev * txCount, process tornado independently
    //   - storm X: TX payout = (tornado_sev + X_sev_if_occurred) * txCount
    //     This means tornado and storm X are NOT independent — must process jointly.
    //
    // But storm X was already processed independently above (for snow/flood/hail)!
    // We need to NOT process storm X independently when it's the TX flip target.
    //
    // Solution: we branch. For each flip outcome, compute the full remaining
    // distribution (tornado + possibly joint with another storm), then average.
    //
    // However, the independent storms (snow, flood, hail) were already convolved into dp.
    // If TX flip targets one of them, we'd need to undo that convolution — which is messy.
    //
    // Better approach: if txCount > 0, defer processing of ALL storms that could be
    // TX flip targets. But that means deferring snow, flood, hail, hurricane, fire too.
    //
    // Simplest correct approach: if txCount > 0, we need to handle everything together
    // by branching on the flip. Let me restructure.
    {
      final torCount = baseCounts[_tornado];
      final pTor = frequencies[_tornado] / d20Base.toDouble();

      if (txCount == 0) {
        // No TX policies — just process tornado independently
        if (torCount > 0 && pTor > 0) {
          List<double> pmf = List.filled(totalCap, 0.0);
          pmf[0] = 1.0 - pTor;
          final pEach = pTor / d6.toDouble();
          for (final sev in severities[_tornado]) {
            final payout = sev * torCount;
            if (payout < totalCap) pmf[payout] += pEach;
          }
          dp = _convolve(dp, pmf, totalCap);
        }
      } else if (pTor > 0) {
        // TX policies exist — need to handle flip outcomes.
        // The flip targets are: snow, hurricane, flood, fire, hail, noStorm.
        // The targeted storm's occurrence+severity interact with TX payout.
        //
        // Key insight: the flip outcome only matters when TORNADO occurs.
        // When tornado doesn't occur, TX pays nothing regardless of flip.
        // The flip target storm's occurrence is independent of tornado's occurrence.
        //
        // For a flip target storm X:
        //   P(tornado occurs, X occurs) = pTor * pX
        //     TX payout = (tor_sev + X_sev) * txCount
        //   P(tornado occurs, X doesn't occur) = pTor * (1 - pX)
        //     TX payout = tor_sev * txCount
        //   P(tornado doesn't occur) = (1 - pTor)
        //     TX payout = 0
        //
        // BUT: storm X's occurrence also affects storm X's own base payout
        // (already convolved into dp above). The TX addition is CONDITIONAL
        // on X occurring, and X's occurrence is already factored in.
        //
        // Actually, the issue is that storm X's base payout and TX's additional
        // payout from X are correlated (both depend on X occurring AND X's severity).
        // We already convolved X's base payout into dp independently.
        //
        // The TX addition from X is: if X occurred, add X_sev * txCount to tornado's payout.
        // Since X's occurrence and severity are already in dp, we can't just multiply.
        //
        // Correct approach: We need to go back to processing from scratch for the
        // TX-linked storm. But we already processed snow, flood, hail above.
        // Let me restructure to defer those if they could be TX flip targets.

        // Actually, let me think again more carefully.
        // The TX flip is determined at game time (draw a card). Each flip has prob 1/6.
        // For a given flip outcome (say "fire"), the TX payout when tornado occurs is:
        //   tor_sev * txCount   (if fire didn't occur)
        //   (tor_sev + fire_sev) * txCount   (if fire did occur)
        // The fire occurrence and severity are independent of tornado.
        //
        // The TOTAL payout is: base_storm_payouts + tornado_payout + TX_payout.
        // TX_payout depends on tornado occurring AND fire occurring AND both severities.
        //
        // Since we process storms via convolution (independent events), we can handle
        // the tornado+TX as a single PMF that accounts for the flip.
        //
        // For flip="fire": the tornado+TX PMF includes outcomes where:
        //   - Neither tornado nor fire occurs: payout = 0
        //   - Only tornado occurs: tornado = tor_sev*torCount, TX = tor_sev*txCount
        //   - Only fire occurs: fire payout already in dp (BUT fire+CA was already processed!)
        //   - Both occur: tornado + TX gets fire severity addition
        //
        // The problem is fire's base payout is ALREADY convolved into dp.
        // We can't undo that. But TX addition is separate — it's txCount * fire_sev
        // that only happens when BOTH tornado and fire occur.
        //
        // Actually, we CAN handle this! The TX addition is an extra payout that
        // depends on tornado AND fire both occurring. It's independent of fire's
        // base payout (which is already in dp). We just need a PMF for the
        // tornado+TX component:
        //
        // For flip="fire" (prob 1/6):
        //   P(no tornado) = (1-pTor): tornado payout = 0, TX payout = 0
        //   P(tornado, no fire) = pTor*(1-pFire):
        //     tornado payout = tor_sev*torCount, TX = tor_sev*txCount
        //   P(tornado, fire) = pTor*pFire:
        //     tornado payout = tor_sev*torCount, TX = (tor_sev + fire_sev)*txCount
        //     (fire_sev rolled independently for this purpose)
        //
        // This works because the fire severity for TX addition is an INDEPENDENT
        // roll from the fire severity that determines fire's base payout.
        // Wait — is it? In the actual game, there's one fire severity roll.
        // If fire occurs, the same severity applies to both fire base policies
        // AND to tornado texas addition.
        //
        // That means fire_sev for TX IS the same as fire_sev for base fire payout.
        // They're correlated. So I can't treat them independently.
        //
        // Hmm. This means for the "fire" flip case, I need to process fire+CA and
        // tornado+TX jointly (4-way joint), because fire_sev affects both
        // fire base payout and TX payout.
        //
        // This is the hard part. Let me handle it properly.

        // APPROACH: Average over 6 flip outcomes. For each flip outcome:
        //   - Rebuild dp from scratch for the storms that interact with TX
        //   - The non-interacting storms are already in dp... but we can't
        //     selectively undo.
        //
        // BETTER APPROACH: Don't convolve anything into dp until we handle TX.
        // Restructure so we build dp in stages:
        //   Stage A: independent storms that are NOT the TX flip target
        //   Stage B: tornado + TX + possibly the flip target storm (joint)
        // Then average over flip outcomes.
        //
        // But we already convolved stages 1-3 into dp. Let me redo.
        // I'll take the approach of branching BEFORE any convolution.
        // This means I need to restart the whole calculation.

        // For simplicity and correctness, let's restart with a clean approach.
        // We'll return from a dedicated method.
        return _calculateWithTexas(
          playerMoney: playerMoney,
          baseCounts: baseCounts,
          flCount: flCount,
          caCount: caCount,
          txCount: txCount,
          frequencies: frequencies,
          severities: severities,
          flAdditionDist: flAdditionDist,
          caAdditionDist: caAdditionDist,
          txFlipOptions: txFlipOptions,
          d20Base: d20Base,
          d6: d6,
          totalCap: totalCap,
          config: config,
        );
      }
    }

    // Finalize
    return _buildResult(dp, playerMoney, totalCap);
  }

  /// Full calculation when TX policies exist.
  /// Branches over 6 flip outcomes, processing the flip-target storm jointly
  /// with tornado+TX to capture the severity correlation.
  static InsolvencyResult _calculateWithTexas({
    required int playerMoney,
    required List<int> baseCounts,
    required int flCount,
    required int caCount,
    required int txCount,
    required List<int> frequencies,
    required List<List<int>> severities,
    required Map<int, double> flAdditionDist,
    required Map<int, double> caAdditionDist,
    required List<_TxFlipOption> txFlipOptions,
    required int d20Base,
    required int d6,
    required int totalCap,
    GameConfig? config,
  }) {
    // For each flip outcome, build the full distribution, then average.
    List<double> finalDp = List.filled(totalCap, 0.0);

    for (final flip in txFlipOptions) {
      final flipProb = flip.probability;
      final linkedStormIdx = flip.stormIndex; // -1 for noStorm

      // Start fresh dp for this flip branch
      List<double> dp = List.filled(totalCap, 0.0);
      dp[0] = 1.0;

      // Process all base storms EXCEPT tornado and the linked storm
      // (those will be processed jointly below)
      for (int idx = 0; idx < 6; idx++) {
        if (idx == _tornado) continue; // handled jointly below
        if (idx == linkedStormIdx) continue; // handled jointly below

        dp = _convolveBaseStorm(dp, idx, baseCounts, flCount, caCount,
            frequencies, severities, flAdditionDist, caAdditionDist,
            d20Base, d6, totalCap);
      }

      // Process tornado + TX + linked storm jointly
      dp = _convolveTornadoTexasJoint(dp, linkedStormIdx, baseCounts,
          flCount, caCount, txCount, frequencies, severities,
          flAdditionDist, caAdditionDist, d20Base, d6, totalCap);

      // Weight this branch by flip probability and add to final
      for (int i = 0; i < totalCap; i++) {
        finalDp[i] += dp[i] * flipProb;
      }
    }

    return _buildResult(finalDp, playerMoney, totalCap);
  }

  /// Convolve a single base storm (with its state variant if applicable) into dp.
  static List<double> _convolveBaseStorm(
    List<double> dp,
    int stormIdx,
    List<int> baseCounts,
    int flCount,
    int caCount,
    List<int> frequencies,
    List<List<int>> severities,
    Map<int, double> flAdditionDist,
    Map<int, double> caAdditionDist,
    int d20Base,
    int d6,
    int totalCap,
  ) {
    final count = baseCounts[stormIdx];
    final pStorm = frequencies[stormIdx] / d20Base.toDouble();

    if (stormIdx == _hurricane) {
      // Hurricane + Florida (joint)
      if ((count > 0 || flCount > 0) && pStorm > 0) {
        List<double> pmf = List.filled(totalCap, 0.0);
        pmf[0] = 1.0 - pStorm;
        for (final baseSev in severities[_hurricane]) {
          final hurPayout = baseSev * count;
          if (flCount > 0) {
            for (final entry in flAdditionDist.entries) {
              final flPayout = (baseSev + entry.key) * flCount;
              final total = hurPayout + flPayout;
              if (total < totalCap) pmf[total] += pStorm * (1.0 / d6) * entry.value;
            }
          } else {
            if (hurPayout < totalCap) pmf[hurPayout] += pStorm * (1.0 / d6);
          }
        }
        return _convolve(dp, pmf, totalCap);
      }
    } else if (stormIdx == _fire) {
      // Fire + California (joint)
      if ((count > 0 || caCount > 0) && pStorm > 0) {
        List<double> pmf = List.filled(totalCap, 0.0);
        pmf[0] = 1.0 - pStorm;
        for (final baseSev in severities[_fire]) {
          final firePayout = baseSev * count;
          if (caCount > 0) {
            for (final entry in caAdditionDist.entries) {
              final caPayout = (baseSev + entry.key) * caCount;
              final total = firePayout + caPayout;
              if (total < totalCap) pmf[total] += pStorm * (1.0 / d6) * entry.value;
            }
          } else {
            if (firePayout < totalCap) pmf[firePayout] += pStorm * (1.0 / d6);
          }
        }
        return _convolve(dp, pmf, totalCap);
      }
    } else {
      // Simple independent storm (snow, flood, hail)
      if (count > 0 && pStorm > 0) {
        List<double> pmf = List.filled(totalCap, 0.0);
        pmf[0] = 1.0 - pStorm;
        final pEach = pStorm / d6.toDouble();
        for (final sev in severities[stormIdx]) {
          final payout = sev * count;
          if (payout < totalCap) pmf[payout] += pEach;
        }
        return _convolve(dp, pmf, totalCap);
      }
    }
    return dp;
  }

  /// Process tornado + TX jointly with the linked storm (if any).
  /// When linkedStormIdx >= 0, the linked storm's severity is shared:
  ///   - It contributes to the linked storm's own base payout
  ///   - AND to TX's additional payout (when both tornado and linked storm occur)
  static List<double> _convolveTornadoTexasJoint(
    List<double> dp,
    int linkedStormIdx,
    List<int> baseCounts,
    int flCount,
    int caCount,
    int txCount,
    List<int> frequencies,
    List<List<int>> severities,
    Map<int, double> flAdditionDist,
    Map<int, double> caAdditionDist,
    int d20Base,
    int d6,
    int totalCap,
  ) {
    final torCount = baseCounts[_tornado];
    final pTor = frequencies[_tornado] / d20Base.toDouble();

    if (pTor == 0 && torCount == 0 && txCount == 0) {
      // Still need to process the linked storm independently if it exists
      if (linkedStormIdx >= 0) {
        return _convolveBaseStorm(dp, linkedStormIdx, baseCounts, flCount, caCount,
            frequencies, severities, flAdditionDist, caAdditionDist,
            d20Base, d6, totalCap);
      }
      return dp;
    }

    if (linkedStormIdx < 0) {
      // "noStorm" flip — tornado + TX is independent, TX payout = tor_sev * txCount
      List<double> pmf = List.filled(totalCap, 0.0);
      pmf[0] = 1.0 - pTor;
      for (final torSev in severities[_tornado]) {
        final torPayout = torSev * torCount;
        final txPayout = torSev * txCount;
        final total = torPayout + txPayout;
        if (total < totalCap) pmf[total] += pTor * (1.0 / d6);
      }
      return _convolve(dp, pmf, totalCap);
    }

    // Linked storm exists. Process tornado + linked storm + TX jointly.
    // Four cases based on which storms occur:
    final linkedCount = baseCounts[linkedStormIdx];
    final pLinked = frequencies[linkedStormIdx] / d20Base.toDouble();

    // Determine if the linked storm has a state variant (FL for hurricane, CA for fire)
    final linkedHasFL = linkedStormIdx == _hurricane && flCount > 0;
    final linkedHasCA = linkedStormIdx == _fire && caCount > 0;

    List<double> pmf = List.filled(totalCap, 0.0);

    // Case 1: Neither tornado nor linked storm occurs
    final pNeither = (1 - pTor) * (1 - pLinked);
    pmf[0] += pNeither;

    // Case 2: Only linked storm occurs (no tornado, so no TX payout)
    if (linkedCount > 0 || linkedHasFL || linkedHasCA) {
      final pOnlyLinked = (1 - pTor) * pLinked;
      _addLinkedStormPayouts(pmf, pOnlyLinked, linkedStormIdx, linkedCount,
          flCount, caCount, severities, flAdditionDist, caAdditionDist,
          d6, linkedHasFL, linkedHasCA, 0, 0);
    } else {
      pmf[0] += (1 - pTor) * pLinked;
    }

    // Case 3: Only tornado occurs (linked storm doesn't)
    {
      final pOnlyTor = pTor * (1 - pLinked);
      for (final torSev in severities[_tornado]) {
        final torPayout = torSev * torCount;
        final txPayout = torSev * txCount; // No linked storm severity
        final total = torPayout + txPayout;
        if (total < totalCap) pmf[total] += pOnlyTor * (1.0 / d6);
      }
    }

    // Case 4: Both tornado and linked storm occur
    {
      final pBoth = pTor * pLinked;
      for (final torSev in severities[_tornado]) {
        final torPayout = torSev * torCount;

        for (final linkedSev in severities[linkedStormIdx]) {
          // TX gets tornado severity + linked storm severity
          final txPayout = (torSev + linkedSev) * txCount;

          // Linked storm's own base payout
          if (linkedHasFL) {
            for (final flEntry in flAdditionDist.entries) {
              final linkedBasePayout = linkedSev * linkedCount;
              final flPayout = (linkedSev + flEntry.key) * flCount;
              final total = torPayout + txPayout + linkedBasePayout + flPayout;
              if (total < totalCap) {
                pmf[total] += pBoth * (1.0 / d6) * (1.0 / d6) * flEntry.value;
              }
            }
          } else if (linkedHasCA) {
            for (final caEntry in caAdditionDist.entries) {
              final linkedBasePayout = linkedSev * linkedCount;
              final caPayout = (linkedSev + caEntry.key) * caCount;
              final total = torPayout + txPayout + linkedBasePayout + caPayout;
              if (total < totalCap) {
                pmf[total] += pBoth * (1.0 / d6) * (1.0 / d6) * caEntry.value;
              }
            }
          } else {
            final linkedBasePayout = linkedSev * linkedCount;
            final total = torPayout + txPayout + linkedBasePayout;
            if (total < totalCap) {
              pmf[total] += pBoth * (1.0 / d6) * (1.0 / d6);
            }
          }
        }
      }
    }

    return _convolve(dp, pmf, totalCap);
  }

  /// Helper to add linked storm payouts (used in case 2: only linked storm occurs)
  static void _addLinkedStormPayouts(
    List<double> pmf,
    double baseProbability,
    int stormIdx,
    int count,
    int flCount,
    int caCount,
    List<List<int>> severities,
    Map<int, double> flAdditionDist,
    Map<int, double> caAdditionDist,
    int d6,
    bool hasFL,
    bool hasCA,
    int extraPayout, // Additional payout from TX
    int txCount,
  ) {
    for (final sev in severities[stormIdx]) {
      final basePayout = sev * count;
      if (hasFL) {
        for (final flEntry in flAdditionDist.entries) {
          final flPayout = (sev + flEntry.key) * flCount;
          final total = basePayout + flPayout + extraPayout;
          if (total < pmf.length) {
            pmf[total] += baseProbability * (1.0 / d6) * flEntry.value;
          }
        }
      } else if (hasCA) {
        for (final caEntry in caAdditionDist.entries) {
          final caPayout = (sev + caEntry.key) * caCount;
          final total = basePayout + caPayout + extraPayout;
          if (total < pmf.length) {
            pmf[total] += baseProbability * (1.0 / d6) * caEntry.value;
          }
        }
      } else {
        final total = basePayout + extraPayout;
        if (total < pmf.length) {
          pmf[total] += baseProbability * (1.0 / d6);
        }
      }
    }
  }

  // --- Deck probability distributions ---

  /// Florida addition: draw 1 card from deck [10,10,20,20,30,30].
  /// Each value has probability 2/6 = 1/3.
  static Map<int, double> _computeFloridaAdditionDist(GameConfig? config) {
    final deck = config?.decks.hurricaneFlorida ?? [10, 10, 20, 20, 30, 30];
    final dist = <int, double>{};
    for (final card in deck) {
      dist[card] = (dist[card] ?? 0) + 1.0 / deck.length;
    }
    return dist;
  }

  /// California addition: draw cards without replacement from deck
  /// [5,5,5,5,10,10,0,0] until drawing a 0. Sum of non-zero cards drawn.
  /// Returns exact probability distribution.
  static Map<int, double> _computeCaliforniaAdditionDist(GameConfig? config) {
    final deck = config?.decks.fireCalifornia ?? [5, 5, 5, 5, 10, 10, 0, 0];
    final dist = <int, double>{};

    // Enumerate by recursion: track remaining cards and accumulated sum
    void enumerate(List<int> remaining, int currentSum, double currentProb) {
      if (remaining.isEmpty) return;

      // Group identical cards to avoid redundant computation
      final cardCounts = <int, int>{};
      for (final c in remaining) {
        cardCounts[c] = (cardCounts[c] ?? 0) + 1;
      }

      final total = remaining.length;
      for (final entry in cardCounts.entries) {
        final card = entry.key;
        final count = entry.value;
        final prob = currentProb * count / total;

        if (card == 0) {
          // Drew a 0 — stop, record current sum
          dist[currentSum] = (dist[currentSum] ?? 0) + prob;
        } else {
          // Drew a non-zero card — add to sum and continue
          final newRemaining = List<int>.from(remaining);
          newRemaining.remove(card); // Remove one instance
          enumerate(newRemaining, currentSum + card, prob);
        }
      }
    }

    enumerate(deck, 0, 1.0);
    return dist;
  }

  /// Texas flip options. Each has equal probability (1/N).
  static List<_TxFlipOption> _getTornadoTexasFlipOptions(GameConfig? config) {
    final deck = config?.decks.tornadoTexas ?? ['snow', 'hurricaneOther', 'flood', 'fire', 'hail', 'noStorm'];
    final stormKeyToIdx = {
      'snow': _snow,
      'hurricaneOther': _hurricane,
      'flood': _flood,
      'fire': _fire,
      'hail': _hail,
    };
    final prob = 1.0 / deck.length;
    return deck.map((key) => _TxFlipOption(
      stormIndex: stormKeyToIdx[key] ?? -1, // -1 for noStorm
      probability: prob,
    )).toList();
  }

  // --- Utility ---

  static List<double> _convolve(List<double> dp, List<double> pmf, int maxSize) {
    final result = List.filled(maxSize, 0.0);
    for (int i = 0; i < dp.length && i < maxSize; i++) {
      if (dp[i] == 0) continue;
      for (int j = 0; j < pmf.length && j < maxSize; j++) {
        if (pmf[j] == 0) continue;
        final index = i + j;
        if (index < maxSize) {
          result[index] += dp[i] * pmf[j];
        }
      }
    }
    return result;
  }

  static InsolvencyResult _buildResult(List<double> dp, int playerMoney, int totalCap) {
    double insolvencyProbability = 0.0;
    for (int i = playerMoney + 1; i < totalCap; i++) {
      insolvencyProbability += dp[i];
    }

    double expectedPayout = 0.0;
    for (int i = 0; i < totalCap; i++) {
      expectedPayout += i * dp[i];
    }

    final payoutDistribution = <int, double>{};
    for (int i = 0; i < totalCap; i++) {
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

  static InsolvencyResult _handleZeroMoneyCase(
    List<int> baseCounts, int flCount, int caCount, int txCount,
    List<int> frequencies, int d20Base,
  ) {
    double noRelevantStormProb = 1.0;

    // Hurricane covers both hurricaneOther and Florida
    bool hurricaneMatters = baseCounts[_hurricane] > 0 || flCount > 0;
    // Fire covers both fire and California
    bool fireMatters = baseCounts[_fire] > 0 || caCount > 0;
    // Tornado covers both tornado and Texas
    bool tornadoMatters = baseCounts[_tornado] > 0 || txCount > 0;

    for (int i = 0; i < 6; i++) {
      final pStorm = frequencies[i] / d20Base.toDouble();
      if (pStorm == 0) continue;

      bool matters = false;
      if (i == _hurricane) {
        matters = hurricaneMatters;
      } else if (i == _fire) {
        matters = fireMatters;
      } else if (i == _tornado) {
        matters = tornadoMatters;
      } else {
        matters = baseCounts[i] > 0;
      }

      // TX flip: if tornado matters only because of TX, and the flip targets
      // a non-occurring storm, tornado alone still causes TX payout.
      // For zero money, any payout > 0 is insolvency, so this is correct.

      if (matters) {
        noRelevantStormProb *= (1 - pStorm);
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

class _TxFlipOption {
  final int stormIndex; // -1 for noStorm
  final double probability;

  _TxFlipOption({required this.stormIndex, required this.probability});
}
