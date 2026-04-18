import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from project root (dev) or system env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Using --dart-define or defaults.");
  }

  // Initialize Supabase — use dart-define values as fallback for production
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(
    const ProviderScope(
      child: AbadgarApp(),
    ),
  );
}
