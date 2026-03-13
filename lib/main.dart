import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/measurement_page.dart';
import 'pages/dev_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CsuszoApp());
}

class CsuszoApp extends StatelessWidget {
  const CsuszoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Csúszási Súrlódás Mérő',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MeasurementPage(),
    DevPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_rounded),
            selectedIcon: Icon(Icons.speed_rounded),
            label: 'Mérés',
          ),
          NavigationDestination(
            icon: Icon(Icons.developer_board_outlined),
            selectedIcon: Icon(Icons.developer_board),
            label: 'Dev',
          ),
        ],
      ),
    );
  }
}