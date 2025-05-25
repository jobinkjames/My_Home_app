import 'package:flutter/material.dart';
import 'settings.dart';
import 'wifi_prov.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'device_add.dart';
import 'device_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import 'dart:async';



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
  List<bool> switchStates = [];
  List<bool> deviceOnline = [];
  Timer? _refreshTimer; // Add timer




  @override
  void initState() {
    super.initState();
    loadDevices();
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      await _refreshDeviceList();
    });

  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer to avoid memory leaks
    super.dispose();
  }


  void loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('devices') ?? [];
    List<bool> onlineStatusList = List.filled(savedDevices.length, false);

    setState(() {
      devices = savedDevices;
      switchStates = List.filled(devices.length, true); // default ON
      deviceOnline = onlineStatusList;
    });
    await _refreshDeviceList();
  }


  // Future<void> _loadDevices() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final List<String>? savedDevices = prefs.getStringList('devices');
  //   if (savedDevices != null) {
  //     setState(() {
  //       devices = savedDevices;
  //     });
  //   }
  // }
  Future<bool> isDeviceOnline(String address, {int port = 8989}) async {
    try {
      InternetAddress ipAddress;

      // Check if the input is a valid IP address
      final isIP = InternetAddress.tryParse(address) != null;

      if (isIP) {
        ipAddress = InternetAddress(address);
        print('Using raw IP address: $ipAddress');
      } else {
        // It's likely an mDNS name (like esp_device.local)
        final cleanMdnsName = address.endsWith('.local') ? address : '$address.local';
        final MDnsClient mdns = MDnsClient();
        await mdns.start();

        final ipStream = mdns.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(cleanMdnsName),
        );

        final record = await ipStream.firstWhere(
              (record) => record.address != null,
          orElse: () {
            throw Exception('No IP address found');
          },
        );



        ipAddress = record.address;
        print('Resolved $cleanMdnsName to IP: $ipAddress');

        mdns.stop(); // ✅ This line is fine
      }

      // Try connecting to the IP address
      print('Trying to connect to $ipAddress:$port');
      final socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      print('$address is ONLINE');
      return true;
    } catch (e) {
      print('$address is OFFLINE, error: $e');
      return false;
    }
  }


  Future<void> _refreshDeviceList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> refreshedDevices = prefs.getStringList('devices') ?? [];
    List<bool> onlineStatusList = [];

    for (String deviceJson in refreshedDevices) {
      final device = jsonDecode(deviceJson);
      final dns = device['dns'];
      final ip = device['ip'];
      bool isOnline = false;

      // Try with mDNS first
      if (dns != null && dns.isNotEmpty) {
        final mdnsAddress = '$dns.local';
        isOnline = await isDeviceOnline(mdnsAddress, port: 8989);
      }

      // Fallback to IP if mDNS fails
      if (!isOnline && ip != null && ip.isNotEmpty) {
        isOnline = await isDeviceOnline(ip, port: 8989);
      }

      onlineStatusList.add(isOnline);
    }

    setState(() {
      devices = refreshedDevices;
      switchStates = List.filled(refreshedDevices.length, true); // or load actual power state
      deviceOnline = onlineStatusList;
    });
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
                          ).then((_) {
                            _refreshDeviceList(); // refresh when returned
                          });

                        },
                        child: const Icon(Icons.add, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Row(
              //   children: const [
              //     FilterButton(label: 'ALL', selected: true),
              //     SizedBox(width: 12),
              //     FilterButton(label: 'ROOM'),
              //     SizedBox(width: 12),
              //     FilterButton(label: 'KITCHEN'),
              //   ],
              // ),
              const SizedBox(height: 40),
              Expanded(
                child: devices.isEmpty
                    ? const Center(
                  child: Text(
                    'No devices found',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                :RefreshIndicator(
                  onRefresh: _refreshDeviceList, // Your async refresh function
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> device = jsonDecode(devices[index]);
                      String deviceName = device['type'] ?? 'Unknown';

                      return GestureDetector(
                        onTap: () {
                          if (deviceOnline[index]) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeviceControlPage(
                                  device: device,
                                  onRename: (newName) async {
                                    final prefs = await SharedPreferences.getInstance();
                                    List<String> updatedDevices = prefs.getStringList('devices') ?? [];

                                    device['type'] = newName; // or 'name' key
                                    updatedDevices[index] = jsonEncode(device);
                                    await prefs.setStringList('devices', updatedDevices);

                                    setState(() {
                                      devices = updatedDevices;
                                    });
                                  },
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Device is offline")),
                            );
                          }
                        },


                        child: Container(
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
                                      deviceOnline[index] ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        color: deviceOnline[index] ? Colors.green : Colors.red,
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
                                        List<String> deviceList = prefs.getStringList('devices') ?? [];

                                        // Get the device JSON string
                                        final String deviceJson = deviceList[index];
                                        final Map<String, dynamic> device = jsonDecode(deviceJson);
                                        final String deviceId = device['id'];

                                        // Remove device-specific settings (fixing the key names)
                                        await prefs.remove('${deviceId}_currentColor');
                                        await prefs.remove('${deviceId}_brightness');
                                        await prefs.remove('${deviceId}_speed');
                                        await prefs.remove('${deviceId}_selectedEffect');
                                        await prefs.remove('${deviceId}_selectedEffectIndex');
                                        await prefs.remove('${deviceId}_powerOn');

                                        // Remove the device from the list
                                        deviceList.removeAt(index);
                                        await prefs.setStringList('devices', deviceList);

                                        setState(() {
                                          devices = deviceList;
                                        });

                                        print("✅ Device and all its data deleted.");
                                      }



                                  ),
                                  Switch(
                                    value: switchStates[index],
                                    onChanged: (val) {
                                      setState(() {
                                        switchStates[index] = val;
                                      });
                                    },
                                    activeColor: Colors.amber,
                                    inactiveTrackColor: Colors.grey.shade800,
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )



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
    if (index == 2) {
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
