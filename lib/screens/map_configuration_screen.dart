import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/map_configuration_provider.dart';
import '../models/map_configuration.dart';
import '../widgets/state_chip.dart';

class MapConfigurationScreen extends StatelessWidget {
  const MapConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Configuration'),
      ),
      body: Consumer<MapConfigurationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(context, provider),
                const SizedBox(height: 24),
                _buildGenerateButton(context, provider),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(provider.errorMessage!),
                ],
                if (provider.currentResult != null) ...[
                  const SizedBox(height: 24),
                  _buildResultsSection(provider.currentResult!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, MapConfigurationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Profile dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Profile',
                border: OutlineInputBorder(),
              ),
              value: provider.settings.selectedProfile,
              items: provider.availableProfiles.map((profile) {
                return DropdownMenuItem(
                  value: profile.filename,
                  child: Text(profile.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  provider.updateSelectedProfile(value);
                }
              },
            ),
            
            // Show profile description
            if (provider.selectedProfile != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.selectedProfile!.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // State limit checkboxes
            CheckboxListTile(
              title: const Text('Limit FL to 1 of each'),
              value: provider.settings.limitFloridaToOne,
              onChanged: (value) {
                provider.updateLimitFlorida(value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: const Text('Limit TX to 1 of each'),
              value: provider.settings.limitTexasToOne,
              onChanged: (value) {
                provider.updateLimitTexas(value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            CheckboxListTile(
              title: const Text('Limit CA to 1 of each'),
              value: provider.settings.limitCaliforniaToOne,
              onChanged: (value) {
                provider.updateLimitCalifornia(value ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            
            const SizedBox(height: 16),
            
            // Number inputs
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Number of mansions',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    initialValue: provider.settings.numberOfMansions.toString(),
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null && intValue >= 0) {
                        provider.updateNumberOfMansions(intValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Number of mobile homes',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    initialValue: provider.settings.numberOfMobileHomes.toString(),
                    onChanged: (value) {
                      final intValue = int.tryParse(value);
                      if (intValue != null && intValue >= 0) {
                        provider.updateNumberOfMobileHomes(intValue);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, MapConfigurationProvider provider) {
    return ElevatedButton(
      onPressed: () {
        provider.generateMap();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Generate'),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(GenerationResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultCard(
          title: 'Mansion Tokens',
          icon: Icons.castle,
          color: Colors.purple,
          assignments: result.mansionAssignments,
        ),
        const SizedBox(height: 16),
        _buildResultCard(
          title: 'Mobile Home Tokens',
          icon: Icons.house,
          color: Colors.orange,
          assignments: result.mobileHomeAssignments,
        ),
        if (result.emptyStates.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildEmptyStatesCard(result.emptyStates),
        ],
      ],
    );
  }

  Widget _buildResultCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, int> assignments,
  }) {
    final sortedEntries = assignments.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${assignments.values.fold(0, (sum, count) => sum + count)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sortedEntries.isEmpty)
              const Text('No assignments')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sortedEntries.map((entry) {
                  final stateInfo = usStates[entry.key]!;
                  return StateChip(
                    stateCode: entry.key,
                    count: entry.value,
                    stormTypes: stateInfo.stormTypes,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStatesCard(List<String> emptyStates) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Empty States',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emptyStates.map((state) {
                return Chip(
                  label: Text(state),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}