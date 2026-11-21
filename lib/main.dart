import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase initialization (safe try-catch fallback for offline & dev mode)
  try {
    // Supabase.initialize(...) can be loaded here when SUPABASE_URL is provided
  } catch (_) {
    // Fallback to offline / mock repository
  }

  runApp(
    const ProviderScope(
      child: TruckLinkApp(),
    ),
  );
}
