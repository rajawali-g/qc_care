import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF161B26),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const QcMceApp());
}

class QcMceApp extends StatelessWidget {
  const QcMceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QC_MCE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10131A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
          surface: const Color(0xFF181E2B),
        ),
        useMaterial3: true,
        fontFamily: null,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onOpenSettings: () {
          setState(() => _currentIndex = 1);
        },
      ),
      SettingsScreen(
        onSaved: () {
          setState(() => _currentIndex = 0);
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF161B26),
        indicatorColor: const Color(0xFF1E88E5).withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_rounded),
            selectedIcon: Icon(Icons.speed_rounded, color: Color(0xFF64B5F6)),
            label: 'Pemantauan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF64B5F6)),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
