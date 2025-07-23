import 'package:flutter/material.dart';
import '../models/policy_data.dart';
import 'policy_tracker_provider.dart';

class PayoutCalculatorProvider extends ChangeNotifier {
  final Map<StormType, int> _selectedPayouts = {};
  bool _billionaireBailout = false;

  PayoutCalculatorProvider() {
    // Initialize all payouts to 0
    for (final storm in StormType.values) {
      _selectedPayouts[storm] = 0;
    }
  }

  bool get billionaireBailout => _billionaireBailout;

  void setBillionaireBailout(bool value) {
    _billionaireBailout = value;
    notifyListeners();
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
      final stormPolicies = _getStormPolicyCount(tracker, storm);
      total += payout * stormPolicies;
    }
    return total;
  }

  int _getStormPolicyCount(PolicyTrackerProvider tracker, StormType storm) {
    if (_billionaireBailout) {
      // Exclude mansions, only count houses and mobile homes
      return tracker.getPolicyCount(storm, PropertyType.house) +
             tracker.getPolicyCount(storm, PropertyType.mobileHome);
    } else {
      // Count all properties
      return tracker.getStormTotal(storm);
    }
  }

  Map<StormType, int> getStormPayouts(PolicyTrackerProvider tracker) {
    final payouts = <StormType, int>{};
    for (final storm in StormType.values) {
      final payout = _selectedPayouts[storm] ?? 0;
      final stormPolicies = _getStormPolicyCount(tracker, storm);
      payouts[storm] = payout * stormPolicies;
    }
    return payouts;
  }
}