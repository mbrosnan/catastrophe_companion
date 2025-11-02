import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_config_provider.dart';
import 'providers/policy_tracker_provider.dart';
import 'providers/payout_calculator_provider.dart';
import 'providers/cards_provider.dart';
import 'providers/insolvency_calculator_provider.dart';
import 'providers/map_configuration_provider.dart';
import 'screens/tracker_v3_screen.dart';
import 'screens/payout_calculator_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/insolvency_calculator_screen.dart';
import 'screens/map_configuration_screen.dart';

void main() {
  runApp(const CatastropheCompanionApp());
}

class CatastropheCompanionApp extends StatelessWidget {
  const CatastropheCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // GameConfigProvider must be first since others depend on it
        ChangeNotifierProvider(create: (_) => GameConfigProvider()),

        // Other providers now depend on GameConfigProvider
        ChangeNotifierProxyProvider<GameConfigProvider, PolicyTrackerProvider>(
          create: (_) => PolicyTrackerProvider(),
          update: (_, config, tracker) {
            tracker?.updateGameConfig(config);
            return tracker ?? PolicyTrackerProvider();
          },
        ),
        ChangeNotifierProxyProvider<GameConfigProvider, PayoutCalculatorProvider>(
          create: (_) => PayoutCalculatorProvider(),
          update: (_, config, calculator) {
            calculator?.updateGameConfig(config);
            return calculator ?? PayoutCalculatorProvider();
          },
        ),
        ChangeNotifierProxyProvider<GameConfigProvider, CardsProvider>(
          create: (_) => CardsProvider(),
          update: (_, config, cards) {
            cards?.updateGameConfig(config);
            return cards ?? CardsProvider();
          },
        ),
        ChangeNotifierProxyProvider<GameConfigProvider, InsolvencyCalculatorProvider>(
          create: (_) => InsolvencyCalculatorProvider(),
          update: (_, config, insolvency) {
            insolvency?.updateGameConfig(config);
            return insolvency ?? InsolvencyCalculatorProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => MapConfigurationProvider()),
      ],
      child: MaterialApp(
        title: 'Catastrophe Companion',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ConfigLoader(),
      ),
    );
  }
}

/// Widget to handle loading game configuration before showing main screen
class ConfigLoader extends StatelessWidget {
  const ConfigLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameConfigProvider>(
      builder: (context, configProvider, child) {
        if (configProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading game configuration...'),
                ],
              ),
            ),
          );
        }

        if (configProvider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading configuration:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      configProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => configProvider.reloadConfig(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const MainScreen();
      },
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
    const TrackerV3Screen(),              // Use V3 as the main tracker
    const PayoutCalculatorScreen(),
    const CardsScreen(),
    const InsolvencyCalculatorScreen(),
    const MapConfigurationScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Tracker',
    'Payout Calculator',
    'Cards',
    'Insolvency Calculator',
    'Map Configuration',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontSize: 18),
        ),
        toolbarHeight: 40,
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
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.policy),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Payout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style),
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
