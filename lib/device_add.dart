import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

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

  Future<void> startTcpServer() async {
    const int port = 8988;

    try {
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      print('✅ TCP Server listening on port $port');

      server.listen((Socket client) {
        print('🚀 New client connected from ${client.remoteAddress.address}:${client.remotePort}');

        client.listen(
              (Uint8List data) {
            final message = String.fromCharCodes(data);
            print('📨 Received: $message');

            try {
              final decoded = json.decode(message);

              if (decoded is Map<String, dynamic> && decoded['type'] == 'RGB_CON') {
                final deviceName = decoded['dns'] ?? 'Unknown RGB Device';
                final deviceType = decoded['type'] ?? 'UNKNOWN';

                if (!availableDevices.any((d) => d['name'] == deviceName)) {
                  setState(() {
                    availableDevices.add({
                      'name': deviceName,
                      'type': deviceType,
                    });
                  });
                }
              }
            } catch (e) {
              print('⚠️ Failed to decode TCP message: $e');
            }
          },
          onDone: () {
            print('❌ Client disconnected');
          },
          onError: (error) {
            print('⚠️ Error: $error');
          },
        );
      });
    } catch (e) {
      print('❌ Failed to start TCP server: $e');
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
                              device['name'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Handle device add
                            },
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