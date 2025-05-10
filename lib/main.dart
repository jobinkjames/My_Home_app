import 'package:flutter/material.dart';
import 'settings.dart';
import 'wifi_prov.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'device_add.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedDevices = prefs.getStringList('devices');
    if (savedDevices != null) {
      setState(() {
        devices = savedDevices;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header
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
                        child: Image.asset('assets/icons/my_icon.png'),
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
                children: const [
                  FilterButton(label: 'ALL', selected: true),
                  SizedBox(width: 12),
                  FilterButton(label: 'ROOM'),
                  SizedBox(width: 12),
                  FilterButton(label: 'KITCHEN'),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: devices.isEmpty
                    ? const Center(
                  child: Text(
                    'No devices found',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                :ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> device = jsonDecode(devices[index]);
                    String deviceName = device['name'] ?? 'Unknown';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2F27),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/icons/rgb.jpg',
                                height: 50,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      deviceName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '192.168.1.${index + 1}', // Replace with real IP
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white70),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();

                                  // Get current list of devices
                                  List<String> deviceList = prefs.getStringList('devices') ?? [];

                                  // Remove the specific device
                                  deviceList.removeAt(index); // or use removeWhere if you compare by name

                                  // Update SharedPreferences
                                  await prefs.setStringList('devices', deviceList);

                                  // Update local list so UI reflects changes
                                  setState(() {
                                    devices = deviceList;
                                  });

                                  print("✅ Device deleted and list updated.");
                                },
                              ),


                              Switch(
                                value: true, // TODO: bind actual device on/off state
                                onChanged: (val) {
                                  // TODO: handle toggle logic
                                },
                                activeColor: Colors.amber,
                                inactiveTrackColor: Colors.grey.shade800,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
            BottomNavigationBarItem(icon: Icon(Icons.wifi_find_sharp), label: 'Wifi Provision'),
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
