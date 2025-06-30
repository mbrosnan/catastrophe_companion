import 'package:flutter/material.dart';
import '../models/policy_data.dart';

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
  
  static final List<VictoryCard> allCards = [
    // Storm Agent Cards
    const VictoryCard(
      name: 'Snow Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.snow,
    ),
    const VictoryCard(
      name: 'Earthquake Agent',
      victoryPoints: 10,
      isAgent: true,
      agentStorm: StormType.earthquake,
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
    // Celebrity Endorsement Cards
    const VictoryCard(
      name: 'Major Celebrity Endorsement',
      victoryPoints: 20,
    ),
    const VictoryCard(
      name: 'Minor Celebrity Endorsement',
      victoryPoints: 5,
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

  void toggleCard(String cardName) {
    _cardStates[cardName] = !(_cardStates[cardName] ?? false);
    notifyListeners();
  }

  int getTotalCardVictoryPoints() {
    int total = 0;
    for (final card in allCards) {
      if (_cardStates[card.name] ?? false) {
        total += card.victoryPoints;
      }
    }
    return total;
  }

  int getCheckedCardsCount() {
    return _cardStates.values.where((checked) => checked).length;
  }
}