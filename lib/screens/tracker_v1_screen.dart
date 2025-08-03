import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/policy_tracker_provider.dart';
import '../models/policy_data.dart';

class TrackerV1Screen extends StatelessWidget {
  const TrackerV1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PolicyTrackerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Policy Tracker',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Total Premium:'),
                              Text(
                                '\$${provider.getTotalPremium()}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Total Victory Points:'),
                              Text(
                                '${provider.getTotalVictoryPoints()}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Storm Icons Grid
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine if we're in landscape or portrait
                      final isLandscape = constraints.maxWidth > constraints.maxHeight;
                      final crossAxisCount = isLandscape ? 4 : 2;
                      final childCount = 8;
                      
                      // Calculate the maximum size for each grid item
                      final availableWidth = constraints.maxWidth - 32; // Account for padding
                      final availableHeight = constraints.maxHeight - 32; // Account for padding
                      
                      // Calculate grid dimensions
                      final itemsPerRow = crossAxisCount;
                      final rowCount = (childCount / itemsPerRow).ceil();
                      
                      // Calculate spacing
                      final spacing = 16.0;
                      final totalSpacingWidth = (itemsPerRow - 1) * spacing;
                      final totalSpacingHeight = (rowCount - 1) * spacing;
                      
                      // Calculate item size
                      final itemWidth = (availableWidth - totalSpacingWidth) / itemsPerRow;
                      final itemHeight = (availableHeight - totalSpacingHeight) / rowCount;
                      final itemSize = itemWidth < itemHeight ? itemWidth : itemHeight;
                      
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildStormIcon(context, StormType.earthquake, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildStormIcon(context, StormType.snow, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildHurricaneIcon(context, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildStormIcon(context, StormType.fire, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildStormIcon(context, StormType.hail, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildStormIcon(context, StormType.tornado, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildStormIcon(context, StormType.flood, provider),
                              ),
                              SizedBox(
                                width: itemSize,
                                height: itemSize,
                                child: _buildCATexasIcon(context, provider),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStormIcon(BuildContext context, StormType stormType, PolicyTrackerProvider provider) {
    final count = provider.getStormTotal(stormType);
    
    return InkWell(
      onTap: () => _showStormDialog(context, stormType),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: _getStormColor(stormType).withOpacity(0.1),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getStormName(stormType),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStormColor(stormType),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Icon(
                  _getStormIcon(stormType),
                  size: 48,
                  color: _getStormColor(stormType),
                ),
              ],
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getStormColor(stormType),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHurricaneIcon(BuildContext context, PolicyTrackerProvider provider) {
    final otherCount = provider.getStormTotal(StormType.hurricaneOther);
    final floridaCount = provider.getStormTotal(StormType.hurricaneFlorida);
    final totalCount = otherCount + floridaCount;
    
    return InkWell(
      onTap: () => _showHurricaneDialog(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.purple.shade50,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Hurricane\n(Normal/Florida)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cyclone,
                      size: 32,
                      color: Colors.purple.shade300,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.cyclone,
                      size: 32,
                      color: Colors.purple.shade700,
                    ),
                  ],
                ),
              ],
            ),
            if (totalCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    totalCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCATexasIcon(BuildContext context, PolicyTrackerProvider provider) {
    return InkWell(
      onTap: () => _showCATexasDialog(context),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.orange.shade50,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'California/Texas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'CA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'TX',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStormDialog(BuildContext context, StormType stormType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<PolicyTrackerProvider>(
          builder: (context, provider, child) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStormIcon(stormType),
                          color: _getStormColor(stormType),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getStormName(stormType),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildPropertyRow(
                      context,
                      'Mobile Home',
                      provider.getPolicyCount(stormType, PropertyType.mobileHome),
                      () => provider.incrementPolicy(stormType, PropertyType.mobileHome, context),
                      () => provider.decrementPolicy(stormType, PropertyType.mobileHome),
                    ),
                    const SizedBox(height: 24),
                    _buildPropertyRow(
                      context,
                      'House',
                      provider.getPolicyCount(stormType, PropertyType.house),
                      () => provider.incrementPolicy(stormType, PropertyType.house, context),
                      () => provider.decrementPolicy(stormType, PropertyType.house),
                    ),
                    const SizedBox(height: 24),
                    _buildPropertyRow(
                      context,
                      'Mansion',
                      provider.getPolicyCount(stormType, PropertyType.mansion),
                      () => provider.incrementPolicy(stormType, PropertyType.mansion, context),
                      () => provider.decrementPolicy(stormType, PropertyType.mansion),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHurricaneDialog(BuildContext context) {
    bool showingFlorida = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<PolicyTrackerProvider>(
              builder: (context, provider, child) {
                final stormType = showingFlorida ? StormType.hurricaneFlorida : StormType.hurricaneOther;
                
                return Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cyclone,
                              color: showingFlorida ? Colors.purple.shade700 : Colors.purple.shade300,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hurricane',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Spacer(),
                            ToggleButtons(
                              isSelected: [!showingFlorida, showingFlorida],
                              onPressed: (index) {
                                setState(() {
                                  showingFlorida = index == 1;
                                });
                              },
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(
                                    Icons.cyclone,
                                    color: Colors.purple.shade300,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('FL'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildPropertyRow(
                          context,
                          'Mobile Home',
                          provider.getPolicyCount(stormType, PropertyType.mobileHome),
                          () => provider.incrementPolicy(stormType, PropertyType.mobileHome, context),
                          () => provider.decrementPolicy(stormType, PropertyType.mobileHome),
                        ),
                        const SizedBox(height: 24),
                        _buildPropertyRow(
                          context,
                          'House',
                          provider.getPolicyCount(stormType, PropertyType.house),
                          () => provider.incrementPolicy(stormType, PropertyType.house, context),
                          () => provider.decrementPolicy(stormType, PropertyType.house),
                        ),
                        const SizedBox(height: 24),
                        _buildPropertyRow(
                          context,
                          'Mansion',
                          provider.getPolicyCount(stormType, PropertyType.mansion),
                          () => provider.incrementPolicy(stormType, PropertyType.mansion, context),
                          () => provider.decrementPolicy(stormType, PropertyType.mansion),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCATexasDialog(BuildContext context) {
    bool showingTexas = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<PolicyTrackerProvider>(
              builder: (context, provider, child) {
                return Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'State Policies',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Spacer(),
                            ToggleButtons(
                              isSelected: [!showingTexas, showingTexas],
                              onPressed: (index) {
                                setState(() {
                                  showingTexas = index == 1;
                                });
                              },
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('CA'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('TX'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          showingTexas
                              ? 'Texas policies (Hurricane + Tornado)'
                              : 'California policies (Fire + Earthquake)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                      _buildStatePropertyRow(
                        context,
                        'Mobile Home',
                        () {
                          if (showingTexas) {
                            provider.incrementPolicy(StormType.hurricaneOther, PropertyType.mobileHome, context);
                            provider.incrementPolicy(StormType.tornado, PropertyType.mobileHome, context);
                          } else {
                            provider.incrementPolicy(StormType.fire, PropertyType.mobileHome, context);
                            provider.incrementPolicy(StormType.earthquake, PropertyType.mobileHome, context);
                          }
                        },
                        () {
                          if (showingTexas) {
                            // Check if both storm types have enough policies
                            if (provider.getPolicyCount(StormType.hurricaneOther, PropertyType.mobileHome) > 0 &&
                                provider.getPolicyCount(StormType.tornado, PropertyType.mobileHome) > 0) {
                              provider.decrementPolicy(StormType.hurricaneOther, PropertyType.mobileHome);
                              provider.decrementPolicy(StormType.tornado, PropertyType.mobileHome);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough policies to subtract a Texas policy'),
                                ),
                              );
                            }
                          } else {
                            // Check if both storm types have enough policies
                            if (provider.getPolicyCount(StormType.fire, PropertyType.mobileHome) > 0 &&
                                provider.getPolicyCount(StormType.earthquake, PropertyType.mobileHome) > 0) {
                              provider.decrementPolicy(StormType.fire, PropertyType.mobileHome);
                              provider.decrementPolicy(StormType.earthquake, PropertyType.mobileHome);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough policies to subtract a California policy'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStatePropertyRow(
                        context,
                        'House',
                        () {
                          if (showingTexas) {
                            provider.incrementPolicy(StormType.hurricaneOther, PropertyType.house, context);
                            provider.incrementPolicy(StormType.tornado, PropertyType.house, context);
                          } else {
                            provider.incrementPolicy(StormType.fire, PropertyType.house, context);
                            provider.incrementPolicy(StormType.earthquake, PropertyType.house, context);
                          }
                        },
                        () {
                          if (showingTexas) {
                            // Check if both storm types have enough policies
                            if (provider.getPolicyCount(StormType.hurricaneOther, PropertyType.house) > 0 &&
                                provider.getPolicyCount(StormType.tornado, PropertyType.house) > 0) {
                              provider.decrementPolicy(StormType.hurricaneOther, PropertyType.house);
                              provider.decrementPolicy(StormType.tornado, PropertyType.house);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough policies to subtract a Texas policy'),
                                ),
                              );
                            }
                          } else {
                            // Check if both storm types have enough policies
                            if (provider.getPolicyCount(StormType.fire, PropertyType.house) > 0 &&
                                provider.getPolicyCount(StormType.earthquake, PropertyType.house) > 0) {
                              provider.decrementPolicy(StormType.fire, PropertyType.house);
                              provider.decrementPolicy(StormType.earthquake, PropertyType.house);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough policies to subtract a California policy'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStatePropertyRow(
                        context,
                        'Mansion',
                        () {
                          if (showingTexas) {
                            provider.incrementPolicy(StormType.hurricaneOther, PropertyType.mansion, context);
                            provider.incrementPolicy(StormType.tornado, PropertyType.mansion, context);
                          } else {
                            provider.incrementPolicy(StormType.fire, PropertyType.mansion, context);
                            provider.incrementPolicy(StormType.earthquake, PropertyType.mansion, context);
                          }
                        },
                        () {
                          if (showingTexas) {
                            // Check if both storm types have enough policies
                            if (provider.getPolicyCount(StormType.hurricaneOther, PropertyType.mansion) > 0 &&
                                provider.getPolicyCount(StormType.tornado, PropertyType.mansion) > 0) {
                              provider.decrementPolicy(StormType.hurricaneOther, PropertyType.mansion);
                              provider.decrementPolicy(StormType.tornado, PropertyType.mansion);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough policies to subtract a Texas policy'),
                                ),
                              );
                            }
                          } else {
                            // Check if both storm types have enough policies
                            if (provider.getPolicyCount(StormType.fire, PropertyType.mansion) > 0 &&
                                provider.getPolicyCount(StormType.earthquake, PropertyType.mansion) > 0) {
                              provider.decrementPolicy(StormType.fire, PropertyType.mansion);
                              provider.decrementPolicy(StormType.earthquake, PropertyType.mansion);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Not enough policies to subtract a California policy'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildPropertyRow(
    BuildContext context,
    String propertyName,
    int count,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(propertyName),
              Text(
                'Current: $count',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: count > 0 ? onDecrement : null,
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildStatePropertyRow(
    BuildContext context,
    String propertyName,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(propertyName),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Color _getStormColor(StormType stormType) {
    switch (stormType) {
      case StormType.snow:
        return Colors.blue.shade200;
      case StormType.earthquake:
        return Colors.brown;
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
        return 'Hurricane (Florida)';
      default:
        return '';
    }
  }
}