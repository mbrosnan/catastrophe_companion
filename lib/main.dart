import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/policy_tracker_provider.dart';
import 'providers/payout_calculator_provider.dart';
import 'providers/cards_provider.dart';
import 'providers/insolvency_calculator_provider.dart';
import 'screens/tracker_screen.dart';
import 'screens/payout_calculator_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/insolvency_calculator_screen.dart';

void main() {
  runApp(const CatastropheCompanionApp());
}

class CatastropheCompanionApp extends StatelessWidget {
  const CatastropheCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PolicyTrackerProvider()),
        ChangeNotifierProvider(create: (_) => PayoutCalculatorProvider()),
        ChangeNotifierProvider(create: (_) => CardsProvider()),
        ChangeNotifierProvider(create: (_) => InsolvencyCalculatorProvider()),
      ],
      child: MaterialApp(
        title: 'Catastrophe Companion',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TrackerScreen(),
    const PayoutCalculatorScreen(),
    const CardsScreen(),
    const InsolvencyCalculatorScreen(),
    const MapConfigurationScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Policy Tracker',
    'Payout Calculator',
    'Victory Cards',
    'Insolvency Calculator',
    'Map Configuration',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_titles[_selectedIndex]),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Payout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Cards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Insolvency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}





class MapConfigurationScreen extends StatelessWidget {
  const MapConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Map Configuration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configure game board setup.\n\n'
              'Generate random or pre-made\n'
              'configurations for placing\n'
              'mansions and mobile homes.\n\n'
              '(Coming in a future update)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'App configuration options.\n\n'
              'Customize default values and\n'
              'app behavior settings here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
