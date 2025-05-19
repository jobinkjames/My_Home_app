import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceAddPage extends StatefulWidget {
  const DeviceAddPage({super.key});

  @override
  State<DeviceAddPage> createState() => _DeviceAddPageState();
}

class _DeviceAddPageState extends State<DeviceAddPage> {
  List<Map<String, String>> availableDevices = [];
  bool isScanning = false;

  Future<void> scanForDevices() async {
    setState(() {
      isScanning = true;
      availableDevices = [];
    });

    // Start TCP server to listen for device responses
    startTcpServer();

    // Send UDP broadcast
    await sendUdpBroadcast("DISCOVER_DEVICES");

    // Simulate scan delay
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isScanning = false;
    });
  }

  Future<void> sendUdpBroadcast(String message) async {
    const int port = 8787;
    const String broadcastAddress = '255.255.255.255';

    final RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    final data = message.codeUnits;
    socket.send(data, InternetAddress(broadcastAddress), port);
    socket.close();
  }

  ServerSocket? _tcpServer;

  @override
  void dispose() {
    _tcpServer?.close();
    super.dispose();
  }

  Future<void> startTcpServer() async {
    const int port = 8988;

    try {
      // Close existing server if running
      await _tcpServer?.close();

      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      print('✅ TCP Server listening on port $port');

      _tcpServer!.listen((Socket client) {
        print('🚀 New client connected from ${client.remoteAddress.address}:${client.remotePort}');

        client.listen(
              (Uint8List data) async {
            final message = String.fromCharCodes(data).trim();
            print('📨 Received: $message');

            try {
              final decoded = jsonDecode(message);
              print('✅ Decoded Message: $decoded');

              if (decoded is Map<String, dynamic> && decoded['type'] == 'RGB_CON') {
                final deviceId = decoded['id'] ?? 'unknown_id';
                final deviceType = decoded['type'] ?? 'UNKNOWN';
                final deviceIp = decoded['ip'] ?? '0.0.0.0';
                final deviceDns = decoded['dns'] ?? 'Unknown RGB Device';

                // Full device map
                final device = {
                  'id': deviceId.toString(),
                  'type': deviceType.toString(),
                  'ip': deviceIp.toString(),
                  'dns': deviceDns.toString(),
                };


                // Get already added devices from SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String> savedDevices = prefs.getStringList('devices') ?? [];

                // Skip adding if already in saved devices (based on device 'id')
                bool alreadyAdded = savedDevices.any((entry) {
                  try {
                    final data = jsonDecode(entry);
                    return data['id'] == deviceId;
                  } catch (_) {
                    return false;
                  }
                });

                if (!alreadyAdded && mounted) {
                  setState(() {
                    availableDevices.add(device);
                  });
                }
              }
            } catch (e) {
              print('❌ Failed to decode TCP message: $e');
            }
          },
          onDone: () => print('❌ Client disconnected'),
          onError: (error) => print('⚠️ Error: $error'),
        );
      });
    } catch (e) {
      print('❌ Failed to start TCP server: $e');
    }
  }



  Future<void> addDevice(Map<String, String> device) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedDevices = prefs.getStringList('devices') ?? [];

    // Avoid adding duplicate devices
    if (!savedDevices.any((d) => jsonDecode(d)['id'] == device['id'])) {
      savedDevices.add(jsonEncode(device));
      await prefs.setStringList('devices', savedDevices);

      final String id = device['id']!;

      // Set default configuration for this device
      await prefs.setInt('${id}_color', Colors.white.value);
      await prefs.setDouble('${id}_brightness', 0.5);
      await prefs.setDouble('${id}_speed', 0.5);
      await prefs.setString('${id}_selectedEffect', 'Static');
      await prefs.setInt('${id}_selectedEffectIndex', 0);
      await prefs.setBool('${id}_powerOn', true);

      setState(() {
        availableDevices.removeWhere((d) => d['id'] == id);
      });
    }
  }



  Icon _getIconForType(String type) {
    switch (type) {
      case 'RGB_CON':
        return const Icon(Icons.lightbulb_rounded, color: Colors.amber);
      case 'TEMP_SENSOR':
        return const Icon(Icons.thermostat, color: Colors.red);
      case 'SPEAKER':
        return const Icon(Icons.speaker, color: Colors.blue);
      case 'HUMIDITY':
        return const Icon(Icons.water_drop, color: Colors.cyan);
      default:
        return const Icon(Icons.device_unknown, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Available Devices",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isScanning
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 12),
                    Text(
                      "Scanning for devices...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
                  : availableDevices.isEmpty
                  ? const Center(
                child: Text(
                  "No devices found",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: availableDevices.length,
                itemBuilder: (context, index) {
                  final device = availableDevices[index];
                  return Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          _getIconForType(device['type'] ?? ''),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              device['type'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => addDevice(device),
                            child: const Text("Add"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isScanning ? null : scanForDevices,
              icon: const Icon(Icons.search),
              label: const Text("Scan for Devices"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey,
                disabledForegroundColor: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
