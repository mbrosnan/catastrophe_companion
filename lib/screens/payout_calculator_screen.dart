import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/policy_data.dart';
import '../providers/game_config_provider.dart';
import '../providers/policy_tracker_provider.dart';
import '../providers/payout_calculator_provider.dart';

class PayoutCalculatorScreen extends StatefulWidget {
  const PayoutCalculatorScreen({super.key});

  @override
  State<PayoutCalculatorScreen> createState() => _PayoutCalculatorScreenState();
}

class _PayoutCalculatorScreenState extends State<PayoutCalculatorScreen> {
  // Only the 6 base storms appear as buttons
  static const List<StormType> baseStorms = [
    StormType.snow,
    StormType.flood,
    StormType.hail,
    StormType.hurricaneOther,
    StormType.fire,
    StormType.tornado,
  ];

  // Track which base storms have occurred and their severities
  Map<StormType, int> occurredStorms = {};

  // State-specific additions (set during severity dialog)
  int? floridaAddition;
  int? californiaAddition;
  String? texasFlippedStorm; // storm key or 'noStorm'

  // Possible California addition values (deck: 4×5, 2×10, 2×0, draw until 0)
  static const List<int> californiaAdditionOptions = [0, 5, 10, 15, 20, 25, 30];

  // Possible Florida addition values (deck: 2×10, 2×20, 2×30)
  static const List<int> floridaAdditionOptions = [10, 20, 30];

  // Texas flip options
  static const List<MapEntry<String, String>> texasFlipOptions = [
    MapEntry('snow', 'Snow'),
    MapEntry('hurricaneOther', 'Hurricane'),
    MapEntry('flood', 'Flood'),
    MapEntry('fire', 'Fire'),
    MapEntry('hail', 'Hail'),
    MapEntry('noStorm', 'No Storm'),
  ];

  int _getTexasAdditionalSeverity() {
    if (texasFlippedStorm == null || texasFlippedStorm == 'noStorm') return 0;
    // Map the flipped storm key to StormType
    final stormTypeMap = {
      'snow': StormType.snow,
      'hurricaneOther': StormType.hurricaneOther,
      'flood': StormType.flood,
      'fire': StormType.fire,
      'hail': StormType.hail,
    };
    final flippedStorm = stormTypeMap[texasFlippedStorm];
    if (flippedStorm == null) return 0;
    // If that storm also occurred, add its severity
    return occurredStorms[flippedStorm] ?? 0;
  }

  int _getStateSeverity(StormType stateStorm) {
    switch (stateStorm) {
      case StormType.hurricaneFlorida:
        final baseSeverity = occurredStorms[StormType.hurricaneOther] ?? 0;
        return baseSeverity + (floridaAddition ?? 0);
      case StormType.fireCalifornia:
        final baseSeverity = occurredStorms[StormType.fire] ?? 0;
        return baseSeverity + (californiaAddition ?? 0);
      case StormType.tornadoTexas:
        final baseSeverity = occurredStorms[StormType.tornado] ?? 0;
        return baseSeverity + _getTexasAdditionalSeverity();
      default:
        return 0;
    }
  }

