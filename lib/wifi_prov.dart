import 'package:flutter/material.dart';
import 'dart:io';

class WifiConfigDialog extends StatefulWidget {
  const WifiConfigDialog({super.key});

  @override
  State<WifiConfigDialog> createState() => _WifiConfigDialogState();
}

class _WifiConfigDialogState extends State<WifiConfigDialog> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Wi-Fi Provisioning',
        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'SSID',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                String ssid = ssidController.text;
                String password = passwordController.text;
                // Check if ssid or password is empty
                if (ssid.isEmpty || password.isEmpty) {
                  // Show an error message if either SSID or password is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SSID and Password cannot be empty')),
                  );
                  return; // Prevent further execution
                }
                String message = '$ssid,$password';

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                // use `context` inside async but only via freshly-built widgets
                () async {
                  try {
                    final socket = await Socket.connect('192.168.0.101', 8989);
                    socket.write(message);
                    await socket.flush();
                    await socket.close();

                    // ✅ Use showDialog AFTER the socket logic, but make sure it's safe
                    if (!mounted) return; // double-check safety

                    // Use `showDialog` with a context that's safe post-async
                    await showDialog(
                    context: navigator.context, // ✅ uses the navigator's safe context
                    builder: (BuildContext context) => AlertDialog(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: const Text('Success', style: TextStyle(color: Colors.amber)),
                      content: const Text(
                        'SSID and password updated successfully!',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK', style: TextStyle(color: Colors.amber)),
                        ),
                      ],
                    ),
                    );

                    // ✅ Close the original WifiConfigDialog
                    navigator.pop();

                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to send data: $e')),
                    );
                  }
                }();
              },




              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Submit'),
            ),
            const SizedBox(height: 12),
            const Text(
              "Note: Make sure the device is in provisioning mode (Phone should be connected to the device's access point) before submitting.",
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
