import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/policy_data.dart';
import '../providers/insolvency_calculator_provider.dart';
import '../providers/policy_tracker_provider.dart';

class InsolvencyCalculatorScreen extends StatefulWidget {
  const InsolvencyCalculatorScreen({super.key});

  @override
  State<InsolvencyCalculatorScreen> createState() => _InsolvencyCalculatorScreenState();
}

class _InsolvencyCalculatorScreenState extends State<InsolvencyCalculatorScreen> {
  final TextEditingController _moneyController = TextEditingController();

  @override
  void dispose() {
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InsolvencyCalculatorProvider, PolicyTrackerProvider>(
      builder: (context, calculator, tracker, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'How it works',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This calculator uses probability theory to determine '
                        'the exact chance of bankruptcy on the next turn.\n\n'
                        'Enter your current money amount, and the calculator will:\n'
                        '• Calculate probabilities for all storm combinations\n'
                        '• Compute the expected payout distribution\n'
                        '• Show the probability that payouts exceed your money',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Money Input Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Money',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _moneyController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          final money = double.tryParse(value) ?? 0;
                          calculator.setCurrentMoney(money);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: calculator.currentMoney < 0
                              ? null
                              : () {
                                  FocusScope.of(context).unfocus();
                                  calculator.calculateInsolvency(tracker);
                                },
                          icon: const Icon(Icons.calculate),
                          label: const Text(
                            'Calculate Risk',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expected Payout Distribution
              if (calculator.payoutDistribution.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expected Payout Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Expected payout: \$${calculator.expectedPayout.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _buildPayoutChart(
                            calculator.payoutDistribution,
                            calculator.currentMoney,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Results Card
              if (calculator.insolvencyPercentage >= 0 && calculator.currentMoney >= 0) ...[
                const SizedBox(height: 16),
                Card(
                  color: _getResultColor(calculator.insolvencyPercentage),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          _getResultIcon(calculator.insolvencyPercentage),
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Insolvency Risk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${calculator.insolvencyPercentage.toStringAsFixed(2)}%',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getRiskMessage(calculator.insolvencyPercentage),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Policy Summary
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Policy Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...StormType.values.map((storm) {
                        final count = tracker.getStormTotal(storm);
                        if (count == 0) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(PolicyData.stormNames[storm] ?? ''),
                              Text(
                                '$count policies',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (tracker.getStormTotal(StormType.snow) == 0 &&
                          tracker.getStormTotal(StormType.earthquake) == 0 &&
                          tracker.getStormTotal(StormType.hurricaneOther) == 0 &&
                          tracker.getStormTotal(StormType.flood) == 0 &&
                          tracker.getStormTotal(StormType.fire) == 0 &&
                          tracker.getStormTotal(StormType.hail) == 0 &&
                          tracker.getStormTotal(StormType.tornado) == 0 &&
                          tracker.getStormTotal(StormType.hurricaneFlorida) == 0)
                        const Text(
                          'No policies yet',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getResultColor(double percentage) {
    if (percentage < 10) return Colors.green;
    if (percentage < 30) return Colors.orange;
    if (percentage < 50) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getResultIcon(double percentage) {
    if (percentage < 10) return Icons.check_circle;
    if (percentage < 30) return Icons.warning;
    return Icons.error;
  }

  String _getRiskMessage(double percentage) {
    if (percentage == 0) return 'No risk of bankruptcy';
    if (percentage < 10) return 'Low risk - You\'re in good shape';
    if (percentage < 30) return 'Moderate risk - Consider your options';
    if (percentage < 50) return 'High risk - Be very careful';
    if (percentage < 100) return 'Very high risk - Bankruptcy likely';
    return 'Guaranteed bankruptcy!';
  }

  Widget _buildPayoutChart(Map<int, double> distribution, double playerMoney) {
    if (distribution.isEmpty) return const SizedBox();

    // Find min and max payouts
    final payouts = distribution.keys.toList()..sort();
    final minPayout = payouts.first;
    var maxPayout = payouts.last;
    
    // Ensure the chart shows at least up to the player's money
    if (playerMoney > maxPayout) {
      maxPayout = playerMoney.toInt();
    }
    
    // Create buckets for grouping
    const int targetBuckets = 20;
    final range = maxPayout - minPayout;
    final bucketSize = range > targetBuckets ? (range / targetBuckets).ceil() : 1;
    
    // Group payouts into buckets
    final buckets = <int, double>{};
    for (final entry in distribution.entries) {
      final bucketIndex = ((entry.key - minPayout) / bucketSize).floor() * bucketSize + minPayout;
      buckets[bucketIndex] = (buckets[bucketIndex] ?? 0) + entry.value;
    }
    
    final maxProbability = buckets.values.reduce((a, b) => a > b ? a : b);
    final sortedBuckets = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Calculate appropriate bar width based on label length
    final maxLabelLength = bucketSize > 1 
        ? '\$${maxPayout}-${maxPayout + bucketSize - 1}'.length
        : '\$${maxPayout}'.length;
    final barWidth = maxLabelLength > 8 ? 60.0 : 50.0;
    
    // Calculate player money position
    final chartWidth = sortedBuckets.length * barWidth;
    final moneyPosition = playerMoney < minPayout 
        ? 0.0 
        : playerMoney > maxPayout 
            ? chartWidth 
            : ((playerMoney - minPayout) / range) * chartWidth;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            child: Stack(
              children: [
                // Bars
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sortedBuckets.map((entry) {
                    final height = (entry.value / maxProbability) * 160;
                    final isAboveMoney = entry.key > playerMoney;
                    return Container(
                      width: barWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: barWidth - 4,
                            height: height,
                            decoration: BoxDecoration(
                              color: isAboveMoney 
                                  ? Colors.red.withOpacity(0.7)
                                  : Theme.of(context).primaryColor.withOpacity(0.7),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 16,
                            child: Text(
                              bucketSize > 1 
                                  ? '\$${entry.key}-${entry.key + bucketSize - 1}'
                                  : '\$${entry.key}',
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // Money threshold line
                if (playerMoney >= minPayout && playerMoney <= maxPayout)
                  Positioned(
                    left: moneyPosition - 1,
                    top: 0,
                    bottom: 20,
                    child: Container(
                      width: 2,
                      color: Colors.black87,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\$${playerMoney.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}