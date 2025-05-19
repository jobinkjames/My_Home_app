import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:flutter/foundation.dart';


class DeviceControlPage extends StatefulWidget {
  final Map<String, dynamic> device;
  final void Function(String newName) onRename;

  const DeviceControlPage({
    Key? key,
    required this.device,
    required this.onRename,
  }) : super(key: key);

  @override
  _DeviceControlPageState createState() => _DeviceControlPageState();
}


class _DeviceControlPageState extends State<DeviceControlPage> {
  Color currentColor = Colors.white;
  double brightness = 0.5;
  double speed = 0.5;
  bool powerOn = true;
  List<String> effectModes = ['Static', 'Blink', 'Rainbow', 'Breath', 'Wave'];
  String selectedEffect = 'Static';
  int selectedEffectIndex = 0;
  late String mdnsName;
  String? displayName;


  final List<Color> presetColors = [
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.lightGreen,
    Colors.green,
  ];

  // Load preferences from SharedPreferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final devicesJson = prefs.getStringList('devices') ?? [];
    final currentDevice = widget.device;
    final deviceId = currentDevice['id']; // Make sure each device has a unique 'id'

    bool deviceExists = devicesJson.any((deviceString) {
      final Map<String, dynamic> deviceMap = jsonDecode(deviceString);
      return deviceMap['id'] == deviceId;
    });

    if (!mounted) return;

