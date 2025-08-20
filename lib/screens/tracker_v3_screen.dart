import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/policy_tracker_provider.dart';
import '../providers/cards_provider.dart';
import '../models/policy_data.dart';

class TrackerV3Screen extends StatefulWidget {
  const TrackerV3Screen({super.key});

  @override
  State<TrackerV3Screen> createState() => _TrackerV3ScreenState();
}

class _TrackerV3ScreenState extends State<TrackerV3Screen> {
  StormType? selectedStormType;
  PropertyType? selectedPropertyType;
  bool isCaliforniaSelected = false; // For CA/TX toggle
  bool isStateSelection = false; // Track if CA/TX is selected

  @override
  Widget build(BuildContext context) {
    return Consumer<PolicyTrackerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header with premium and VP
                _buildHeader(context, provider),
                const Divider(height: 1),
                
                // Storm type grid
                Expanded(
                  child: Column(
                    children: [
                      _buildStormGrid(provider),
                      const Divider(height: 32, thickness: 1),
                      
                      // Property type selection
                      _buildPropertyTypeRow(),
                      const Divider(height: 32, thickness: 1),
                      
                      // Add/Remove buttons
                      _buildActionButtons(provider),
                      
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PolicyTrackerProvider provider) {
    final cardsProvider = context.watch<CardsProvider>();
    final policyVP = provider.getTotalVictoryPoints();
    final cardVP = cardsProvider.getTotalCardVictoryPoints();
    final totalVP = policyVP + cardVP;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Premium',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '\$${provider.getTotalPremium()}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Policy Tracker',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cardVP > 0)
                Text(
                  '($policyVP + $cardVP cards)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Victory Points',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$totalVP',
                style: TextStyle(
                  fontSize: 20,
                  color: totalVP >= 0 ? Colors.blue : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStormGrid(PolicyTrackerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // First row: EQ, Snow, Hurricane
          Row(
            children: [
              Expanded(child: _buildStormButton(StormType.earthquake, provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(StormType.snow, provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildHurricaneButton(provider)),
            ],
          ),
          const SizedBox(height: 8),
          
          // Second row: Flood, Fire, Hail
          Row(
            children: [
              Expanded(child: _buildStormButton(StormType.flood, provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(StormType.fire, provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(StormType.hail, provider)),
            ],
          ),
          const SizedBox(height: 8),
          
          // Third row: Tornado, Hurricane FL, TX/CA
          Row(
            children: [
              Expanded(child: _buildStormButton(StormType.tornado, provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(StormType.hurricaneFlorida, provider, label: 'Hurricane\nFlorida')),
              const SizedBox(width: 8),
              Expanded(child: _buildStateButtons()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStormButton(StormType stormType, PolicyTrackerProvider provider, {String? label}) {
    final isSelected = selectedStormType == stormType && !isStateSelection;
    final totalPolicies = provider.getPolicyCount(stormType, PropertyType.mobileHome) +
        provider.getPolicyCount(stormType, PropertyType.house) +
        provider.getPolicyCount(stormType, PropertyType.mansion);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedStormType = null;
          } else {
            selectedStormType = stormType;
            isStateSelection = false; // Regular storm selection
          }
        });
      },
      onLongPress: () {
        _showPolicyDetails(context, stormType, provider);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: _getStormColor(stormType).withOpacity(0.1),
          border: Border.all(
            color: isSelected ? _getStormColor(stormType) : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
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
                    _getStormIcon(stormType),
                    color: _getStormColor(stormType),
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label ?? _getStormName(stormType),
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Policy count circle (top right)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getStormColor(stormType),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    totalPolicies.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Growth Target indicator (top left)
            if (provider.hasGrowthTargetCard(stormType))
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getStormColor(stormType),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.track_changes,  // Bullseye icon
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            // Agent of Year indicator (bottom left)
            if (provider.hasAgentOfYearCard(stormType))
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getStormColor(stormType),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,  // Person in suit icon
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHurricaneButton(PolicyTrackerProvider provider) {
    final isSelected = selectedStormType == StormType.hurricaneOther && !isStateSelection;
    final totalPolicies = provider.getPolicyCount(StormType.hurricaneOther, PropertyType.mobileHome) +
        provider.getPolicyCount(StormType.hurricaneOther, PropertyType.house) +
        provider.getPolicyCount(StormType.hurricaneOther, PropertyType.mansion);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedStormType = null;
          } else {
            selectedStormType = StormType.hurricaneOther;
            isStateSelection = false; // Regular storm selection
          }
        });
      },
      onLongPress: () {
        _showPolicyDetails(context, StormType.hurricaneOther, provider);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
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
                    Icons.cyclone,
                    color: Colors.purple.shade300,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hurricane',
                    style: TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Policy count circle (top right)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.purple.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    totalPolicies.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Growth Target indicator (top left)
            if (provider.hasGrowthTargetCard(StormType.hurricaneOther))
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.track_changes,  // Bullseye icon
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            // Agent of Year indicator (bottom left)
            if (provider.hasAgentOfYearCard(StormType.hurricaneOther))
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,  // Person in suit icon
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateButtons() {
    return Container(
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isStateSelection && isCaliforniaSelected) {
                    // Deselect California
                    selectedStormType = null;
                    isStateSelection = false;
                  } else {
                    // Select California
                    selectedStormType = StormType.fire; // CA uses fire as marker internally
                    isCaliforniaSelected = true;
                    isStateSelection = true;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.5, 0.5],
                    colors: [
                      Colors.red.withOpacity(0.2),  // Fire color
                      Color(0xFF6D4C41).withOpacity(0.2), // Earthquake color - more brown
                    ],
                  ),
                  border: Border.all(
                    color: (isStateSelection && isCaliforniaSelected) 
                        ? Colors.orange.shade700 : Colors.grey.shade300,
                    width: (isStateSelection && isCaliforniaSelected) ? 3 : 1,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('CA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department, size: 12, color: Colors.red),
                        const Text('/', style: TextStyle(fontSize: 9)),
                        Icon(Icons.landscape, size: 12, color: Color(0xFF6D4C41)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isStateSelection && !isCaliforniaSelected) {
                    // Deselect Texas
                    selectedStormType = null;
                    isStateSelection = false;
                  } else {
                    // Select Texas
                    selectedStormType = StormType.tornado; // TX uses tornado as marker internally
                    isCaliforniaSelected = false;
                    isStateSelection = true;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.5, 0.5],
                    colors: [
                      Colors.purple.shade300.withOpacity(0.2), // Hurricane color
                      Colors.grey.withOpacity(0.2),            // Tornado color
                    ],
                  ),
                  border: Border.all(
                    color: (isStateSelection && !isCaliforniaSelected) 
                        ? Colors.purple.shade400 : Colors.grey.shade300,
                    width: (isStateSelection && !isCaliforniaSelected) ? 3 : 1,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('TX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cyclone, size: 12, color: Colors.purple.shade300),
                        const Text('/', style: TextStyle(fontSize: 9)),
                        Icon(Icons.air, size: 12, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeRow() {
    return Consumer<PolicyTrackerProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(child: _buildPropertyButton(PropertyType.mobileHome, 'Mobile', provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildPropertyButton(PropertyType.house, 'House', provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildPropertyButton(PropertyType.mansion, 'Mansion', provider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPropertyButton(PropertyType propertyType, String label, PolicyTrackerProvider provider) {
    final isSelected = selectedPropertyType == propertyType;
    
    // Calculate total policies of this property type across all storms
    int totalCount = 0;
    for (final storm in StormType.values) {
      totalCount += provider.getPolicyCount(storm, propertyType);
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPropertyType = isSelected ? null : propertyType;
        });
      },
      onLongPress: () {
        _showPropertyBreakdown(context, propertyType, label, provider);
      },
      child: Container(
        height: 80,  // Increased from 60 to 80 (33% increase)
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
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
                    _getPropertyIcon(propertyType),
                    color: Colors.blue.shade700,
                    size: 28,  // Increased from 20 to 28
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      totalCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildActionButtons(PolicyTrackerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Remove button (smaller)
          SizedBox(
            width: 100,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _handleRemove(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ),
          const SizedBox(width: 16),
          
          // Add button (larger)
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () => _handleAdd(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAdd(PolicyTrackerProvider provider) {
    if (selectedStormType == null || selectedPropertyType == null) {
      _showErrorDialog('Please select both a storm type and a property type.');
      return;
    }

    // Handle California (Fire + Earthquake)
    if (isStateSelection && isCaliforniaSelected) {
      provider.incrementPolicy(StormType.fire, selectedPropertyType!, context);
      provider.incrementPolicy(StormType.earthquake, selectedPropertyType!, context);
    }
    // Handle Texas (Tornado + Hurricane)
    else if (isStateSelection && !isCaliforniaSelected) {
      provider.incrementPolicy(StormType.tornado, selectedPropertyType!, context);
      provider.incrementPolicy(StormType.hurricaneOther, selectedPropertyType!, context);
    }
    // Handle regular storm types
    else {
      provider.incrementPolicy(selectedStormType!, selectedPropertyType!, context);
    }

    // Clear selections
    setState(() {
      selectedStormType = null;
      selectedPropertyType = null;
      isStateSelection = false;
    });
  }

  void _handleRemove(PolicyTrackerProvider provider) {
    if (selectedStormType == null || selectedPropertyType == null) {
      _showErrorDialog('Please select both a storm type and a property type.');
      return;
    }

    // Build confirmation message
    String stormName;
    if (isStateSelection && isCaliforniaSelected) {
      stormName = 'California (Fire/Earthquake)';
    } else if (isStateSelection && !isCaliforniaSelected) {
      stormName = 'Texas (Tornado/Hurricane)';
    } else {
      stormName = _getStormName(selectedStormType!);
    }

    String propertyName = _getPropertyName(selectedPropertyType!);

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: Text('Are you sure you want to remove a $stormName $propertyName policy?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                // Check if removal is possible
                if (isStateSelection && isCaliforniaSelected) {
                  // California - check both fire and earthquake
                  if (provider.getPolicyCount(StormType.fire, selectedPropertyType!) > 0 &&
                      provider.getPolicyCount(StormType.earthquake, selectedPropertyType!) > 0) {
                    provider.decrementPolicy(StormType.fire, selectedPropertyType!);
                    provider.decrementPolicy(StormType.earthquake, selectedPropertyType!);
                  } else {
                    _showErrorDialog('Not enough policies to remove.');
                  }
                } else if (isStateSelection && !isCaliforniaSelected) {
                  // Texas - check both tornado and hurricane
                  if (provider.getPolicyCount(StormType.tornado, selectedPropertyType!) > 0 &&
                      provider.getPolicyCount(StormType.hurricaneOther, selectedPropertyType!) > 0) {
                    provider.decrementPolicy(StormType.tornado, selectedPropertyType!);
                    provider.decrementPolicy(StormType.hurricaneOther, selectedPropertyType!);
                  } else {
                    _showErrorDialog('Not enough policies to remove.');
                  }
                } else {
                  // Regular storm type
                  if (provider.getPolicyCount(selectedStormType!, selectedPropertyType!) > 0) {
                    provider.decrementPolicy(selectedStormType!, selectedPropertyType!);
                  } else {
                    _showErrorDialog('Not enough policies to remove.');
                  }
                }

                // Clear selections
                setState(() {
                  selectedStormType = null;
                  selectedPropertyType = null;
                  isStateSelection = false;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showPolicyDetails(BuildContext context, StormType stormType, PolicyTrackerProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${_getStormName(stormType)} Policies'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mobile Homes: ${provider.getPolicyCount(stormType, PropertyType.mobileHome)}'),
              Text('Houses: ${provider.getPolicyCount(stormType, PropertyType.house)}'),
              Text('Mansions: ${provider.getPolicyCount(stormType, PropertyType.mansion)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPropertyBreakdown(BuildContext context, PropertyType propertyType, String label, PolicyTrackerProvider provider) {
    // Get policy counts for this property type across all storm types
    List<Widget> policyBreakdown = [];
    
    for (final storm in StormType.values) {
      final count = provider.getPolicyCount(storm, propertyType);
      if (count > 0) {
        policyBreakdown.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _getStormIcon(storm),
                  color: _getStormColor(storm),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStormName(storm),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$label Breakdown'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: policyBreakdown.isEmpty
                ? [const Text('No policies of this type')]
                : policyBreakdown,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notice'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
        return Color(0xFF6D4C41);  // More distinct brown color
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

  IconData _getPropertyIcon(PropertyType propertyType) {
    switch (propertyType) {
      case PropertyType.mobileHome:
        return Icons.rv_hookup;  // More appropriate for mobile home
      case PropertyType.house:
        return Icons.home;
      case PropertyType.mansion:
        return Icons.villa;
      default:
        return Icons.home;
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

  String _getPropertyName(PropertyType propertyType) {
    switch (propertyType) {
      case PropertyType.mobileHome:
        return 'Mobile Home';
      case PropertyType.house:
        return 'House';
      case PropertyType.mansion:
        return 'Mansion';
      default:
        return '';
    }
  }
}