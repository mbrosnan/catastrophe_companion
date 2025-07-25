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
                      .where((card) => !card.isAgent && card.name != 'Loan')
                      .map((card) => _CardTile(card: card)),
                  const SizedBox(height: 16),
                  // Other Cards Section
                  _buildSectionHeader('Other Cards', Icons.credit_card),
                  ...CardsProvider.allCards
                      .where((card) => card.name == 'Loan')
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
    
    if (card.isAgent) {
      if (card.name == 'Diversified Agent of the Year') {
        // Use a rainbow/multicolor theme for diversified agent
        iconColor = Colors.deepPurple;
        if (isChecked) {
          tileColor = Colors.deepPurple.withOpacity(0.1);
        }
      } else if (card.agentStorm != null) {
        final stormColor = PolicyData.stormColors[card.agentStorm!] ?? Colors.grey;
        iconColor = stormColor == Colors.yellow ? Colors.orange[800]! : stormColor;
        final backgroundColor = PolicyData.stormBackgroundColors[card.agentStorm!];
        if (isChecked) {
          // Use custom background color if available, otherwise use storm color
          tileColor = backgroundColor != null 
              ? backgroundColor.withOpacity(0.3)
              : stormColor.withOpacity(0.1);
        }
      }
    } else if (!card.isAgent) {
      if (card.name == 'Loan') {
        iconColor = Colors.red;
        if (isChecked) {
          tileColor = Colors.red.withOpacity(0.1);
        }
      } else {
        iconColor = Colors.amber;
        if (isChecked) {
          tileColor = Colors.amber.withOpacity(0.1);
        }
      }
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (_) async {
          if (card.name == 'Loan') {
            if (!isChecked) {
              // Show VP selection dialog when checking the Loan card
              final vpCost = await showDialog<int>(
                context: context,
                barrierDismissible: false,
                builder: (context) => _LoanVPDialog(),
              );
              if (vpCost != null) {
                cardsProvider.setLoanVPCost(vpCost);
                cardsProvider.toggleCard(card.name);
              }
            } else {
              // Show confirmation dialog when unchecking the Loan card
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Loan?'),
                  content: Text(
                    'Are you sure you want to remove the Loan card? You currently owe ${cardsProvider.loanVPCost} VP.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                cardsProvider.toggleCard(card.name);
                cardsProvider.setLoanVPCost(0);
              }
            }
          } else {
            cardsProvider.toggleCard(card.name);
          }
        },
        title: Text(
          card.name,
          style: TextStyle(
            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
            decoration: isChecked ? TextDecoration.none : null,
          ),
        ),
        subtitle: Text(
          card.name == 'Loan' 
              ? '${-cardsProvider.loanVPCost} Victory Points'
              : '${card.victoryPoints} Victory Points',
          style: TextStyle(
            color: card.name == 'Loan' 
                ? (isChecked ? Colors.red[700] : Colors.grey[600])
                : (isChecked ? Colors.green[700] : Colors.grey[600]),
            fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        secondary: Icon(
          card.isAgent 
              ? (card.name == 'Diversified Agent of the Year' 
                  ? Icons.diversity_3 
                  : _getStormIcon(card.agentStorm!))
              : (card.name == 'Loan' ? Icons.account_balance : Icons.star),
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

class _LoanVPDialog extends StatefulWidget {
  @override
  _LoanVPDialogState createState() => _LoanVPDialogState();
}

class _LoanVPDialogState extends State<_LoanVPDialog> {
  int _selectedVP = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Loan Amount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How many Victory Points do you want to borrow?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            'You will owe: ${_selectedVP} VP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedVP.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$_selectedVP VP',
            onChanged: (value) {
              setState(() {
                _selectedVP = value.toInt();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0 VP'),
              Text('10 VP'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedVP),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Take Loan'),
        ),
      ],
    );
  }
}