  int _calculateTotalPayout(PolicyTrackerProvider tracker, PayoutCalculatorProvider payoutProvider) {
    int total = 0;

    // Base storms
    occurredStorms.forEach((storm, severity) {
      final count = payoutProvider.billionaireBailout
          ? (tracker.getPolicyCount(storm, PropertyType.house) +
             tracker.getPolicyCount(storm, PropertyType.mobileHome))
          : tracker.getStormTotal(storm);
      total += count * severity;
    });

    // State-specific storms (only if parent occurred)
    for (final stateStorm in PolicyData.stateStormTypes) {
      final parentStorm = PolicyData.parentStormTypes[stateStorm]!;
      if (!occurredStorms.containsKey(parentStorm)) continue;
      final count = payoutProvider.billionaireBailout
          ? (tracker.getPolicyCount(stateStorm, PropertyType.house) +
             tracker.getPolicyCount(stateStorm, PropertyType.mobileHome))
          : tracker.getStormTotal(stateStorm);
      if (count == 0) continue;
      total += count * _getStateSeverity(stateStorm);
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PayoutCalculatorProvider, PolicyTrackerProvider>(
      builder: (context, payoutProvider, trackerProvider, child) {
        final size = MediaQuery.of(context).size;
        final isPortrait = size.height > size.width;

        final totalPayout = _calculateTotalPayout(trackerProvider, payoutProvider);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(totalPayout),
                const Divider(height: 1),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total Payout:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                floridaAddition = null;
                californiaAddition = null;
                texasFlippedStorm = null;
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
              Expanded(child: _buildUnoccurredStorms(trackerProvider)),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
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
              Expanded(child: _buildOccurredStorms(trackerProvider, payoutProvider)),
              CheckboxListTile(
                title: const Text('Billionaire Bailout', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Mansions do not add to payout', style: TextStyle(fontSize: 11)),
                value: payoutProvider.billionaireBailout,
                onChanged: (value) {
                  if (value != null) payoutProvider.setBillionaireBailout(value);
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
              Expanded(child: _buildUnoccurredStorms(trackerProvider)),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
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
              Expanded(child: _buildOccurredStorms(trackerProvider, payoutProvider)),
              CheckboxListTile(
                title: const Text('Billionaire Bailout', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Mansions do not add to payout', style: TextStyle(fontSize: 11)),
                value: payoutProvider.billionaireBailout,
                onChanged: (value) {
                  if (value != null) payoutProvider.setBillionaireBailout(value);
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
    final unoccurred = baseStorms.where((s) => !occurredStorms.containsKey(s)).toList();
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    final List<Widget> gridItems = [];
    for (int i = 0; i < 6; i++) {
      if (i < unoccurred.length) {
        gridItems.add(_buildStormButton(unoccurred[i], trackerProvider));
      } else {
        gridItems.add(Container());
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: isLandscape ? 1.0 : 1.25,
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
        child: Text('No storms have occurred yet', style: TextStyle(color: Colors.grey)),
      );
    }

    // Build list of all occurred entries (base + state-specific)
    final List<Widget> items = [];
    for (final entry in occurredStorms.entries) {
      final storm = entry.key;
      final severity = entry.value;
      final count = payoutProvider.billionaireBailout
          ? (trackerProvider.getPolicyCount(storm, PropertyType.house) +
             trackerProvider.getPolicyCount(storm, PropertyType.mobileHome))
          : trackerProvider.getStormTotal(storm);
      items.add(_buildOccurredStormTile(storm, severity, count, storm));

      // Add state-specific variants if player has those policies
      for (final stateStorm in PolicyData.stateStormTypes) {
        if (PolicyData.parentStormTypes[stateStorm] != storm) continue;
        final stateCount = payoutProvider.billionaireBailout
            ? (trackerProvider.getPolicyCount(stateStorm, PropertyType.house) +
               trackerProvider.getPolicyCount(stateStorm, PropertyType.mobileHome))
            : trackerProvider.getStormTotal(stateStorm);
        if (stateCount == 0) continue;
        final stateSeverity = _getStateSeverity(stateStorm);
        items.add(_buildOccurredStormTile(stateStorm, stateSeverity, stateCount, storm));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      children: items,
    );
  }

  Widget _buildOccurredStormTile(StormType storm, int severity, int count, StormType parentStorm) {
    final color = _getStormColor(storm);
    final payout = count * severity;
    final isStateSpecific = PolicyData.parentStormTypes.containsKey(storm);

    // Build subtitle showing calculation details
    String subtitle = '$count × \$$severity = \$$payout';
    if (storm == StormType.tornadoTexas && texasFlippedStorm != null) {
      final baseTornado = occurredStorms[StormType.tornado] ?? 0;
      final additional = _getTexasAdditionalSeverity();
      final flipLabel = texasFlipOptions.firstWhere((e) => e.key == texasFlippedStorm).value;
      if (texasFlippedStorm == 'noStorm') {
        subtitle = '$count × \$$baseTornado = \$$payout';
      } else {
        subtitle = '$count × (\$$baseTornado Tornado + \$$additional $flipLabel) = \$$payout';
      }
    } else if (storm == StormType.fireCalifornia && californiaAddition != null) {
      final baseFire = occurredStorms[StormType.fire] ?? 0;
      subtitle = '$count × (\$$baseFire + \$$californiaAddition CA) = \$$payout';
    } else if (storm == StormType.hurricaneFlorida && floridaAddition != null) {
      final baseHurricane = occurredStorms[StormType.hurricaneOther] ?? 0;
      subtitle = '$count × (\$$baseHurricane + \$$floridaAddition FL) = \$$payout';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: _buildStormIcon(storm, color, 28),
        title: Text(
          _getStormName(storm),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isStateSpecific ? color : null,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(
          '\$$payout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: payout > 0 ? Colors.red : Colors.green,
          ),
        ),
        onTap: isStateSpecific ? null : () => _showRemoveConfirmation(storm),
      ),
    );
  }

  Widget _buildStormButton(StormType storm, PolicyTrackerProvider trackerProvider) {
    final totalPolicies = trackerProvider.getCombinedStormTotal(storm);
    final stormColor = _getStormColor(storm);

    return GestureDetector(
      onTap: () => _showSeverityDialog(storm, trackerProvider),
      child: Container(
        decoration: BoxDecoration(
          color: stormColor.withOpacity(0.1),
          border: Border.all(color: stormColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStormIcon(storm, stormColor, 24),
                  const SizedBox(height: 4),
                  Text(
                    _getStormName(storm),
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: stormColor, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    totalPolicies.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Severity Dialogs ---

  void _showSeverityDialog(StormType storm, PolicyTrackerProvider tracker) {
    final configProvider = Provider.of<GameConfigProvider>(context, listen: false);

    // Get base severity options
    List<int> severityOptions;
    if (configProvider.hasConfig) {
      severityOptions = [];
      int prev = -1;
      for (int i = 0; i < 20; i++) {
        int p = configProvider.getStormPayout(storm, i);
        if (p == prev && p == 0) break;
        severityOptions.add(p);
        prev = p;
      }
    } else {
      severityOptions = PolicyData.stormPayouts[storm] ?? [0];
    }
    severityOptions = severityOptions.where((v) => v > 0).toList();

    // Determine if this storm has a state-specific variant
    StormType? stateStorm;
    for (final ss in PolicyData.stateStormTypes) {
      if (PolicyData.parentStormTypes[ss] == storm) {
        stateStorm = ss;
        break;
      }
    }

    final hasStatePolicy = stateStorm != null && tracker.getStormTotal(stateStorm) > 0;

    if (stateStorm == null || !hasStatePolicy) {
      // Simple dialog — no state-specific section needed
      _showSimpleSeverityDialog(storm, severityOptions);
    } else if (stateStorm == StormType.hurricaneFlorida) {
      _showHurricaneSeverityDialog(severityOptions, tracker);
    } else if (stateStorm == StormType.fireCalifornia) {
      _showFireSeverityDialog(severityOptions, tracker);
    } else if (stateStorm == StormType.tornadoTexas) {
      _showTornadoSeverityDialog(severityOptions, tracker);
    }
  }

  void _showSimpleSeverityDialog(StormType storm, List<int> options) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Select ${_getStormName(storm)} Severity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((severity) {
              return ListTile(
                title: Text('\$$severity'),
                onTap: () {
                  setState(() {
                    occurredStorms[storm] = severity;
                  });
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showHurricaneSeverityDialog(List<int> severityOptions, PolicyTrackerProvider tracker) {
    int? selectedSeverity;
    int? selectedFLAddition;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Hurricane Severity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: severityOptions.map((sev) {
                        final isSelected = selectedSeverity == sev;
                        return ChoiceChip(
                          label: Text('\$$sev'),
                          selected: isSelected,
                          selectedColor: Colors.purple.shade200,
                          onSelected: (_) {
                            setDialogState(() => selectedSeverity = sev);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Florida Addition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: floridaAdditionOptions.map((add) {
                        final isSelected = selectedFLAddition == add;
                        return ChoiceChip(
                          label: Text('+\$$add'),
                          selected: isSelected,
                          selectedColor: Colors.purple.shade400,
                          onSelected: (_) {
                            setDialogState(() => selectedFLAddition = add);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: (selectedSeverity != null && selectedFLAddition != null)
                      ? () {
                          setState(() {
                            occurredStorms[StormType.hurricaneOther] = selectedSeverity!;
                            floridaAddition = selectedFLAddition;
                          });
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFireSeverityDialog(List<int> severityOptions, PolicyTrackerProvider tracker) {
    int? selectedSeverity;
    int? selectedCAAddition;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Fire Severity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: severityOptions.map((sev) {
                        final isSelected = selectedSeverity == sev;
                        return ChoiceChip(
                          label: Text('\$$sev'),
                          selected: isSelected,
                          selectedColor: Colors.red.shade200,
                          onSelected: (_) {
                            setDialogState(() => selectedSeverity = sev);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('California Addition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: californiaAdditionOptions.map((add) {
                        final isSelected = selectedCAAddition == add;
                        return ChoiceChip(
                          label: Text(add == 0 ? '\$0' : '+\$$add'),
                          selected: isSelected,
                          selectedColor: const Color(0xFFB71C1C).withOpacity(0.4),
                          onSelected: (_) {
                            setDialogState(() => selectedCAAddition = add);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: (selectedSeverity != null && selectedCAAddition != null)
                      ? () {
                          setState(() {
                            occurredStorms[StormType.fire] = selectedSeverity!;
                            californiaAddition = selectedCAAddition;
                          });
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTornadoSeverityDialog(List<int> severityOptions, PolicyTrackerProvider tracker) {
    int? selectedSeverity;
    String? selectedFlip;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Tornado Severity'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: severityOptions.map((sev) {
                        final isSelected = selectedSeverity == sev;
                        return ChoiceChip(
                          label: Text('\$$sev'),
                          selected: isSelected,
                          selectedColor: Colors.grey.shade400,
                          onSelected: (_) {
                            setDialogState(() => selectedSeverity = sev);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Texas Storm Flip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: texasFlipOptions.map((entry) {
                        final isSelected = selectedFlip == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          selectedColor: const Color(0xFF424242).withOpacity(0.4),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                          ),
                          onSelected: (_) {
                            setDialogState(() => selectedFlip = entry.key);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: (selectedSeverity != null && selectedFlip != null)
                      ? () {
                          setState(() {
                            occurredStorms[StormType.tornado] = selectedSeverity!;
                            texasFlippedStorm = selectedFlip;
                          });
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemoveConfirmation(StormType storm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove Storm?'),
          content: Text('Remove ${_getStormName(storm)} from occurred storms?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  occurredStorms.remove(storm);
                  // Clear state-specific data when parent is removed
                  if (storm == StormType.hurricaneOther) floridaAddition = null;
                  if (storm == StormType.fire) californiaAddition = null;
                  if (storm == StormType.tornado) texasFlippedStorm = null;
                });
                Navigator.of(ctx).pop();
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
      case StormType.flood:
        return const Color(0xFF1A4784);
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
        return const Color(0xFFB71C1C);
      case StormType.tornadoTexas:
        return const Color(0xFF424242);
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
      case StormType.hurricaneOther:
      case StormType.hurricaneFlorida:
        return Icons.cyclone;
      case StormType.flood:
        return Icons.water;
      case StormType.fire:
      case StormType.fireCalifornia:
        return Icons.local_fire_department;
      case StormType.hail:
        return Icons.grain;
      case StormType.tornado:
      case StormType.tornadoTexas:
        return Icons.tornado;
    }
  }

  String _getStormName(StormType stormType) {
    return PolicyData.stormNames[stormType] ?? '';
  }
}
