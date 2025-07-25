import 'package:flutter/material.dart';
import '../models/policy_data.dart';
import '../models/insolvency_algorithm.dart';
import 'policy_tracker_provider.dart';

class InsolvencyCalculatorProvider extends ChangeNotifier {
  double _currentMoney = 0;
  double _insolvencyPercentage = 0;
  Map<int, double> _payoutDistribution = {};
  double _expectedPayout = 0;
  int? _earthquakeSeverity;

  double get currentMoney => _currentMoney;
  double get insolvencyPercentage => _insolvencyPercentage;
  Map<int, double> get payoutDistribution => _payoutDistribution;
  double get expectedPayout => _expectedPayout;
  int? get earthquakeSeverity => _earthquakeSeverity;

  void setCurrentMoney(double money) {
    _currentMoney = money;
    notifyListeners();
  }

  void setEarthquakeSeverity(int? severity) {
    _earthquakeSeverity = severity;
    notifyListeners();
  }

  void calculateInsolvency(PolicyTrackerProvider tracker) {
    // Build property count map from tracker
    final propertyCount = <StormType, int>{};
    for (final storm in StormType.values) {
      propertyCount[storm] = tracker.getStormTotal(storm);
    }

    // Use the new algorithm
    final result = InsolvencyAlgorithm.calculate(
      playerMoney: _currentMoney.toInt(),
      propertyCount: propertyCount,
      earthquakeSeverity: _earthquakeSeverity,
    );

    _insolvencyPercentage = result.insolvencyProbability;
    _payoutDistribution = result.payoutDistribution;
    _expectedPayout = result.expectedPayout;
    
    notifyListeners();
  }
}