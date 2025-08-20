import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path_parsing/path_parsing.dart';
import '../providers/policy_tracker_provider.dart';
import '../models/policy_data.dart' as policy;
import '../models/map_configuration.dart' as config;

// Helper class to convert SVG path commands to Flutter Path  
class FlutterPathProxy extends PathProxy {
  FlutterPathProxy(this.path);
  
  final Path path;
  
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  
  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);
  
  @override
  void close() => path.close();
}

class TrackerV2Screen extends StatefulWidget {
  const TrackerV2Screen({super.key});

  @override
  State<TrackerV2Screen> createState() => _TrackerV2ScreenState();
}

class _TrackerV2ScreenState extends State<TrackerV2Screen> {
  String? _svgString;
  String? _selectedState;
  String? _hoveredState;
  final Map<String, Path> _statePaths = {};
  
  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    final svgData = await rootBundle.loadString('assets/catastrophe_regions_simple.svg');
    setState(() {
      _svgString = svgData;
    });
  }

  // Convert between storm type enums
  policy.StormType _convertStormType(config.StormType configStorm) {
    switch (configStorm) {
      case config.StormType.earthquake:
        return policy.StormType.earthquake;
      case config.StormType.snow:
        return policy.StormType.snow;
      case config.StormType.hurricaneOther:
        return policy.StormType.hurricaneOther;
      case config.StormType.flood:
        return policy.StormType.flood;
      case config.StormType.fire:
        return policy.StormType.fire;
      case config.StormType.hail:
        return policy.StormType.hail;
      case config.StormType.tornado:
        return policy.StormType.tornado;
      case config.StormType.hurricaneFlorida:
        return policy.StormType.hurricaneFlorida;
    }
  }

  // Get state info by code
  config.StateInfo? _getStateInfo(String stateCode) {
    return config.usStates[stateCode];
  }

  // Find which region contains the given point using actual path hit testing
  String? _findRegionAtPoint(xml.XmlDocument document, double x, double y) {
    final paths = document.findAllElements('path');
    final clickPoint = Offset(x, y);
    
    for (final pathElement in paths) {
      final id = pathElement.getAttribute('id');
      if (id == null) continue;
      
      final d = pathElement.getAttribute('d');
      if (d == null) continue;
      
      try {
        // Create a path from SVG data
        final path = Path();
        final SvgPathStringSource source = SvgPathStringSource(d);
        final SvgPathNormalizer normalizer = SvgPathNormalizer();
        
        for (PathSegmentData seg in source.parseSegments()) {
          normalizer.emitSegment(seg, FlutterPathProxy(path));
        }
        
        // Check if the click point is inside this path
        if (path.contains(clickPoint)) {
          return id;
        }
      } catch (e) {
        // If parsing fails for this path, skip it silently
        continue;
      }
    }
    
    return null;
  }

  // Get display name for region
  String _getDisplayName(String id) {
    if (id.startsWith('Hawaii_')) return 'Hawaii (Fire)';
    if (id == 'CA') return 'California';
    if (id == 'TX') return 'Texas';
    if (id == 'Hail_West') return 'Hail (West)';
    if (id == 'Hail_East') return 'Hail (East)';
    if (id == 'Snow_West') return 'Snow (West)';
    if (id == 'Snow_East') return 'Snow (East)';
    if (id == 'Hurricane_Florida') return 'Hurricane (FL)';
    if (id == 'Hurricane_Other') return 'Hurricane';
    return id.replaceAll('_', ' ');
  }

  // Build interactive SVG map
  Widget _buildInteractiveSvgMap(PolicyTrackerProvider provider) {
    if (_svgString == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Parse SVG to extract paths
    final document = xml.XmlDocument.parse(_svgString!);
    final svgElement = document.findElements('svg').first;
    final viewBox = svgElement.getAttribute('viewBox') ?? '0 0 529.16669 430.74167';
    final viewBoxValues = viewBox.split(' ').map((e) => double.parse(e)).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final svgWidth = viewBoxValues[2];
        final svgHeight = viewBoxValues[3];
        final scale = constraints.maxWidth / svgWidth;
        final renderedHeight = svgHeight * scale;
        
        return InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: SizedBox(
            width: constraints.maxWidth,
            height: renderedHeight,
            child: Stack(
              children: [
                // Background SVG
                SvgPicture.string(
                  _svgString!,
                  width: constraints.maxWidth,
                  height: renderedHeight,
                  fit: BoxFit.fill,
                ),
                // Overlay for click detection
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (details) {
                      // Get local position relative to the widget
                      final localX = details.localPosition.dx;
                      final localY = details.localPosition.dy;
                      
                      // Convert to SVG coordinates
                      final svgX = localX / scale;
                      final svgY = localY / scale;
                      
                      // Find which region was tapped
                      final tappedRegion = _findRegionAtPoint(document, svgX, svgY);
                      if (tappedRegion != null) {
                        _handleStateTap(tappedRegion, provider);
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // Handle region tap
  void _handleStateTap(String regionId, PolicyTrackerProvider provider) {
    setState(() {
      _selectedState = regionId;
    });
    
    // Map regions to their appropriate storm types
    if (regionId == 'Fire' || regionId.startsWith('Hawaii_')) {
      _showStormDialog(context, policy.StormType.fire, 'Fire', provider);
    } else if (regionId == 'CA') {
      _showSpecialStateDialog(context, 'California', provider);
    } else if (regionId == 'TX') {
      _showSpecialStateDialog(context, 'Texas', provider);
    } else if (regionId == 'Hail_West' || regionId == 'Hail_East') {
      _showStormDialog(context, policy.StormType.hail, 'Hail', provider);
    } else if (regionId == 'Snow_West' || regionId == 'Snow_East') {
      _showStormDialog(context, policy.StormType.snow, 'Snow', provider);
    } else if (regionId == 'Tornado') {
      _showStormDialog(context, policy.StormType.tornado, 'Tornado', provider);
    } else if (regionId == 'Hurricane_Florida') {
      _showStormDialog(context, policy.StormType.hurricaneFlorida, 'Hurricane (Florida)', provider);
    } else if (regionId == 'Hurricane_Other') {
      _showStormDialog(context, policy.StormType.hurricaneOther, 'Hurricane', provider);
    } else if (regionId == 'Flood') {
      _showStormDialog(context, policy.StormType.flood, 'Flood', provider);
    } else if (regionId == 'Alaska') {
      _showStormDialog(context, policy.StormType.earthquake, 'Earthquake', provider);
    }
  }

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
                        'Policy Tracker - Map View',
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
                // Map and Legend
                Expanded(
                  child: Column(
                    children: [
                      // Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildLegend(),
                      ),
                      const SizedBox(height: 16),
                      // US Map
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildInteractiveSvgMap(provider),
                        ),
                      ),
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

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Fire', Colors.red),
        _buildLegendItem('Earthquake', Colors.brown),
        _buildLegendItem('Snow', Colors.blue.shade200),
        _buildLegendItem('Hail', Colors.yellow.shade700),
        _buildLegendItem('Tornado', Colors.grey),
        _buildLegendItem('Flood', Colors.blue),
        _buildLegendItem('Hurricane', Colors.purple),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            border: Border.all(color: Colors.black54),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showStormDialog(BuildContext context, policy.StormType stormType, String stormName, PolicyTrackerProvider provider) {
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStormIcon(stormType),
                          color: _getStormColor(stormType),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          stormName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStormColor(stormType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildPropertyRow(
                            context,
                            'Mobile Home',
                            provider.getPolicyCount(stormType, policy.PropertyType.mobileHome),
                            () => provider.incrementPolicy(stormType, policy.PropertyType.mobileHome, context),
                            () => provider.decrementPolicy(stormType, policy.PropertyType.mobileHome),
                          ),
                          const SizedBox(height: 12),
                          _buildPropertyRow(
                            context,
                            'House',
                            provider.getPolicyCount(stormType, policy.PropertyType.house),
                            () => provider.incrementPolicy(stormType, policy.PropertyType.house, context),
                            () => provider.decrementPolicy(stormType, policy.PropertyType.house),
                          ),
                          const SizedBox(height: 12),
                          _buildPropertyRow(
                            context,
                            'Mansion',
                            provider.getPolicyCount(stormType, policy.PropertyType.mansion),
                            () => provider.incrementPolicy(stormType, policy.PropertyType.mansion, context),
                            () => provider.decrementPolicy(stormType, policy.PropertyType.mansion),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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

  void _showSpecialStateDialog(BuildContext context, String stateName, PolicyTrackerProvider provider) {
    // For California: only Fire and Earthquake
    // For Texas: only Tornado and Hurricane
    final List<policy.StormType> availableStorms;
    if (stateName == 'California') {
      availableStorms = [
        policy.StormType.fire,
        policy.StormType.earthquake,
      ];
    } else if (stateName == 'Texas') {
      availableStorms = [
        policy.StormType.tornado,
        policy.StormType.hurricaneOther,
        policy.StormType.hurricaneFlorida,
      ];
    } else {
      availableStorms = [];
    }
    
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
                Text(
                  stateName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'All Storm Types Available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: availableStorms.map((stormType) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStormColor(stormType).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getStormIcon(stormType),
                                        color: _getStormColor(stormType),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getStormName(stormType),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPropertyRow(
                                    context,
                                    'Mobile Home',
                                    provider.getPolicyCount(stormType, policy.PropertyType.mobileHome),
                                    () => provider.incrementPolicy(stormType, policy.PropertyType.mobileHome, context),
                                    () => provider.decrementPolicy(stormType, policy.PropertyType.mobileHome),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPropertyRow(
                                    context,
                                    'House',
                                    provider.getPolicyCount(stormType, policy.PropertyType.house),
                                    () => provider.incrementPolicy(stormType, policy.PropertyType.house, context),
                                    () => provider.decrementPolicy(stormType, policy.PropertyType.house),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPropertyRow(
                                    context,
                                    'Mansion',
                                    provider.getPolicyCount(stormType, policy.PropertyType.mansion),
                                    () => provider.incrementPolicy(stormType, policy.PropertyType.mansion, context),
                                    () => provider.decrementPolicy(stormType, policy.PropertyType.mansion),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Color _getStormColor(policy.StormType stormType) {
    switch (stormType) {
      case policy.StormType.snow:
        return Colors.blue.shade200;
      case policy.StormType.earthquake:
        return Colors.brown;
      case policy.StormType.hurricaneOther:
        return Colors.purple.shade300;
      case policy.StormType.flood:
        return Colors.blue;
      case policy.StormType.fire:
        return Colors.red;
      case policy.StormType.hail:
        return Colors.yellow.shade700;
      case policy.StormType.tornado:
        return Colors.grey;
      case policy.StormType.hurricaneFlorida:
        return Colors.purple.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStormIcon(policy.StormType stormType) {
    switch (stormType) {
      case policy.StormType.snow:
        return Icons.ac_unit;
      case policy.StormType.earthquake:
        return Icons.landscape;
      case policy.StormType.hurricaneOther:
      case policy.StormType.hurricaneFlorida:
        return Icons.cyclone;
      case policy.StormType.flood:
        return Icons.water;
      case policy.StormType.fire:
        return Icons.local_fire_department;
      case policy.StormType.hail:
        return Icons.grain;
      case policy.StormType.tornado:
        return Icons.air;
      default:
        return Icons.warning;
    }
  }

  String _getStormName(policy.StormType stormType) {
    switch (stormType) {
      case policy.StormType.snow:
        return 'Snow';
      case policy.StormType.earthquake:
        return 'Earthquake';
      case policy.StormType.hurricaneOther:
        return 'Hurricane';
      case policy.StormType.flood:
        return 'Flood';
      case policy.StormType.fire:
        return 'Fire';
      case policy.StormType.hail:
        return 'Hail';
      case policy.StormType.tornado:
        return 'Tornado';
      case policy.StormType.hurricaneFlorida:
        return 'Hurricane (Florida)';
      default:
        return '';
    }
  }
}