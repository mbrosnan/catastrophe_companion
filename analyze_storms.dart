import 'lib/models/map_configuration.dart';

void main() {
  // Count spaces per storm type
  final stormSpaces = <StormType, int>{};
  final stormStates = <StormType, List<String>>{};
  
  for (final storm in StormType.values) {
    stormSpaces[storm] = 0;
    stormStates[storm] = [];
  }
  
  for (final entry in usStates.entries) {
    final state = entry.key;
    final info = entry.value;
    
    for (final storm in info.stormTypes) {
      stormSpaces[storm] = (stormSpaces[storm] ?? 0) + info.spaces;
      stormStates[storm]!.add('$state(${info.spaces})');
    }
  }
  
  print('Storm Type Space Distribution:');
  print('==============================');
  
  for (final entry in stormSpaces.entries) {
    final storm = entry.key;
    final spaces = entry.value;
    print('${storm.toString().split('.').last.padRight(20)}: $spaces spaces');
    print('  States: ${stormStates[storm]!.join(', ')}');
    print('');
  }
  
  print('\nTotal spaces: ${usStates.values.fold(0, (sum, state) => sum + state.spaces)}');
  print('Note: TX(8) and CA(10) count for both their storm types');
  
  // Calculate if balanced distribution is possible
  print('\nBalanced Distribution Analysis:');
  print('===============================');
  print('For 10 mansions + 10 mobile homes = 20 tokens');
  print('With 8 storm types, perfect balance = 2.5 tokens per storm');
  print('With acceptableDifference = 1, range is 2-3 tokens per storm');
  print('With acceptableDifference = 2, range is 1-4 tokens per storm');
  
  // Remove hurricaneFlorida from consideration
  final effectiveStorms = stormSpaces.entries
      .where((e) => e.key != StormType.hurricaneFlorida)
      .toList();
  
  print('\nEffective storm types (treating hurricaneFlorida as hurricaneOther): ${effectiveStorms.length}');
}