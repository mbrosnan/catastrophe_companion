import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  // Grid order: Snow, Flood, Hail, Hurricane, Fire, Tornado, Florida, California, Texas
  static const List<StormType> gridOrder = [
    StormType.snow,
    StormType.flood,
    StormType.hail,
    StormType.hurricaneOther,
    StormType.fire,
    StormType.tornado,
    StormType.hurricaneFlorida,
    StormType.fireCalifornia,
    StormType.tornadoTexas,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<PolicyTrackerProvider>(
      builder: (context, provider, child) {
        final size = MediaQuery.of(context).size;
        final isPortrait = size.height > size.width;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header with premium and VP
                _buildHeader(context, provider),
                const Divider(height: 1),

                // Main content area - different layout based on orientation
                Expanded(
                  child: isPortrait
                      ? _buildPortraitLayout(provider)
                      : _buildLandscapeLayout(provider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(PolicyTrackerProvider provider) {
    return Column(
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
    );
  }

  Widget _buildLandscapeLayout(PolicyTrackerProvider provider) {
    return Row(
      children: [
        // Storm grid on the left
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStormGrid(provider),
          ),
        ),

        const VerticalDivider(width: 1),

        // Property types in the middle (vertical)
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPropertyTypeColumn(provider),
          ),
        ),

        const VerticalDivider(width: 1),

        // Add/Remove buttons on the right
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildActionButtonsVertical(provider),
          ),
        ),
      ],
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
          // Row 1: Snow, Flood, Hail
          Row(
            children: [
              Expanded(child: _buildStormButton(gridOrder[0], provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(gridOrder[1], provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(gridOrder[2], provider)),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Hurricane, Fire, Tornado
          Row(
            children: [
              Expanded(child: _buildStormButton(gridOrder[3], provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(gridOrder[4], provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(gridOrder[5], provider)),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Florida, California, Texas
          Row(
            children: [
              Expanded(child: _buildStormButton(gridOrder[6], provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(gridOrder[7], provider)),
              const SizedBox(width: 8),
              Expanded(child: _buildStormButton(gridOrder[8], provider)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStormButton(StormType stormType, PolicyTrackerProvider provider) {
    final isSelected = selectedStormType == stormType;
    final totalPolicies = provider.getStormTotal(stormType);
    final color = _getStormColor(stormType);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStormType = isSelected ? null : stormType;
        });
      },
      onLongPress: () {
        _showPolicyDetails(context, stormType, provider);
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
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
                  _buildStormIcon(stormType, color, 28),
                  const SizedBox(height: 4),
                  Text(
                    _getStormName(stormType),
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
                  color: color,
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
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.track_changes,
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
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
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
        height: 80,
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey.shade300,
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
                    color: Colors.teal.shade700,
                    size: 28,
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
                  decoration: const BoxDecoration(
                    color: Colors.teal,
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

  Widget _buildPropertyTypeColumn(PolicyTrackerProvider provider) {
    // Property types arranged vertically for landscape
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _buildPropertyButton(PropertyType.mobileHome, 'Mobile', provider)),
        const SizedBox(height: 8),
        Expanded(child: _buildPropertyButton(PropertyType.house, 'House', provider)),
        const SizedBox(height: 8),
        Expanded(child: _buildPropertyButton(PropertyType.mansion, 'Mansion', provider)),
      ],
    );
  }

  Widget _buildActionButtonsVertical(PolicyTrackerProvider provider) {
    // Add on top, Remove on bottom for landscape
    return Column(
      children: [
        // Add button (larger, takes up 60% of height)
        Expanded(
          flex: 3,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleAdd(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 32),
                  SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Remove button (smaller, takes up 40% of height)
        Expanded(
          flex: 2,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleRemove(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove, size: 24),
                  SizedBox(height: 4),
                  Text('Remove'),
                ],
              ),
            ),
          ),
        ),
      ],
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

    provider.incrementPolicy(selectedStormType!, selectedPropertyType!, context);

    // Clear selections
    setState(() {
      selectedStormType = null;
      selectedPropertyType = null;
    });
  }

  void _handleRemove(PolicyTrackerProvider provider) {
    if (selectedStormType == null || selectedPropertyType == null) {
      _showErrorDialog('Please select both a storm type and a property type.');
      return;
    }

    String stormName = _getStormName(selectedStormType!);
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

                if (provider.getPolicyCount(selectedStormType!, selectedPropertyType!) > 0) {
                  provider.decrementPolicy(selectedStormType!, selectedPropertyType!);
                } else {
                  _showErrorDialog('Not enough policies to remove.');
                }

                // Clear selections
                setState(() {
                  selectedStormType = null;
                  selectedPropertyType = null;
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
    List<Widget> policyBreakdown = [];

    for (final storm in StormType.values) {
      final count = provider.getPolicyCount(storm, propertyType);
      if (count > 0) {
        policyBreakdown.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildStormIcon(storm, _getStormColor(storm), 20),
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
      case StormType.flood:
        return const Color(0xFF1A4784); // Dark royal blue (KC Royals)
      case StormType.hail:
        return Colors.yellow.shade700;
      case StormType.hurricaneOther:
        return Colors.purple.shade300;
      case StormType.fire:
        return Colors.red;
      case StormType.tornado:
        return Colors.grey;
      case StormType.hurricaneFlorida:
        return Colors.purple.shade700;
      case StormType.fireCalifornia:
        return const Color(0xFFB71C1C); // Darker red
      case StormType.tornadoTexas:
        return const Color(0xFF424242); // Darker grey
    }
  }

  Widget _buildStormIcon(StormType stormType, Color color, double size) {
    if (stormType == StormType.tornado || stormType == StormType.tornadoTexas) {
      return SvgPicture.asset(
        'assets/icons/tornado.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(_getStormIcon(stormType), color: color, size: size);
  }

  IconData _getStormIcon(StormType stormType) {
    switch (stormType) {
      case StormType.snow:
        return Icons.ac_unit;
      case StormType.flood:
        return Icons.water;
      case StormType.hail:
        return Icons.grain;
      case StormType.hurricaneOther:
      case StormType.hurricaneFlorida:
        return Icons.cyclone;
      case StormType.fire:
      case StormType.fireCalifornia:
        return Icons.local_fire_department;
      case StormType.tornado:
      case StormType.tornadoTexas:
        return Icons.tornado;
    }
  }

  IconData _getPropertyIcon(PropertyType propertyType) {
    switch (propertyType) {
      case PropertyType.mobileHome:
        return Icons.rv_hookup;
      case PropertyType.house:
        return Icons.home;
      case PropertyType.mansion:
        return Icons.villa;
    }
  }

  String _getStormName(StormType stormType) {
    return PolicyData.stormNames[stormType] ?? '';
  }

  String _getPropertyName(PropertyType propertyType) {
    return PolicyData.propertyNames[propertyType] ?? '';
  }
}
