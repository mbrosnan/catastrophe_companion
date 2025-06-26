import 'package:flutter/material.dart';
import '../models/policy_data.dart';
import 'policy_tracker_provider.dart';

class PayoutCalculatorProvider extends ChangeNotifier {
  final Map<StormType, int> _selectedPayouts = {};

  PayoutCalculatorProvider() {
    // Initialize all payouts to 0
    for (final storm in StormType.values) {
      _selectedPayouts[storm] = 0;
    }
  }

  int getSelectedPayout(StormType storm) {
    return _selectedPayouts[storm] ?? 0;
  }

  void setSelectedPayout(StormType storm, int value) {
    _selectedPayouts[storm] = value;
    notifyListeners();
  }

  void resetAllPayouts() {
    for (final storm in StormType.values) {
      _selectedPayouts[storm] = 0;
    }
    notifyListeners();
  }

  int calculateTotalPayout(PolicyTrackerProvider tracker) {
    int total = 0;
    for (final storm in StormType.values) {
      final payout = _selectedPayouts[storm] ?? 0;
      final stormPolicies = tracker.getStormTotal(storm);
      total += payout * stormPolicies;
    }
    return total;
  }

  Map<StormType, int> getStormPayouts(PolicyTrackerProvider tracker) {
    final payouts = <StormType, int>{};
    for (final storm in StormType.values) {
      final payout = _selectedPayouts[storm] ?? 0;
      final stormPolicies = tracker.getStormTotal(storm);
      payouts[storm] = payout * stormPolicies;
    }
    return payouts;
  }
}