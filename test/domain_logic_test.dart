// Domain-logic unit tests for Catastrophe Companion.
//
// Focus: the pure game math and the "state-variant counts with its parent"
// rule (Hurricane/Florida, Fire/California, Tornado/Texas), which is the
// subtlest, highest-consequence logic in the app.
//
// Run with:  flutter test test/domain_logic_test.dart
//
// NOTE: these were authored by reading the source, not by executing them in
// this environment. Run them once to confirm; any exact-value assertion that
// fails is either an arithmetic slip in the comment derivations below OR a real
// behavior worth inspecting — which is exactly what a test is for.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:catastrophe_companion/models/policy_data.dart';
import 'package:catastrophe_companion/models/insolvency_algorithm.dart';
import 'package:catastrophe_companion/providers/policy_tracker_provider.dart';
import 'package:catastrophe_companion/providers/cards_provider.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 1. Data-model invariants (pure, no Flutter needed).
  //    These guard against drift — e.g. they'd have caught the 8→9 storm-type
  //    growth that left CLAUDE.md describing "24 policy types" when there are 27.
  // ---------------------------------------------------------------------------
  group('PolicyData invariants', () {
    test('there are 9 storm types and 3 property types (27 policy combos)', () {
      expect(StormType.values.length, 9);
      expect(PropertyType.values.length, 3);
      expect(StormType.values.length * PropertyType.values.length, 27);
    });

    test('every storm has a name and a color; every property has a name', () {
      for (final s in StormType.values) {
        expect(PolicyData.stormNames.containsKey(s), isTrue, reason: 'name for $s');
        expect(PolicyData.stormColors.containsKey(s), isTrue, reason: 'color for $s');
      }
      for (final p in PropertyType.values) {
        expect(PolicyData.propertyNames.containsKey(p), isTrue, reason: 'name for $p');
      }
    });

    test('base + state storm types partition all storm types (6 + 3 = 9)', () {
      expect(PolicyData.baseStormTypes.length, 6);
      expect(PolicyData.stateStormTypes.length, 3);
      final union = {...PolicyData.baseStormTypes, ...PolicyData.stateStormTypes};
      expect(union, StormType.values.toSet());
      // disjoint
      final intersection = PolicyData.baseStormTypes.toSet()
          .intersection(PolicyData.stateStormTypes.toSet());
      expect(intersection, isEmpty);
    });

    test('every state-specific storm maps to a base storm parent', () {
      expect(PolicyData.parentStormTypes.keys.toSet(),
          PolicyData.stateStormTypes.toSet());
      for (final parent in PolicyData.parentStormTypes.values) {
        expect(PolicyData.baseStormTypes.contains(parent), isTrue,
            reason: '$parent should be a base storm');
      }
      // documented pairings
      expect(PolicyData.parentStormTypes[StormType.hurricaneFlorida],
          StormType.hurricaneOther);
      expect(PolicyData.parentStormTypes[StormType.fireCalifornia], StormType.fire);
      expect(PolicyData.parentStormTypes[StormType.tornadoTexas], StormType.tornado);
    });

    test('the policy value table covers all 27 storm/property combinations', () {
      expect(PolicyData.policyValues.length, 27);
      for (final s in StormType.values) {
        for (final p in PropertyType.values) {
          expect(PolicyData.policyValues.containsKey(PolicyKey(s, p)), isTrue,
              reason: 'missing value for ($s, $p)');
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 2. CardsProvider (pure — no BuildContext dependency).
  // ---------------------------------------------------------------------------
  group('CardsProvider', () {
    test('starts with no cards checked and zero points', () {
      final cards = CardsProvider();
      expect(cards.getCheckedCardsCount(), 0);
      expect(cards.getTotalCardVictoryPoints(), 0);
    });

    test('toggling a card flips its state and is reversible', () {
      final cards = CardsProvider();
      expect(cards.isCardChecked('Snow Agent'), isFalse);
      cards.toggleCard('Snow Agent');
      expect(cards.isCardChecked('Snow Agent'), isTrue);
      expect(cards.getCheckedCardsCount(), 1);
      cards.toggleCard('Snow Agent');
      expect(cards.isCardChecked('Snow Agent'), isFalse);
      expect(cards.getCheckedCardsCount(), 0);
    });

    test('victory points sum across checked cards (fallback values)', () {
      final cards = CardsProvider();
      cards.toggleCard('Snow Agent'); // 10
      cards.toggleCard('Major Celebrity Endorsement'); // 20
      expect(cards.getTotalCardVictoryPoints(), 30);
      expect(cards.getCheckedCardsCount(), 2);
    });

    test('the Loan card subtracts its configured VP cost', () {
      final cards = CardsProvider();
      cards.setLoanVPCost(15);
      cards.toggleCard('Loan');
      expect(cards.getTotalCardVictoryPoints(), -15);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. PolicyTrackerProvider — counting + the state-variant ("combined") rule.
  //
  //    Pure parts (no context) are plain test()s. Exercising increment()
  //    requires a BuildContext (it shows threshold popups), so those live in a
  //    testWidgets block. The need for a context here is a testability smell —
  //    see 09-testing.md's "refactor for testability" note.
  // ---------------------------------------------------------------------------
  group('PolicyTrackerProvider (pure)', () {
    test('fresh provider: all counts zero, no cards earned', () {
      final p = PolicyTrackerProvider();
      expect(p.getPolicyCount(StormType.snow, PropertyType.house), 0);
      expect(p.getStormTotal(StormType.hurricaneOther), 0);
      expect(p.getCombinedStormTotal(StormType.hurricaneOther), 0);
      expect(p.hasGrowthTargetCard(StormType.hurricaneOther), isFalse);
      expect(p.hasDiversifiedAgent(), isFalse);
    });

    test('decrement floors at zero (never goes negative)', () {
      final p = PolicyTrackerProvider();
      p.decrementPolicy(StormType.snow, PropertyType.house);
      expect(p.getPolicyCount(StormType.snow, PropertyType.house), 0);
    });

    test('state-variant buttons never show their own card icon', () {
      final p = PolicyTrackerProvider();
      // hasGrowthTargetCard/hasAgentOfYearCard return false for state types by
      // design (the icon belongs on the parent base storm button).
      expect(p.hasGrowthTargetCard(StormType.hurricaneFlorida), isFalse);
      expect(p.hasAgentOfYearCard(StormType.fireCalifornia), isFalse);
    });
  });

  group('PolicyTrackerProvider (combined rule via increment)', () {
    testWidgets('Florida policies count toward the Hurricane combined total '
        'and trigger the parent Growth Target', (tester) async {
      final p = PolicyTrackerProvider();
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ));

      // 1 base Hurricane policy → combined total 1 (< growth threshold 2).
      p.incrementPolicy(StormType.hurricaneOther, PropertyType.house, ctx);
      expect(p.getCombinedStormTotal(StormType.hurricaneOther), 1);
      expect(p.hasGrowthTargetCard(StormType.hurricaneOther), isFalse);

      // 1 Florida policy → it's tracked separately for its own total...
      p.incrementPolicy(StormType.hurricaneFlorida, PropertyType.mansion, ctx);
      expect(p.getStormTotal(StormType.hurricaneOther), 1);
      expect(p.getStormTotal(StormType.hurricaneFlorida), 1);
      // ...but counts WITH the parent for the combined total → now 2.
      expect(p.getCombinedStormTotal(StormType.hurricaneOther), 2);

      // Combined total 2 ≥ default Growth Target threshold (2) → parent earns it,
      // and the popup fires (default threshold because no GameConfig is wired in).
      expect(p.hasGrowthTargetCard(StormType.hurricaneOther), isTrue);

      // The increment showed a Growth Target dialog; flush and dismiss it.
      await tester.pumpAndSettle();
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK').first);
        await tester.pumpAndSettle();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // 4. InsolvencyAlgorithm — the crown jewel. Pure static function.
  //
  //    Defaults used when no GameConfig is passed (from PolicyData):
  //      d20 frequencies: snow 10, hurricane 4, flood 5, fire 4, hail 7, tornado 6  (/20)
  //      snow severity D6: [5,5,5,10,10,25]  → mean 10
  //    Worked example below for {snow: 1}.
  // ---------------------------------------------------------------------------
  group('InsolvencyAlgorithm', () {
    test('no policies → certain solvency, zero expected payout', () {
      final r = InsolvencyAlgorithm.calculate(
        playerMoney: 0,
        propertyCount: const {},
      );
      expect(r.insolvencyProbability, closeTo(0.0, 1e-9));
      expect(r.expectedPayout, closeTo(0.0, 1e-9));
    });

    test('single snow policy: exact expected payout and insolvency odds', () {
      // pSnow = 10/20 = 0.5. Snow severities [5,5,5,10,10,25] (mean 10).
      // E[payout] = pSnow * mean_severity * count = 0.5 * 10 * 1 = 5.0
      // Distribution: P(0)=0.5, P(5)=0.25, P(10)=0.1667, P(25)=0.0833
      final snow1 = {StormType.snow: 1};

      final rich = InsolvencyAlgorithm.calculate(
          playerMoney: 100, propertyCount: snow1);
      expect(rich.expectedPayout, closeTo(5.0, 1e-6));
      expect(rich.insolvencyProbability, closeTo(0.0, 1e-6)); // can't lose >25

      // With $4: insolvent iff payout ≥ 5 → P = 0.25+0.1667+0.0833 = 0.5 → 50%.
      final broke = InsolvencyAlgorithm.calculate(
          playerMoney: 4, propertyCount: snow1);
      expect(broke.insolvencyProbability, closeTo(50.0, 1e-6));

      // With $0 (special-cased): insolvent iff snow occurs at all → 50%.
      final zero = InsolvencyAlgorithm.calculate(
          playerMoney: 0, propertyCount: snow1);
      expect(zero.insolvencyProbability, closeTo(50.0, 1e-6));
    });

    test('payout distribution is a proper probability distribution', () {
      final r = InsolvencyAlgorithm.calculate(
          playerMoney: 100, propertyCount: {StormType.snow: 1});
      final sum = r.payoutDistribution.values.fold<double>(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-6));
    });

    test('insolvency probability is monotonically non-increasing in money', () {
      final policies = {StormType.snow: 1};
      double prev = 101.0;
      for (final money in [0, 4, 10, 100]) {
        final r = InsolvencyAlgorithm.calculate(
            playerMoney: money, propertyCount: policies);
        expect(r.insolvencyProbability, lessThanOrEqualTo(prev + 1e-9),
            reason: 'money=$money should not raise insolvency vs less money');
        expect(r.insolvencyProbability, inInclusiveRange(0.0, 100.0));
        prev = r.insolvencyProbability;
      }
    });

    test('adding a Florida policy increases expected payout (state variant adds risk)',
        () {
      // Metamorphic: Florida stacks on top of the base hurricane payout, so
      // expected payout must strictly increase when we add it.
      final base = InsolvencyAlgorithm.calculate(
          playerMoney: 1000, propertyCount: {StormType.hurricaneOther: 1});
      final withFl = InsolvencyAlgorithm.calculate(
          playerMoney: 1000, propertyCount: {
        StormType.hurricaneOther: 1,
        StormType.hurricaneFlorida: 1,
      });
      expect(withFl.expectedPayout, greaterThan(base.expectedPayout));
    });

    test('more policies never reduce expected payout (monotonic in counts)', () {
      final few = InsolvencyAlgorithm.calculate(
          playerMoney: 1000, propertyCount: {StormType.fire: 1});
      final more = InsolvencyAlgorithm.calculate(
          playerMoney: 1000, propertyCount: {StormType.fire: 3});
      expect(more.expectedPayout, greaterThan(few.expectedPayout));
    });

    test('results stay well-formed across a spread of inputs (invariants)', () {
      final samples = <Map<StormType, int>>[
        {StormType.tornado: 2, StormType.tornadoTexas: 1}, // exercises the TX flip path
        {StormType.fire: 1, StormType.fireCalifornia: 2},
        {StormType.snow: 1, StormType.flood: 1, StormType.hail: 1},
        {for (final s in StormType.values) s: 1}, // one of everything
      ];
      for (final sample in samples) {
        final r = InsolvencyAlgorithm.calculate(
            playerMoney: 50, propertyCount: sample);
        expect(r.insolvencyProbability, inInclusiveRange(0.0, 100.0),
            reason: 'prob out of range for $sample');
        expect(r.expectedPayout, greaterThanOrEqualTo(0.0),
            reason: 'negative expected payout for $sample');
      }
    });
  });
}
