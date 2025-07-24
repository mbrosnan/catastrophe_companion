import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/policy_data.dart';
import '../providers/policy_tracker_provider.dart';
import '../providers/payout_calculator_provider.dart';

class PayoutCalculatorScreen extends StatelessWidget {
  const PayoutCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PayoutCalculatorProvider, PolicyTrackerProvider>(
      builder: (context, payoutProvider, trackerProvider, child) {
        final totalPayout = payoutProvider.calculateTotalPayout(trackerProvider);
        final stormPayouts = payoutProvider.getStormPayouts(trackerProvider);

        return Column(
          children: [
            // Total Payout Card
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Total Payout Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalPayout}',
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => payoutProvider.resetAllPayouts(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text(
                        'Billionaire Bailout',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Mansion properties do NOT add to the payout',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: payoutProvider.billionaireBailout,
                      onChanged: (value) {
                        if (value != null) {
                          payoutProvider.setBillionaireBailout(value);
                        }
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            // Storm Payout List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: StormType.values.length,
                itemBuilder: (context, index) {
                  final storm = StormType.values[index];
                  return _StormPayoutCard(
                    storm: storm,
                    stormPayout: stormPayouts[storm] ?? 0,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StormPayoutCard extends StatelessWidget {
  final StormType storm;
  final int stormPayout;

  const _StormPayoutCard({
    required this.storm,
    required this.stormPayout,
  });

  @override
  Widget build(BuildContext context) {
    final payoutProvider = Provider.of<PayoutCalculatorProvider>(context);
    final trackerProvider = Provider.of<PolicyTrackerProvider>(context);
    final stormTotal = payoutProvider.billionaireBailout
        ? (trackerProvider.getPolicyCount(storm, PropertyType.house) +
           trackerProvider.getPolicyCount(storm, PropertyType.mobileHome))
        : trackerProvider.getStormTotal(storm);
    final selectedPayout = payoutProvider.getSelectedPayout(storm);
    final payoutOptions = PolicyData.stormPayouts[storm] ?? [0];
    final stormColor = PolicyData.stormColors[storm] ?? Colors.grey;
    final backgroundColor = PolicyData.stormBackgroundColors[storm];
    final hasCustomBackground = backgroundColor != null;
    
    // For text and icons, always use the storm color
    final textColor = stormColor == Colors.yellow 
        ? Colors.orange[800]! 
        : stormColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: hasCustomBackground ? backgroundColor!.withOpacity(0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStormIcon(storm),
                  color: textColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: hasCustomBackground 
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : EdgeInsets.zero,
                  decoration: hasCustomBackground 
                      ? BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        )
                      : null,
                  child: Text(
                    PolicyData.stormNames[storm] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasCustomBackground 
                        ? backgroundColor!
                        : stormColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$stormTotal policies',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: storm == StormType.hurricaneFlorida
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: hasCustomBackground 
                                  ? backgroundColor!.withOpacity(0.8)
                                  : stormColor.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payout per policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$$selectedPayout (Auto: 2x Hurricane-Other)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: selectedPayout,
                          decoration: InputDecoration(
                            labelText: 'Payout per policy',
                            labelStyle: TextStyle(
                              color: textColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: hasCustomBackground 
                                    ? backgroundColor!.withOpacity(0.8)
                                    : stormColor.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: textColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: payoutOptions.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text('\$$value'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              payoutProvider.setSelectedPayout(storm, value);
                            }
                          },
                        ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Storm Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$$stormPayout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: stormPayout > 0 ? Colors.red[700] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (stormTotal > 0 && selectedPayout > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Calculation: $stormTotal policies × \$$selectedPayout = \$$stormPayout',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getStormIcon(StormType storm) {
    switch (storm) {
      case StormType.snow:
        return Icons.ac_unit;
      case StormType.earthquake:
        return Icons.landscape;
      case StormType.hurricaneOther:
      case StormType.hurricaneFlorida:
        return Icons.cyclone;
      case StormType.flood:
        return Icons.water;
      case StormType.fire:
        return Icons.local_fire_department;
      case StormType.hail:
        return Icons.grain;
      case StormType.tornado:
        return Icons.air;
    }
  }
}