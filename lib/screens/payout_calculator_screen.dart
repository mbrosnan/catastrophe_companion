import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/policy_data.dart';
import '../providers/policy_tracker_provider.dart';
import '../providers/payout_calculator_provider.dart';

class PayoutCalculatorScreen extends StatefulWidget {
  const PayoutCalculatorScreen({super.key});

  @override
  State<PayoutCalculatorScreen> createState() => _PayoutCalculatorScreenState();
}

class _PayoutCalculatorScreenState extends State<PayoutCalculatorScreen> {
  // Track which storms have occurred and their severities
  Map<StormType, int> occurredStorms = {};
  
  // Helper to handle Hurricane Florida automatically
  void _updateHurricanes(StormType storm, int? severity) {
    if (storm == StormType.hurricaneOther) {
      if (severity == null) {
        // Remove both hurricanes
        occurredStorms.remove(StormType.hurricaneOther);
        occurredStorms.remove(StormType.hurricaneFlorida);
      } else {
        // Add/update both hurricanes
        occurredStorms[StormType.hurricaneOther] = severity;
        occurredStorms[StormType.hurricaneFlorida] = severity * 2; // Double for Florida
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PayoutCalculatorProvider, PolicyTrackerProvider>(
      builder: (context, payoutProvider, trackerProvider, child) {
        final size = MediaQuery.of(context).size;
        final isPortrait = size.height > size.width;
        
        // Calculate total payout
        int totalPayout = 0;
        occurredStorms.forEach((storm, severity) {
          final stormTotal = payoutProvider.billionaireBailout
              ? (trackerProvider.getPolicyCount(storm, PropertyType.house) +
                 trackerProvider.getPolicyCount(storm, PropertyType.mobileHome))
              : trackerProvider.getStormTotal(storm);
          totalPayout += stormTotal * severity;
        });

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header with total payout and clear button
                _buildHeader(totalPayout),
                const Divider(height: 1),
                
                // Main content - different layout based on orientation
                Expanded(
                  child: isPortrait
                      ? _buildPortraitLayout(trackerProvider, payoutProvider)
                      : _buildLandscapeLayout(trackerProvider, payoutProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int totalPayout) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Payout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total Payout:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            '\$$totalPayout',
            style: TextStyle(
              fontSize: 24,
              color: totalPayout > 0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                occurredStorms.clear();
              });
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(PolicyTrackerProvider trackerProvider, PayoutCalculatorProvider payoutProvider) {
    return Column(
      children: [
        // Storms that did not occur
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Storms That Did Not Occur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: _buildUnoccurredStorms(trackerProvider),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1, thickness: 1),
        
        // Storms that occurred
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Storms That Occurred',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: _buildOccurredStorms(trackerProvider, payoutProvider),
              ),
              // Billionaire bailout checkbox
              CheckboxListTile(
                title: const Text(
                  'Billionaire Bailout',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Mansions do not add to payout',
                  style: TextStyle(fontSize: 11),
                ),
                value: payoutProvider.billionaireBailout,
                onChanged: (value) {
                  if (value != null) {
                    payoutProvider.setBillionaireBailout(value);
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(PolicyTrackerProvider trackerProvider, PayoutCalculatorProvider payoutProvider) {
    return Row(
      children: [
        // Left side - Storms that did not occur
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Storms That Did Not Occur',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: _buildUnoccurredStorms(trackerProvider),
              ),
            ],
          ),
        ),
        
        const VerticalDivider(width: 1, thickness: 1),
        
        // Right side - Storms that occurred
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Storms That Occurred',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: _buildOccurredStorms(trackerProvider, payoutProvider),
              ),
              // Billionaire bailout checkbox
              CheckboxListTile(
                title: const Text(
                  'Billionaire Bailout',
                  style: TextStyle(fontSize: 13),
                ),
                subtitle: const Text(
                  'Mansions do not add to payout',
                  style: TextStyle(fontSize: 11),
                ),
                value: payoutProvider.billionaireBailout,
                onChanged: (value) {
                  if (value != null) {
                    payoutProvider.setBillionaireBailout(value);
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnoccurredStorms(PolicyTrackerProvider trackerProvider) {
    final unoccurredStorms = StormType.values.where((storm) => !occurredStorms.containsKey(storm)).toList();
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    
    // Pad with empty containers if needed to maintain grid
    final List<Widget> gridItems = [];
    for (int i = 0; i < 8; i++) {
      if (i < unoccurredStorms.length) {
        gridItems.add(_buildStormButton(unoccurredStorms[i], trackerProvider, false));
      } else {
        gridItems.add(Container()); // Empty space
      }
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.count(
        crossAxisCount: 4,
        childAspectRatio: isLandscape ? 1.0 : 1.25,  // Square in landscape, wider in portrait
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: gridItems,
      ),
    );
  }

  Widget _buildOccurredStorms(PolicyTrackerProvider trackerProvider, PayoutCalculatorProvider payoutProvider) {
    if (occurredStorms.isEmpty) {
      return const Center(
        child: Text(
          'No storms have occurred yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // Build list of occurred storm widgets
    final occurredStormWidgets = occurredStorms.entries.map((entry) {
      final storm = entry.key;
      final severity = entry.value;
      final stormTotal = payoutProvider.billionaireBailout
          ? (trackerProvider.getPolicyCount(storm, PropertyType.house) +
             trackerProvider.getPolicyCount(storm, PropertyType.mobileHome))
          : trackerProvider.getStormTotal(storm);
      final payout = stormTotal * severity;

      return _buildOccurredStormButton(storm, trackerProvider, severity, stormTotal, payout);
    }).toList();
    
    // Pad with empty containers to maintain 4x2 grid
    final List<Widget> gridItems = [];
    for (int i = 0; i < 8; i++) {
      if (i < occurredStormWidgets.length) {
        gridItems.add(occurredStormWidgets[i]);
      } else {
        gridItems.add(Container()); // Empty space
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.count(
        crossAxisCount: 4,
        childAspectRatio: isLandscape ? 0.85 : 1.1,  // Taller in landscape, wider in portrait
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: gridItems,
      ),
    );
  }
  
  Widget _buildOccurredStormButton(StormType storm, PolicyTrackerProvider trackerProvider, int severity, int stormTotal, int payout) {
    final stormColor = _getStormColor(storm);
    
    return GestureDetector(
      onTap: storm != StormType.hurricaneFlorida ? () => _showRemoveConfirmation(storm) : null,
      child: Container(
        decoration: BoxDecoration(
          color: stormColor.withOpacity(0.1),
          border: Border.all(
            color: stormColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        _getStormIcon(storm),
                        color: stormColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storm == StormType.hurricaneFlorida 
                            ? 'Hurricane\nFL'
                            : _getStormName(storm),
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Policy count circle
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: stormColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        stormTotal.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$stormTotal×\$$severity',
              style: const TextStyle(
                fontSize: 10,
              ),
            ),
            Text(
              '=\$$payout',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStormButton(StormType storm, PolicyTrackerProvider trackerProvider, bool isOccurred) {
    final totalPolicies = trackerProvider.getStormTotal(storm);
    final stormColor = isOccurred ? _getStormColor(storm) : _getStormColor(storm).withOpacity(0.5);
    final isHurricaneFlorida = storm == StormType.hurricaneFlorida;

    return GestureDetector(
      onTap: () {
        // Hurricane Florida is not clickable
        if (!isOccurred && !isHurricaneFlorida) {
          _showSeverityDialog(storm);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: stormColor.withOpacity(isHurricaneFlorida && !isOccurred ? 0.05 : 0.1),
          border: Border.all(
            color: isHurricaneFlorida && !isOccurred ? stormColor.withOpacity(0.3) : stormColor,
            width: isOccurred ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStormIcon(storm),
                    color: stormColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    storm == StormType.hurricaneFlorida 
                        ? 'Hurricane\nFL'
                        : _getStormName(storm),
                    style: TextStyle(
                      fontSize: 10,
                      color: isOccurred ? Colors.black : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Policy count circle
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: stormColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    totalPolicies.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeverityDialog(StormType storm) {
    final payoutOptions = PolicyData.stormPayouts[storm] ?? [0];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select ${_getStormName(storm)} Severity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: payoutOptions.where((payout) => payout > 0).map((payout) {
              return ListTile(
                title: Text('\$$payout'),
                onTap: () {
                  setState(() {
                    _updateHurricanes(storm, payout);
                    if (storm != StormType.hurricaneOther) {
                      occurredStorms[storm] = payout;
                    }
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveConfirmation(StormType storm) {
    // Don't allow removing Hurricane Florida directly
    if (storm == StormType.hurricaneFlorida) {
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Storm?'),
          content: Text('Are you sure you want to remove ${_getStormName(storm)} from occurred storms?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (storm == StormType.hurricaneOther) {
                    _updateHurricanes(storm, null);
                  } else {
                    occurredStorms.remove(storm);
                  }
                });
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Color _getStormColor(StormType stormType) {
    switch (stormType) {
      case StormType.snow:
        return Colors.blue.shade200;
      case StormType.earthquake:
        return const Color(0xFF6D4C41);  // More distinct brown
      case StormType.hurricaneOther:
        return Colors.purple.shade300;
      case StormType.flood:
        return Colors.blue;
      case StormType.fire:
        return Colors.red;
      case StormType.hail:
        return Colors.yellow.shade700;
      case StormType.tornado:
        return Colors.grey;
      case StormType.hurricaneFlorida:
        return Colors.purple.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStormIcon(StormType stormType) {
    switch (stormType) {
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
      default:
        return Icons.warning;
    }
  }

  String _getStormName(StormType stormType) {
    switch (stormType) {
      case StormType.snow:
        return 'Snow';
      case StormType.earthquake:
        return 'Earthquake';
      case StormType.hurricaneOther:
        return 'Hurricane';
      case StormType.flood:
        return 'Flood';
      case StormType.fire:
        return 'Fire';
      case StormType.hail:
        return 'Hail';
      case StormType.tornado:
        return 'Tornado';
      case StormType.hurricaneFlorida:
        return 'Hurricane FL';
      default:
        return '';
    }
  }
}