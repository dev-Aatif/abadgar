import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  debugPrint("🚀 Startup: Step 1 (Widgets initialized)");

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("🚀 Startup: Step 2 (.env loaded)");
  } catch (e) {
    debugPrint("⚠️ Warning: .env file not found.");
  }

  // Initialize Supabase - safely handle missing .env
  final supabaseUrl = dotenv.isInitialized ? (dotenv.env['SUPABASE_URL'] ?? '') : '';
  final supabaseKey = dotenv.isInitialized ? (dotenv.env['SUPABASE_ANON_KEY'] ?? '') : '';

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    debugPrint("⚠️ Warning: Supabase credentials missing. Cloud sync will be disabled.");
  }

  try {
    debugPrint("🚀 Startup: Step 3 (Initializing Supabase...)");
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    ).timeout(const Duration(seconds: 5));
    debugPrint("🚀 Startup: Step 4 (Supabase Ready)");
  } catch (e) {
    debugPrint("❌ Supabase Init Failed: $e");
  }

  runApp(
    const ProviderScope(
      child: AbadgarApp(),
    ),
  );
  
  // Remove splash after a tiny delay to ensure first frame is painted
  Future.delayed(const Duration(milliseconds: 500), () {
    FlutterNativeSplash.remove();
    debugPrint("🚀 Startup: Step 5 (Splash Removed)");
  });
}
