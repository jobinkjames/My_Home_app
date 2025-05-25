import 'package:flutter/material.dart';

class DeviceSettingsPage extends StatefulWidget {
  final Map<String, dynamic> device;
  final String? displayName;
  final int ledCount;
  final String? category;

  const DeviceSettingsPage({
    super.key,
    required this.device,
    this.displayName,
    required this.ledCount,
    this.category,
  });

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  late TextEditingController ledController;
  late TextEditingController nameController;
  String? selectedCategory;
  late TextEditingController customCategoryController;

  @override
  void initState() {
    super.initState();
    ledController = TextEditingController(
      text: widget.device['ledCount']?.toString() ?? '0',
    );
    nameController = TextEditingController(
      text: widget.device['name'] ?? '',
    );
    selectedCategory = widget.category;
    customCategoryController = TextEditingController();
  }

  @override
  void dispose() {
    ledController.dispose();
    nameController.dispose();
    customCategoryController.dispose();
    super.dispose();
  }

  void saveSettings() {
    final updatedDevice = {
      ...widget.device,
      'name': nameController.text,
      'ledCount': int.tryParse(ledController.text) ?? 0,
      'category': selectedCategory,
    };
    Navigator.pop(context, {'updated': true, 'device': updatedDevice});
  }

  Widget buildSection({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Base categories
    List<String> categories = ['Living Room', 'Bedroom', 'Kitchen', 'Custom'];

    // If current selectedCategory is not in the list and not null, add it at front
    if (selectedCategory != null && !categories.contains(selectedCategory)) {
      categories = [selectedCategory!, ...categories];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Large device image at top
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icons/rgb.jpg',
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.displayName ?? widget.device['name'] ?? 'Unknown Device',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Number of LEDs section
            buildSection(
              title: "Number of LEDs",
              child: TextField(
                controller: ledController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter LED count',
                ),
              ),
            ),

            // Category dropdown + custom input + save button
            buildSection(
              title: "Add to Category",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                        if (value != 'Custom') {
                          customCategoryController.clear();
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Category',
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                        .toList(),
                  ),
                  if (selectedCategory == 'Custom') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customCategoryController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Custom Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Use custom category if provided
                      final category = (selectedCategory == 'Custom' &&
                          customCategoryController.text.trim().isNotEmpty)
                          ? customCategoryController.text.trim()
                          : selectedCategory;

                      setState(() {
                        selectedCategory = category;
                      });

                      saveSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            // You can add other sections here (e.g. delete device, wifi settings etc)
          ],
        ),
      ),
    );
  }
}
