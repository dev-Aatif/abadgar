import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AbadgarApp extends ConsumerWidget {
  const AbadgarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Abadgar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // High-quality Green for Farming
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default modern font
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.agriculture, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Abadgar',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text('Initializing Local Brain...'),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
