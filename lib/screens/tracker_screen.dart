import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/policy_data.dart';
import '../providers/policy_tracker_provider.dart';
import '../providers/cards_provider.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PolicyTrackerProvider, CardsProvider>(
      builder: (context, tracker, cardsProvider, child) {
        final policyVP = tracker.getTotalVictoryPoints();
        final cardVP = cardsProvider.getTotalCardVictoryPoints();
        final totalVP = policyVP + cardVP;
        
        return Column(
          children: [
            // Totals Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Total Premium',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${tracker.getTotalPremium()}',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Total Victory Points',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalVP',
                          style: TextStyle(
                            fontSize: 24,
                            color: totalVP >= 0
                                ? Colors.blue
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cardVP > 0)
                          Text(
                            '($policyVP + $cardVP cards)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Policy List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: StormType.values.length,
                itemBuilder: (context, index) {
                  final storm = StormType.values[index];
                  return _StormSection(storm: storm);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StormSection extends StatelessWidget {
  final StormType storm;

  const _StormSection({required this.storm});

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<PolicyTrackerProvider>(context);
    final stormTotal = tracker.getStormTotal(storm);
    final stormColor = PolicyData.stormColors[storm] ?? Colors.grey;
    final effectiveColor = stormColor == Colors.white ? Colors.grey[300]! : stormColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStormIcon(storm),
                  color: effectiveColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  PolicyData.stormNames[storm] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: effectiveColor == Colors.yellow 
                        ? Colors.orange[800] 
                        : effectiveColor,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (tracker.hasAbilityCard(storm))
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Ability',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (tracker.hasAgentOfYearCard(storm))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Agent of Year',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ...PropertyType.values.map((property) => _PolicyRow(
                storm: storm,
                property: property,
              )),
        ],
      ),
    );
  }

  IconData _getStormIcon(StormType storm) {
    switch (storm) {
      case StormType.snow:
        return Icons.ac_unit; // Snowflake
      case StormType.earthquake:
        return Icons.landscape; // Split ground
      case StormType.hurricaneOther:
      case StormType.hurricaneFlorida:
        return Icons.cyclone; // Hurricane
      case StormType.flood:
        return Icons.water; // Waterline
      case StormType.fire:
        return Icons.local_fire_department; // Flame
      case StormType.hail:
        return Icons.grain; // Hail
      case StormType.tornado:
        return Icons.air; // Tornado
    }
  }
}

class _PolicyRow extends StatelessWidget {
  final StormType storm;
  final PropertyType property;

  const _PolicyRow({
    required this.storm,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<PolicyTrackerProvider>(context);
    final count = tracker.getPolicyCount(storm, property);
    final policyValue = PolicyData.policyValues[PolicyKey(storm, property)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Property Type
          SizedBox(
            width: 100,
            child: Text(
              PolicyData.propertyNames[property] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Premium and VP info
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'P: \$${policyValue?.premium ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'VP: ${policyValue?.victoryPoints ?? 0}',
                  style: TextStyle(
                    fontSize: 12,
                    color: (policyValue?.victoryPoints ?? 0) >= 0
                        ? Colors.blue[700]
                        : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          // Counter controls
          Row(
            children: [
              IconButton(
                onPressed: () => tracker.decrementPolicy(storm, property),
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => tracker.incrementPolicy(storm, property, context),
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}