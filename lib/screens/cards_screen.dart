import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/policy_data.dart';
import '../providers/cards_provider.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CardsProvider>(
      builder: (context, cardsProvider, child) {
        final totalVP = cardsProvider.getTotalCardVictoryPoints();
        final checkedCount = cardsProvider.getCheckedCardsCount();

        return Column(
          children: [
            // Victory Points Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Card Victory Points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalVP VP',
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$checkedCount of ${CardsProvider.allCards.length} cards collected',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Cards List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Storm Agents Section
                  _buildSectionHeader('Storm Agents', Icons.person),
                  ...CardsProvider.allCards
                      .where((card) => card.isAgent)
                      .map((card) => _CardTile(card: card)),
                  const SizedBox(height: 16),
                  // Celebrity Endorsements Section
                  _buildSectionHeader('Celebrity Endorsements', Icons.star),
                  ...CardsProvider.allCards
                      .where((card) => !card.isAgent)
                      .map((card) => _CardTile(card: card)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final VictoryCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final cardsProvider = Provider.of<CardsProvider>(context);
    final isChecked = cardsProvider.isCardChecked(card.name);
    
    Color? tileColor;
    Color? iconColor;
    
    if (card.isAgent && card.agentStorm != null) {
      final stormColor = PolicyData.stormColors[card.agentStorm!] ?? Colors.grey;
      iconColor = stormColor == Colors.yellow ? Colors.orange[800]! : stormColor;
      final backgroundColor = PolicyData.stormBackgroundColors[card.agentStorm!];
      if (isChecked) {
        // Use custom background color if available, otherwise use storm color
        tileColor = backgroundColor != null 
            ? backgroundColor.withOpacity(0.3)
            : stormColor.withOpacity(0.1);
      }
    } else if (!card.isAgent) {
      iconColor = Colors.amber;
      if (isChecked) {
        tileColor = Colors.amber.withOpacity(0.1);
      }
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (_) => cardsProvider.toggleCard(card.name),
        title: Text(
          card.name,
          style: TextStyle(
            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
            decoration: isChecked ? TextDecoration.none : null,
          ),
        ),
        subtitle: Text(
          '${card.victoryPoints} Victory Points',
          style: TextStyle(
            color: isChecked ? Colors.green[700] : Colors.grey[600],
            fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        secondary: Icon(
          card.isAgent ? _getStormIcon(card.agentStorm!) : Icons.star,
          color: iconColor,
          size: 32,
        ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: iconColor,
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