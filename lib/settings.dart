import 'package:flutter/material.dart';
import 'wifi_prov.dart';

class CustomSettingsScreen extends StatefulWidget {
  const CustomSettingsScreen({super.key});

  @override
  State<CustomSettingsScreen> createState() => _CustomSettingsScreenState();
}

class _CustomSettingsScreenState extends State<CustomSettingsScreen> {
  bool isSoundOn = false;
  bool autoAddDevice = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          _buildSection([
            _buildListTile('Personal Information'),
            _buildListTile('Account and Security'),
            _buildListTile('Wifi Provision', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WifiConfigDialog()),
              );
            }),

            _buildListTile('Device Update'),
          ]),
          _buildSection([
            _buildSwitchTile('Sound', isSoundOn, (val) {
              setState(() => isSoundOn = val);
            }),
            _buildListTile('App Notification'),
            _buildSwitchTile('Add Device Automatically', autoAddDevice, (val) {
              setState(() => autoAddDevice = val);
            }),
            _buildListTile('Temperature Unit', trailing: const Text('℃', style: TextStyle(color: Colors.white))),
          ]),
          _buildSection([
            _buildListTile('About'),
            _buildListTile('Privacy Settings'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(String title, {VoidCallback? onTap, Widget? trailing}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
      onTap: onTap,
    );
  }


  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.amber,
      inactiveTrackColor: Colors.white24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
