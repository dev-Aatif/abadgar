import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('Theme Mode'),
          trailing: Switch(value: false, onChanged: (v) {}),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export Data (JSON)'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('Import Data (JSON)'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Check for Updates'),
          onTap: () {},
        ),
      ],
    );
  }
}
