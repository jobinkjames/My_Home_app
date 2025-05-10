import 'package:flutter/material.dart';
import 'settings.dart';
import 'wifi_prov.dart';
import 'package:intl/intl.dart';
import 'device_add.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Device UI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
        colorScheme: ColorScheme.dark().copyWith(secondary: Colors.amber),
      ),
      home: const DashboardScreen(),
    );
  }
}

// HOME PAGE
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black, // avoid nested scaffold coloring issues
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        // decoration: BoxDecoration(
                        //   border: Border.all(color: Colors.white),
                        // ),
                        child: Image.asset('assets/icons/my_icon.png'), // 👈 Your custom icon
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Welcome, Jobin",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.cloud, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('E, MMM d').format(DateTime.now()),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.amber,
                        child: Text('J'),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton(
                        backgroundColor: Colors.amber,
                        mini: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DeviceAddPage()),
                          );
                        },
                        child: const Icon(Icons.add, color: Colors.black),
                      ),

                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  FilterButton(label: 'ALL', selected: true),
                  SizedBox(width: 12),
                  FilterButton(label: 'ROOM'),
                  SizedBox(width: 12),
                  FilterButton(label: 'KITCHEN'),
                ],
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'No devices found',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// FILTER BUTTON
class FilterButton extends StatelessWidget {
  final String label;
  final bool selected;

  const FilterButton({
    super.key,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.brown : Colors.transparent,
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}

// DASHBOARD SCREEN WITH BOTTOM NAVIGATION
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    Placeholder(),
    AlertsScreen(),
  CustomSettingsScreen(),

  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      showDialog(
        context: context,
        builder: (context) => const WifiConfigDialog(),
      );
      return; // Do not update _selectedIndex
    }

    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   backgroundColor: Colors.amber,
      //   child: const Icon(Icons.mic, color: Colors.black),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.black,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white70,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.wifi_find_sharp), label: 'Wifi Provision'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// PLACEHOLDER SCREENS
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Stats Screen', style: TextStyle(color: Colors.white)));
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Alerts Screen', style: TextStyle(color: Colors.white)));
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Screen', style: TextStyle(color: Colors.white)));
  }
}
