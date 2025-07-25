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
                      const Text(
                        'Earthquake Severity (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        value: calculator.earthquakeSeverity,
                        decoration: InputDecoration(
                          hintText: 'Use default probabilities',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Default (varies by dice roll)'),
                          ),
                          ...List.generate(10, (index) {
                            final value = (index + 1) * 5;
                            return DropdownMenuItem<int?>(
                              value: value,
                              child: Text('\$$value'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          calculator.setEarthquakeSeverity(value);
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
              
              // Expected Payout
              if (calculator.expectedPayout > 0) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Expected Payout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${calculator.expectedPayout.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
}