    setState(() {
      if (deviceExists) {
        currentColor = Color(prefs.getInt('${deviceId}_currentColor') ?? Colors.white.value);
        brightness = prefs.getDouble('${deviceId}_brightness') ?? 0.5;
        speed = prefs.getDouble('${deviceId}_speed') ?? 0.5;
        selectedEffect = prefs.getString('${deviceId}_selectedEffect') ?? 'Static';
        selectedEffectIndex = prefs.getInt('${deviceId}_selectedEffectIndex') ?? 0;
        powerOn = prefs.getBool('${deviceId}_powerOn') ?? true;
      } else {
        // Device not found, use default values
        currentColor = Colors.white;
        brightness = 0.5;
        speed = 0.5;
        selectedEffect = 'Static';
        selectedEffectIndex = 0;
        powerOn = true;
      }
    });
  }


  Future<void> sendTcpMessage(List<String> settings, String mdnsName, int port) async {
    try {
      // Ensure we have the correct mDNS name format (e.g., add '.local' if not present)
      final cleanMdnsName = mdnsName.endsWith('.local') ? mdnsName : '$mdnsName.local';

      // Initialize mDNS client
      final MDnsClient mdns = MDnsClient();
      await mdns.start();

      // Lookup for the A record (IPv4 address)
      final Stream<IPAddressResourceRecord> ipStream = mdns.lookup<IPAddressResourceRecord>(
        ResourceRecordQuery.addressIPv4(cleanMdnsName),
      );

      // Wait for the first non-null IP address record
      final IPAddressResourceRecord? record = await ipStream.firstWhere(
            (record) => record.address != null,
        orElse: () => throw Exception('No IP address found for $cleanMdnsName'),
      );

      // Ensure the record has a valid address
      final ipAddress = record?.address;
      if (ipAddress == null) {
        throw Exception('No valid IP address found for $cleanMdnsName');
      }

      // Connect to the resolved IP address using TCP
      final socket = await Socket.connect(ipAddress, port);

      // Prepare the message to be sent
      final message = jsonEncode({
        'color': settings[0],
        'brightness': settings[1],
        'speed': settings[2],
        'effect': settings[3],
        'power': settings[4],
      });

      // Send the message over the socket connection
      socket.write(message);
      await socket.flush();
      await socket.close();

      print('✅ Message sent to $cleanMdnsName: $message');
    } catch (e) {
      print('❌ Error resolving or sending: $e');
    }
  }


  // Save preferences to SharedPreferences
  Future<void> savePreferences(Map<String, dynamic> device) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve the list of saved devices from SharedPreferences
    List<String> savedDevices = prefs.getStringList('devices') ?? [];

    final deviceId = device['id'];

    bool deviceFound = savedDevices.any((entry) {
      try {
        final savedDevice = jsonDecode(entry);
        return savedDevice['id'] == deviceId;
      } catch (_) {
        return false;
      }
    });

    if (deviceFound) {
      // Use device-specific keys
      await prefs.setInt('${deviceId}_currentColor', currentColor.value);
      await prefs.setDouble('${deviceId}_brightness', brightness);
      await prefs.setDouble('${deviceId}_speed', speed);
      await prefs.setString('${deviceId}_selectedEffect', selectedEffect);
      await prefs.setInt('${deviceId}_selectedEffectIndex', selectedEffectIndex);
      await prefs.setBool('${deviceId}_powerOn', powerOn);

      print('✅ Preferences saved for device ID: $deviceId');
    } else {
      print('❌ Device not found in saved devices, preferences not saved.');
    }
  }


  void _notifyServer() {
    final settings = getCurrentSettingsArray();
    // final mdnsName = widget.device['ip']; // This is the .local mDNS name
    const port = 8989; // Use your device's TCP port
    sendTcpMessage(settings, mdnsName, port);
  }


  void changeColor(Color color) {
    setState(() => currentColor = color);
    savePreferences(widget.device); // Pass the device as an argument
    // Save color change
    _notifyServer();
  }

  List<String> getCurrentSettingsArray() {
    // Convert color to hex string (ARGB)
    String hexColor = '#${currentColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';


    // Convert all values to strings and return as array
    return [
      hexColor,                      // e.g. #FFFFFFFF
      brightness.toStringAsFixed(2), // e.g. "0.75"
      speed.toStringAsFixed(2),      // e.g. "0.50"
      selectedEffect,               // e.g. "Rainbow"
      powerOn.toString(),           // "true" or "false"
    ];
  }

  @override
  void initState() {
    super.initState();
    mdnsName = widget.device['dns'] ?? widget.device['ip'] ?? 'esp-light.local';
    loadPreferences(); // Load saved preferences when the page is initialized
    displayName = widget.device['name'] ?? widget.device['id'];
  }
  void _showRenameDialog() {
    final TextEditingController _controller = TextEditingController(text: displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'Enter new device name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                displayName = _controller.text;
                widget.device['name'] = _controller.text;
              });
              widget.onRename(_controller.text);  // <-- Notify home page here

              Navigator.of(context).pop();
              savePreferences(widget.device);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final deviceName = displayName ?? widget.device['id'] ?? 'Unknown Device';
    final deviceIP = widget.device['ip'] ?? '0.0.0.0';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min, // Prevents excessive spacing
          children: [
            Text(
              deviceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6), // Small spacing
            GestureDetector(
              onTap: _showRenameDialog, // Trigger rename dialog
              child: const Icon(
                Icons.edit,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                deviceIP,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),


      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20), // Padding to avoid overflow
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Color Settings Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Color Settings',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    Center(
                      child: ColorPicker(
                        pickerColor: currentColor,
                        onColorChanged: changeColor,
                        labelTypes: const [],
                        enableAlpha: false,
                        displayThumbColor: false,
                        pickerAreaHeightPercent: 0.8,
                        paletteType: PaletteType.hueWheel,
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text('Preset Colors', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: presetColors.map((color) {
                          return GestureDetector(
                            onTap: () => changeColor(color),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Text('Brightness', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.brightness_6, color: Colors.white),
                        Expanded(
                          child: Slider(
                            value: brightness,
                            onChanged: (value) {
                              setState(() {
                                brightness = value;
                              });
                              savePreferences(widget.device); // Pass the device as an argument
                              _notifyServer();
                            },
                            min: 0,
                            max: 1,
                            activeColor: currentColor,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                        Text('${(brightness * 100).round()}%',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Text('Speed', style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.speed, color: Colors.white),
                        Expanded(
                          child: Slider(
                            value: speed,
                            onChanged: (value) {
                              if (!mounted) return;
                              setState(() {
                                speed = value;
                              });
                              savePreferences(widget.device); // Pass the device as an argument

                              _notifyServer();
                            },
                            min: 0,
                            max: 1,
                            activeColor: currentColor,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                        Text('${(speed * 100).round()}%',
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Select Effect Mode',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: effectModes.map((mode) {
                          final isSelected = selectedEffect == mode;
                          return GestureDetector(
                            onTap: () {
                              final index = effectModes.indexOf(mode);
                              if (!mounted) return;
                              setState(() {
                                selectedEffect = mode;
                                selectedEffectIndex = index;
                              });
                              savePreferences(widget.device); // Pass the device as an argument

                              _notifyServer();
                            },

                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? currentColor : Colors.grey[800],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                mode,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Footer Buttons

            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.info),
                label: const Text('Info'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => powerOn = !powerOn);
                  savePreferences(widget.device);
                  _notifyServer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentColor,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  elevation: 6,
                ),
                child: Icon(
                  powerOn ? Icons.power_settings_new : Icons.power_off_outlined,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),

    );

  }

}
