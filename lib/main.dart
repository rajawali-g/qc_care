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
      systemNavigationBarColor: Color(0xFF090D15),
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
        scaffoldBackgroundColor: const Color(0xFF07090E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0C101A),
        ),
        useMaterial3: true,
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF090D15),
          border: Border(top: BorderSide(color: Color(0xFF1B2333))),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00E5FF).withOpacity(0.18),
          surfaceTintColor: Colors.transparent,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.radar_rounded, color: Color(0xFF78909C)),
              selectedIcon: Icon(Icons.radar_rounded, color: Color(0xFF00E5FF)),
              label: 'TELEMETRY',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_rounded, color: Color(0xFF78909C)),
              selectedIcon: Icon(Icons.tune_rounded, color: Color(0xFF00E5FF)),
              label: 'SYS_CONFIG',
            ),
          ],
        ),
      ),
    );
  }
}
