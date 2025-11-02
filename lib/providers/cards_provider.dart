import 'package:flutter/material.dart';
import '../models/policy_data.dart';
import 'game_config_provider.dart';

class VictoryCard {
  final String name;
  final int victoryPoints;
  final bool isAgent;
  final StormType? agentStorm;

  const VictoryCard({
    required this.name,
    required this.victoryPoints,
    this.isAgent = false,
    this.agentStorm,
  });
}

class CardsProvider extends ChangeNotifier {
  final Map<String, bool> _cardStates = {};
  int _loanVPCost = 0;

  // Store reference to GameConfigProvider
  GameConfigProvider? _configProvider;

  // Update the game configuration reference
  void updateGameConfig(GameConfigProvider configProvider) {
    _configProvider = configProvider;
    notifyListeners();
  }
  
  static final List<VictoryCard> allCards = [
    // Storm Agent Cards
    const VictoryCard(
      name: 'Earthquake Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.earthquake,
    ),
    const VictoryCard(
      name: 'Snow Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.snow,
    ),
    const VictoryCard(
      name: 'Hurricane Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.hurricaneOther, // Used for both hurricane types
    ),
    const VictoryCard(
      name: 'Flood Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.flood,
    ),
    const VictoryCard(
      name: 'Fire Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.fire,
    ),
    const VictoryCard(
      name: 'Hail Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.hail,
    ),
    const VictoryCard(
      name: 'Tornado Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.tornado,
    ),
    const VictoryCard(
      name: 'Diversified Agent of the Year',
      victoryPoints: 10,
      isAgent: true,
    ),
    // Celebrity Endorsement Cards
    const VictoryCard(
      name: 'Major Celebrity Endorsement',
      victoryPoints: 20,
    ),
    const VictoryCard(
      name: 'Minor Celebrity Endorsement',
      victoryPoints: 5,
    ),
    const VictoryCard(
      name: 'Loan',
      victoryPoints: 0, // VP will be handled separately
    ),
  ];

  CardsProvider() {
    // Initialize all cards as unchecked
    for (final card in allCards) {
      _cardStates[card.name] = false;
    }
  }

  bool isCardChecked(String cardName) {
    return _cardStates[cardName] ?? false;
  }

  int get loanVPCost => _loanVPCost;

  void setLoanVPCost(int cost) {
    _loanVPCost = cost;
    notifyListeners();
  }

  void toggleCard(String cardName) {
    _cardStates[cardName] = !(_cardStates[cardName] ?? false);
    notifyListeners();
  }

  int getTotalCardVictoryPoints() {
    if (_configProvider == null) {
      // Fall back to hardcoded values if config not loaded
      int total = 0;
      for (final card in allCards) {
        if (_cardStates[card.name] ?? false) {
          if (card.name == 'Loan') {
            total -= _loanVPCost;
          } else {
            total += card.victoryPoints;
          }
        }
      }
      return total;
    }

    // Use configuration values
    int total = 0;
    for (final card in allCards) {
      if (_cardStates[card.name] ?? false) {
        if (card.name == 'Loan') {
          total -= _loanVPCost;
        } else {
          // Get victory points from configuration
          int points = 0;
          if (card.name.contains('Agent')) {
            // Agent cards
            if (card.name == 'Earthquake Agent') points = _configProvider!.getCardPoints('earthquake');
            else if (card.name == 'Snow Agent') points = _configProvider!.getCardPoints('snow');
            else if (card.name == 'Hurricane Agent') points = _configProvider!.getCardPoints('hurricane');
            else if (card.name == 'Flood Agent') points = _configProvider!.getCardPoints('flood');
            else if (card.name == 'Fire Agent') points = _configProvider!.getCardPoints('fire');
            else if (card.name == 'Hail Agent') points = _configProvider!.getCardPoints('hail');
            else if (card.name == 'Tornado Agent') points = _configProvider!.getCardPoints('tornado');
            else if (card.name == 'Diversified Agent of the Year') points = _configProvider!.getCardPoints('diversified');
          } else if (card.name == 'Major Celebrity Endorsement') {
            points = _configProvider!.getCardPoints('major');
          } else if (card.name == 'Minor Celebrity Endorsement') {
            points = _configProvider!.getCardPoints('minor');
          }
          total += points;
        }
      }
    }
    return total;
  }

  int getCheckedCardsCount() {
    return _cardStates.values.where((checked) => checked).length;
  }
}