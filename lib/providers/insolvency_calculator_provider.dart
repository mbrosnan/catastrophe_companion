import 'package:flutter/material.dart';
import '../models/policy_data.dart';
import '../models/insolvency_algorithm.dart';
import 'policy_tracker_provider.dart';
import 'game_config_provider.dart';

class InsolvencyCalculatorProvider extends ChangeNotifier {
  double _currentMoney = 0;
  double _insolvencyPercentage = 0;
  Map<int, double> _payoutDistribution = {};
  double _expectedPayout = 0;

  // Store reference to GameConfigProvider
  GameConfigProvider? _configProvider;

  // Update the game configuration reference
  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }

  double get currentMoney => _currentMoney;
  double get insolvencyPercentage => _insolvencyPercentage;
  Map<int, double> get payoutDistribution => _payoutDistribution;
  double get expectedPayout => _expectedPayout;

  void setCurrentMoney(double money) {
    _currentMoney = money;
    notifyListeners();
  }

  void calculateInsolvency(PolicyTrackerProvider tracker) {
    if (_configProvider == null || !_configProvider!.hasConfig) {
      return;
    }

    // Build property count map from tracker
    final propertyCount = <StormType, int>{};
    for (final storm in StormType.values) {
      propertyCount[storm] = tracker.getStormTotal(storm);
    }

    final result = InsolvencyAlgorithm.calculate(
      playerMoney: _currentMoney.toInt(),
      propertyCount: propertyCount,
      config: _configProvider!.config!,
    );

    _insolvencyPercentage = result.insolvencyProbability;
    _payoutDistribution = result.payoutDistribution;
    _expectedPayout = result.expectedPayout;

    notifyListeners();
  }
}
