import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/hive_service.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'providers/log_provider.dart';
import 'providers/tag_provider.dart';
import 'screens/home_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Initialize services
  await PreferencesService.init();
  await HiveService.init();
  await NotificationService.init();
  
  runApp(const LogitApp());
}

class LogitApp extends StatelessWidget {
  const LogitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LogProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => TagProvider()..initialize(),
        ),
      ],
      child: Consumer<LogProvider>(
        builder: (context, logProvider, child) {
          return MaterialApp(
            title: 'Logit',
            theme: AppTheme.theme,
            themeMode: ThemeMode.dark,
            home: const MainNavigationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const LogsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh data when app becomes active
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<LogProvider>().loadLogs();
      context.read<TagProvider>().loadTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
