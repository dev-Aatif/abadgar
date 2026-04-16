import 'package:flutter/material.dart';

class SeasonsScreen extends StatelessWidget {
  const SeasonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Season', style: Theme.of(context).textTheme.headlineMedium),
          const Card(child: ListTile(title: Text('Rice 2024'), subtitle: Text('Active'))),
          const SizedBox(height: 24),
          Text('Past Seasons', style: Theme.of(context).textTheme.headlineMedium),
          const Card(child: ListTile(title: Text('Wheat 2023'), subtitle: Text('Completed'))),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('CREATE NEW SEASON'),
            ),
          ),
        ],
      ),
    );
  }
}
